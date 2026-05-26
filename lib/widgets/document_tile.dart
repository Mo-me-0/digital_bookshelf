import 'package:digital_bookshelf/models/book_document.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:flutter/material.dart';

class DocumentTile extends StatelessWidget{
  final BookDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  
  const DocumentTile({super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
  });
  
  @override
  Widget build(BuildContext context) {
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // File icon
              Container(
                width: 46,
                height: 54,
                decoration: BoxDecoration(
                  color: _iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _iconColor.withValues(alpha: 0.25)),
                ),
                child: Icon(_icon,
                  color: _iconColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              
              // Name + meta
              Expanded( child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(document.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary
                    ),
                  ),
                  const SizedBox(height: 4,),
                  Row(
                    children: [
                      _iconLabel(document.fileType, _iconColor),
                      const SizedBox(width: 6),
                      Text(_sizeLabel, 
                        style: const TextStyle(fontSize: 11),
                      ),
                      
                      const SizedBox(width: 6),
                      Text('• $_dateLabel', 
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ],
              )),
              
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline,
                  size: 20,
                ),
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Set an icon based on file type
  IconData get _icon {
    switch(document.fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'docx' || 'doc':
        return Icons.description;
      case 'pptx' || 'ppt':
        return Icons.slideshow;
      default:
        return Icons.insert_drive_file;
    }
  }
  
  // Set color base on docment type
  Color get _iconColor {
    switch (document.fileType) {
      case 'pdf':
        return const Color(0xFFD32F2F);
      case 'docx' || 'doc':
        return const Color(0xFF1565C0);
      case 'pptx' || 'ppt':
        return const Color(0xFFE65100);
      default:
        return AppTheme.textSecondary;
    }
  }
  
  // Get the file size
  String get _sizeLabel {
    // convert the byte size to KB
    final kb = document.fileSizeBytes / 1024;
    
    // if < 1 MB
    if(kb < 1024) return '${kb.toStringAsFixed(0)} KB';
    // if >= 1 MB
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }
  
  // Format the added date as dd/mm/yy
  String get _dateLabel {
    final date = document.addedAt;
    return '${date.day}/${date.month}/${date.year}';
  }
  
  // Document type text style
  Widget _iconLabel(String label, Color color) {
        return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}