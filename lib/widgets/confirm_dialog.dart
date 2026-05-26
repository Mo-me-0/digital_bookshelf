
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget{
  final String title;
  final String message;
  final VoidCallback onPressed;
  
  const ConfirmDialog({super.key,
    required this.title,
    required this.message,
    required this.onPressed
  });
  
  @override
  Widget build(BuildContext context) {

    return AlertDialog(
        backgroundColor: AppTheme.background,
        
        // Title
        title: Text(title,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Message
        content: Text(message),
        
        // Buttons
        actions: [
          // Cancel button
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          
          // Remove button
          MaterialButton(
            onPressed: onPressed,
            color: AppTheme.error,
            child: const Text('Remove',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
  }
}