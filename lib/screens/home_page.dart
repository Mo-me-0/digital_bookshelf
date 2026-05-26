import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/screens/category_detail_page.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:digital_bookshelf/widgets/category_card.dart';
import 'package:digital_bookshelf/widgets/category_dialog.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_stories,
              size: 22,
            ),
            SizedBox(width: 8),
            const Text('My Bookshelf'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search),
          ),
        ],
      ),
      
      // Display list of categories
      body: ValueListenableBuilder<Box<BookCategory>>(
        valueListenable: ShelfServices.categoriesListnable,
        builder: (context, box, child) {
          // fetch categories list from hive database
          final categories = ShelfServices.getCategories();
          
          // if there are no categories
          if(categories.isEmpty) {
            return Center(
              child: Text('Your bookshelf is empty.\nTap + to add a category.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          
          return CustomScrollView(
            slivers: [
              // Show total number of categories
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '${categories.length} ${categories.length == 1 ? 'category' : 'categories'}'
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.62,
                  ),
                  
                  delegate: SliverChildBuilderDelegate(
                    childCount: categories.length,
                    (context, index) {
                      // Access each category
                      final category = categories[index];
                      
                      return CategoryCard(
                        category: category,
                        docCount: ShelfServices.countDocuments(category.id), 
                        onTap: () => _openCategoryDetail(category), 
                        onLongPress:() => _showOptions(context, category),
                      );
                    }
                  ),
                ),
              ),
            ],
          ); 
        },
      ),
      
      // Add category button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategory(context),
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
      ),
    );
  }
  
  // Add Category Dialog
  void _showAddCategory(BuildContext context) {    
    showDialog(
      context: context,
      builder: (context)  => StatefulBuilder(
        builder: (context, setState) => CategoryDialog(),
      ),
    );
  }
  
  // To go to next page
  void _openCategoryDetail(BookCategory category) {
    Navigator.push(context, 
      MaterialPageRoute(
        builder: (contect) => CategoryDetailPage(category: category),
      ),
    );
  }
  
  // Options for editing and deleting
  void _showOptions(BuildContext context, BookCategory category) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, 
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Category'),
              onTap: () => _editCategory(context, category),
            ),
            
            ListTile(
              leading: Icon(Icons.delete,
                color: AppTheme.error,
              ),
              title: Text('Delete Category',
                style: TextStyle(
                  color: AppTheme.error,
                ),
              ),
              onTap: () => _deleteCategory(context, category),
            ),
          ],
        ),
      ),
    );
  }
  
  void _editCategory(BuildContext context, BookCategory category) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(existing: category,),
    );
  }
  
  // Remove the category
  void _deleteCategory(BuildContext context, BookCategory category) async {
    Navigator.pop(context);
    await ShelfServices.deleteCategory(category.id);
  }
}