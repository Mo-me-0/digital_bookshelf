import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileServices {
  // Method to open the file picker dialog and select multiple files.
  static Future<List<PlatformFile>?> pickMultipleFiles() async {
    // Await the user's file selection, restricted to PDF, Word, and PPT files.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );
    
    // Check if the user successfully selected files
    if(result == null) return null;
    return result.files;
  }
  
  // Method to open the image picker dialog and select an image file.
  static Future<XFile?> chooseImage() async {
    final picker = ImagePicker();
    
    // access the image with reduced quality
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if(image == null) return null;
    
    // returns the image file
    return image;
  }
  
  // Create directories to store documents and images
  static Future<void> initDirectory() async{
    // Identify if this is the first time the app run
    final prefs = await SharedPreferences.getInstance();
    bool firstRun = prefs.getBool('first_run') ?? true;
    
    if(!firstRun) return; // stop if not 1st time opening app
    
    // Get the app's working(documents) directory
    final Directory appDir = await getApplicationDocumentsDirectory();
    
    // Define new directories to store docs and images
    final Directory docsDir = Directory('${appDir.path}/Documents');
    final Directory imageDir = Directory('${appDir.path}/Images');
    
    // Create the directories if they don't exist
    if (!await docsDir.exists() && !await imageDir.exists()) {
      await docsDir.create(recursive: true);
      await imageDir.create(recursive: true);
    }
    
    // Update the flag so this doesn't run again
    await prefs.setBool('first_run', false);
  }
}