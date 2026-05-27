import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

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