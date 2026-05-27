import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:open_filex/open_filex.dart';
import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/models/book_document.dart';
import 'package:digital_bookshelf/widgets/confirm_dialog.dart';
import 'package:digital_bookshelf/widgets/document_tile.dart';
import 'package:digital_bookshelf/services/file_services.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:digital_bookshelf/screens/pdf_viewer_page.dart';
import 'package:uuid/uuid.dart';

class CategoryDetailPage extends StatelessWidget {
  final BookCategory category;
  
  const CategoryDetailPage({ super.key,
    required this.category,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(  
      body: CustomScrollView(
        slivers: [
          // create appbar
          _appBar(context),
          
          // create document lists
          _documentList(context),
        ]
      ),
      
      // To add new document
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addDocuments(),
        tooltip: 'Add Files',
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Add Files',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // To convert text hex as Color object
  Color get _spineColor {
    try{
      return Color(int.parse('FF${category.colorHex}', radix: 16));
    } catch(_) {
      return AppTheme.primary;
    }
  }

  // Custome sliver appbar 
  Widget _appBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: _spineColor,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Delete Category',
          onPressed: () => _confirmDeleteCategory(context),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 14),
        
        // Category name
        title: Text(category.name.isNotEmpty ? category.name : '???',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        
        // Category Icon
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            if ( category.imagePath != null &&
                (kIsWeb || File(category.imagePath!).existsSync())
            ) kIsWeb
                ? Image.network(category.imagePath!, fit: BoxFit.cover,)
                : Image.file(File(category.imagePath!), fit: BoxFit.cover,),
            
            // Overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _spineColor.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            
            // Big Initial letter If there is no image
            if(category.imagePath == null)
              Positioned(
                right: 24,
                top: 20,
                child: Text(
                    category.name.isNotEmpty ? category.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
  
  // Confirm and delete category from detail page
  void _confirmDeleteCategory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Category?',
        message: '"${category.name}" and all its files will be permanently deleted.',
        onPressed: () async {
          Navigator.pop(context); // close dialog
          await ShelfServices.deleteCategory(category.id);
          if (context.mounted) {
            Navigator.pop(context); // go back to home page
          }
        },
      ),
    );
  }
  
  // Ui for list of documents
  Widget _documentList(BuildContext context) {
    // Use ValueListenableBuilder to reactively update UI when the database changes
    return ValueListenableBuilder<Box<BookDocument>>(
      valueListenable: ShelfServices.documentsListenable,
      builder: (context, Box box, _) {
        // fetch document list of the selected category from hive
        var docs = ShelfServices.getDocuments(category.id);
        
        // if no documents found
        if (docs.isEmpty) {
          // to fill(cover) the remening space from the app bar
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                'Your category is empty.\nTap "Add Files" button.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }
        
        // If documents found in the category
        return SliverPadding(
          padding: const EdgeInsets.only(top: 12, bottom: 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              // Set the amount of documents to build
              childCount: docs.length,
              
              // Build documents list
              (context, index) {
              final doc = docs[index];
              return DocumentTile(
                document: doc,
                onTap: () => _openDocument(context, doc),
                onDelete: () => _confirmDelete(context, doc),
              );
            }),
          ),
        );
      },
    );
  }
  
  // Open the document in another page or external app
  void _openDocument(BuildContext context, BookDocument doc) async {
    final fileType = doc.fileType.toLowerCase();
    if (fileType == 'pdf') {
      // Navigate to PdfViewerPage when a tile is selected
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(path: doc.filePath, name: doc.name),
        ),
      );
    } else {
      // Open in external app using open_filex
      try {
        final result = await OpenFilex.open(doc.filePath);
        if (!context.mounted) return;
        if (result.type != ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${result.message}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  
  // Ask confirmation for deleting
  void _confirmDelete(BuildContext context, BookDocument doc) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        // warning topic(to show what we are doing)
        title: 'Remove File?',
        
        // detail explanation
        message: '"${doc.name}" will be removed from this category.',
        
        // confirm delete
        onPressed: () async {
          Navigator.pop(context);
          // deletes from database
          await ShelfServices.deleteDocument(doc.id);
        },
      ),
    );
  }
  
  // Add multiple documents
  void _addDocuments() async {
    // show file picker dialog to pick multiple files
    final files = await FileServices.pickMultipleFiles();
    
    // if no file selected
    if(files == null || files.isEmpty) return;
    
    for (final file in files) {
      final ext = file.extension?.toLowerCase() ?? 'other';
      
      // save the document in hive
      ShelfServices.addDocument(
        BookDocument(
          id: const Uuid().v4(), // create unique id
          name: file.name,
          categoryId: category.id,
          filePath: file.path ?? '',
          fileType: ext,
          addedAt: DateTime.now(),
          fileSizeBytes: file.size,
        )
      );
    }
  }
}