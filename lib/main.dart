import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart'; // Import open_filex to handle opening files using default system apps

import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('bookshelf');
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Bookshelf',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: const HomePage(title: 'My Bookshelf'),
    );
  }
}

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use Hive box for persistent storage
  final _box = Hive.box('bookshelf');

  // Retrieve the name of the selected file from Hive
  String? get _selectedFileName => _box.get('selectedFileName');
  
  // Retrieve the path of the selected file from Hive
  String? get _selectedFilePath => _box.get('selectedFilePath');

  /// Method to open the file picker dialog and select a file.
  /// 
  /// The [FilePicker.platform.pickFiles] method by default allows picking
  /// any file type from the device's native file explorer.
  Future<void> _pickFile() async {
    // Await the user's file selection. This opens the native OS dialog.
    // We do not specify allowedExtensions here, so it accepts all files.
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    // Check if the user successfully selected a file (returns null if they cancelled the dialog)
    if (result != null) {
      setState(() {
        // Update the state and save to Hive for persistence
        _box.put('selectedFileName', result.files.single.name);
        _box.put('selectedFilePath', result.files.single.path);
      });
    }
  }

  /// Method to open the selected file using the device's default application
  Future<void> _openFile() async {
    // Verify that a file has actually been selected and we have its path
    if (_selectedFilePath != null) {
      // Use the open_filex package to open the file at the given path
      // This delegates to the OS to find an appropriate app to handle this file type
      final result = await OpenFilex.open(_selectedFilePath!);
      
      // We can inspect the result.type to see if it was successful, or handle errors
      if (result.type != ResultType.done) {
        // In a real app, you might show a SnackBar or AlertDialog here
        debugPrint('Error opening file: ${result.message}');
      }
    }
  }

  /// Method to delete the selected file from the device
  Future<void> _deleteFile() async {
    if (_selectedFilePath != null) {
      try {
        final file = File(_selectedFilePath!);
        if (await file.exists()) {
          await file.delete();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File deleted successfully')),
            );
          }
          
          // Clear current file selection selection state and remove from Hive
          setState(() {
            _box.delete('selectedFileName');
            _box.delete('selectedFilePath');
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File does not exist')),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting file: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _selectedFileName != null
                  ? 'Selected File: $_selectedFileName'
                  : 'No file selected',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Pick a File'),
            ),
            const SizedBox(height: 10), // Adding some space between the buttons
            // Button to open the file, which is disabled (null onPressed) if no file is selected yet
            ElevatedButton(
              onPressed: _selectedFilePath != null ? _openFile : null,
              child: const Text('Open Selected File'),
            ),
            const SizedBox(height: 10),
            // Button to delete the selected file
            ElevatedButton(
              onPressed: _selectedFilePath != null ? _deleteFile : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Selected File'),
            ),
          ],
        ),
      ),
    );
  }
}
