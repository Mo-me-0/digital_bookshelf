import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:digital_bookshelf/services/file_services.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:uuid/uuid.dart';

class CategoryDialog extends StatefulWidget {
  final BookCategory? existing;
  
  const CategoryDialog({super.key,
    this.existing
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _controller;
  String? _categoryIcon;
  late int _colorIndex;
  
  // Convert Color object to string
  String _colorHex() {
    final Color c = AppTheme.shelfColors[_colorIndex];
    return c.toARGB32().toRadixString(16)
      .substring(2)
      .toUpperCase();
  }
  
  @override
  void initState() {
    super.initState();
    final existing = widget.existing; // for easy access
    
    // If editing an existing category, get that category data
    _categoryIcon = existing?.imagePath;
    _controller = TextEditingController(
      text: existing?.name ?? '',
    );
    _colorIndex = 0;
    
    if(existing != null) {
      // Find the index that muches the category's colorHex
      final index = AppTheme.shelfColors.indexWhere(
        (color) => color.toARGB32().toRadixString(16).toUpperCase().substring(2) == 
          existing.colorHex,
      );
      
      _colorIndex = index < 0 ? 0 : index;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Identify edit mode or not
    final bool isEdit = widget.existing != null;
    
    return AlertDialog(
      title: Text(isEdit ? 'Edit Category' : 'New Category',
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: AppTheme.background,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          
          // To add an image
          GestureDetector(
            onTap: () async {
              _categoryIcon = await FileServices.chooseImage();
              setState(() {});
            },
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppTheme.shelfColors[_colorIndex].withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.shelfColors[_colorIndex].withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: _categoryIcon != null && (kIsWeb || File(_categoryIcon!).existsSync())
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: kIsWeb
                        ? Image.network(_categoryIcon!,
                            fit: BoxFit.cover,
                          )
                        : Image.file(File(_categoryIcon!),
                            fit: BoxFit.cover,
                          ),
                  )
                
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: AppTheme.shelfColors[_colorIndex],
                      ),
                      
                      Text('cover',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.shelfColors[_colorIndex],
                        ),
                      ),
                    ],
                  ),
            ),
          ),
          
          // Name field
          const SizedBox(height: 20,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category name:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 15),
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'e.g. Mobile App',
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          
          // Spine color choice
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Spine color:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 5),
              SizedBox(
                height: 38,
                width: 224,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppTheme.shelfColors.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    // identify if the current color is the selected color
                    final bool selected = index == _colorIndex;
                    
                    // List of selectable colors
                    return GestureDetector(
                      onTap: () {
                        setState(() => _colorIndex = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppTheme.shelfColors[index],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? AppTheme.accent : Colors.transparent,
                            width: 3,
                          ),
                        boxShadow: selected
                            ? [BoxShadow(color: AppTheme.shelfColors[index].withValues(alpha: 0.5),
                                blurRadius: 8, spreadRadius: 1)]
                            : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      
      // Buttons
      actions: [
        // Cancel button
        TextButton(
          // close the dialog
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        
        isEdit ? MaterialButton(
            color: AppTheme.primary,
            textColor: Colors.white,
            onPressed: () {
              final BookCategory category = widget.existing!;
              // Apply changes to existing category
              category.name = _controller.text.trim();
              category.colorHex = _colorHex();
              category.imagePath = _categoryIcon;
              
              // save the changes made to hive
              ShelfServices.updateCategory(category);
              
              // close the dialog
              Navigator.pop(context);
            },
            child: const Text("Save"),
          )
          
          // Add button(Create category)
        :  MaterialButton(
            color: AppTheme.primary,
            textColor: Colors.white,
            onPressed: () {
              // save the created category to hive
              ShelfServices.addCategory(
                // create a category with selected options
                BookCategory(
                  id: const Uuid().v4(), // create unique id  
                  name: _controller.text.trim(), 
                  imagePath: _categoryIcon,
                  colorHex: _colorHex(), 
                  createdAt: DateTime.now(),
                  order: ShelfServices.getCategories().length,
                )
              );
              
              // close the dialog
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
      ],
    );
  }
}