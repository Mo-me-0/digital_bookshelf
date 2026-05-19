import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/models/book_document.dart';
import 'package:digital_bookshelf/services/file_services.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:digital_bookshelf/screens/pdf_viewer_page.dart';
import 'package:uuid/uuid.dart';

class CategoryDetailPage extends StatefulWidget {
  final BookCategory category;
  const CategoryDetailPage({super.key, required this.category});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.category.name),
      ),
      
      // Use ValueListenableBuilder to reactively update UI when the database changes
      body: ValueListenableBuilder<Box<BookDocument>>(
        valueListenable: ShelfServices.documentsListenable,
        builder: (context, Box box, _) {
          var docs = ShelfServices.getDocuments(widget.category.id);
          
          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'Your category is empty.\nTap + to add a PDF book.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              // Retrieve the book document map from Hive
              final doc = docs[index];
              final String name = doc.name;
              final String path = doc.filePath;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: Text(name),
                  subtitle: const Text('Tap to read'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => ShelfServices.deleteDocument(doc.id),
                  ),
                  onTap: () {
                    // Navigate to PdfViewerPage when a book is selected
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerPage(path: path, name: name),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // show file picker dialog
          final file = await FileServices.pickFile();
          
          // if no file selected
          if(file == null) return;
          
          // save the document in hive
          ShelfServices.addDocument(
            BookDocument(
              id: const Uuid().v4(), // create unique id
              name: file.name,
              categoryId: widget.category.id,
              filePath: file.path ?? '',
              fileType: file.extension ?? 'other',
              addedAt: DateTime.now(),
              fileSizeBytes: file.size,
            )
          );
        },
        tooltip: 'Add PDF Book',
        child: const Icon(Icons.add),
      ),
    );
  }
}