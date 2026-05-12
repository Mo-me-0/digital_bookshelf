import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:digital_bookshelf/screens/pdf_viewer_page.dart';


class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use Hive box for persistent local database storage
  final Box _box = Hive.box('bookshelf');

  /// Method to open the file picker dialog and select a PDF file.
  Future<void> _pickFile() async {
    // Await the user's file selection, restricted to PDF files.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    // Check if the user successfully selected a file
    if (result != null) {
      final String? path = result.files.single.path;
      final String name = result.files.single.name;
      
      if (path != null) {
        // Save the book entry to the Hive database
        _box.add({'name': name, 'path': path});
      }
    }
  }

  /// Method to delete a book from the local database
  Future<void> _deleteFile(int index) async {
    await _box.deleteAt(index);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File removed from database')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      // Use ValueListenableBuilder to reactively update UI when the database changes
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text(
                'Your bookshelf is empty.\nTap + to add a PDF book.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              // Retrieve the book document map from Hive
              final Map<dynamic, dynamic> book = box.getAt(index);
              final String name = book['name'];
              final String path = book['path'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                  title: Text(name),
                  subtitle: const Text('Tap to read'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _deleteFile(index),
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
        onPressed: _pickFile,
        tooltip: 'Add PDF Book',
        child: const Icon(Icons.add),
      ),
    );
  }
}