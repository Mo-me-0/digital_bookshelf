import 'dart:io';
import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/screens/category_detail_page.dart';
import 'package:digital_bookshelf/services/file_services.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  final String title;
  const HomePage({super.key, required this.title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      
      // Display list of categories
      body: ValueListenableBuilder<Box<BookCategory>>(
        valueListenable: ShelfServices.categoriesListnable,
        builder: (context, box, child) {
          // fetch categories list from hive database
          final categories = ShelfServices.getCategories();
          
          // if there are no categories
          if(categories.isEmpty) return Center(child: Text('Your bookshelf is empty.\nTap + to add a category.'),);
          
          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Card(
                child: ListTile(
                  // go to target category detail page
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => CategoryDetailPage(category: category),
                    ));
                  },
                  leading: category.imagePath != null && File(category.imagePath!).existsSync()
                    ? Image.file(File(category.imagePath!)) 
                    : Icon(Icons.image, size: 50,),
                  title: Text(category.name),
                  trailing: IconButton(
                    // remove target category
                    onPressed: () => ShelfServices.deleteCategory(category.id),
                    icon: Icon(Icons.delete), 
                  ),
                ),
              );
            },
          );
        },
      ),
      
      // Add category button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategory(context),
        child: Icon(Icons.add),
      ),
    );
  }
  
  // Add Category Dialog
  void _showAddCategory(BuildContext context) {
    final controller = TextEditingController();
    String? categoryIcon;
    showDialog(
      context: context,
      builder: (context)  => AlertDialog(
        title: Text('Add Category'),
        content: Column(
          children: [
            // To add an image
            GestureDetector(
              onTap: () async {
                categoryIcon = await FileServices.chooseImage();
              },
              child: SizedBox(
                width: 60,
                height: 60,
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 80,
                ),
              ),
            ),
            
            SizedBox(height: 20,),
            
            // Name field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('category name:'),
                TextField(controller: controller),
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
          
          // Add button(Create category)
          ElevatedButton(
            onPressed: () {
              // save the created category to hive
              ShelfServices.addCategory(
                // create a category with selected options
                BookCategory(
                  id: const Uuid().v4(), // create unique id  
                  name: controller.text.trim(), 
                  imagePath: categoryIcon,
                  colorHex: 'FF6D4C2A', 
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
      ),
    );
  }
}