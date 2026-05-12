import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// A secondary page to view the PDF file natively inside the app
class PdfViewerPage extends StatelessWidget {
  final String path;
  final String name;

  const PdfViewerPage({super.key, required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(name),
      ),
      // Render the PDF file
      body: SfPdfViewer.file(File(path)),
    );
  }
}