import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final BookCategory category;
  final int docCount;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  
  const CategoryCard({
    super.key,
    required this.category,
    required this.docCount,
    this.onTap, // open category detail page
    this.onDoubleTap, // to edit or delete the category
  });
  
  Color get _spineColor {
    try{
      return Color(int.parse('FF${category.colorHex}', radix: 16));
    } catch (_){
      return AppTheme.primary;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: Column(
        children: [
          // Category Icon
          Expanded(
            child: _BookWidget(
              category: category,
              spineColor: _spineColor
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Category name
          Text(
            category.name.trim().isNotEmpty
              ? category.name
              : '???',
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 2),
          
          // Number of documents inside the category
          Text(
            '$docCount ${docCount == 1 ? 'file' : 'files'}',
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _BookWidget extends StatelessWidget{
  final BookCategory category;
  final Color spineColor;
  
  const _BookWidget({
    required this.category,
    required this.spineColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Drop shadow
        Positioned(
          bottom: 0,
          left: 4,
          right: 0,
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
          ), 
        ),
        
        // Book cover
        Positioned.fill(
          bottom: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: spineColor),
              borderRadius: BorderRadius.circular(8),
              color: spineColor.withValues(alpha: 0.12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Cover image or gradiant
                  _buildCover(),
                  
                  // Spine/left strip
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: spineColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          bottomLeft: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Adaptive catagory icon
  Widget _buildCover() {
    // If category has an image show that
    if(category.imagePath != null) {
      if (kIsWeb) {
        return Image.network(category.imagePath!, fit: BoxFit.cover);
      } else {
        final image = File(category.imagePath!);
        if(image.existsSync()) {
          return Image.file(image, fit: BoxFit.cover);
        }
      }
    }
    
    // If category doesn't have an image
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            spineColor.withValues(alpha: 0.7),
            spineColor.withValues(alpha: 0.4),
          ],
        ),
      ),
      
      // First letter of category name
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            category.name.trim().isNotEmpty
              ? category.name[0].toUpperCase()
              : '?',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ),
      ),
    );
  }
}