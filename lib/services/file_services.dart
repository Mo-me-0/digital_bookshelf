import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class FileServices {
  // Method to open the file picker dialog and select a PDF file.
  static Future<PlatformFile?> pickFile() async {
    // Await the user's file selection, restricted to PDF files.
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    // Check if the user successfully selected a file
    if(result == null) return null;
    return result.files.single;
  }
  
  // Method to open the image picker dialog and select an image file.
  static Future<String?> chooseImage() async {
    final picker = ImagePicker();
    
    // access the image with reduced quality
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if(image == null) return null;
    // returns the path of the image
    return image.path;
  }
}