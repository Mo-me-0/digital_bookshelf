import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/screens/category_detail_page.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:digital_bookshelf/theme/app_theme.dart';
import 'package:digital_bookshelf/widgets/category_card.dart';
import 'package:digital_bookshelf/widgets/category_dialog.dart';
import 'package:digital_bookshelf/widgets/category_search.dart';
import 'package:digital_bookshelf/widgets/confirm_dialog.dart';
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
        
        // Search button
        actions: [
          IconButton(
            onPressed: () => _showSearch(context),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shelves, 
                    size: 80,
                    color: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your bookshelf is empty.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  const Text('Tap + to add a category.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
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
                      
                      return DragTarget<BookCategory>(
                        onWillAcceptWithDetails: (details) => details.data.id != category.id,
                        onAcceptWithDetails: (details) {
                          _reorderCategories(details.data, category);
                        },
                        builder: (context, candidateData, rejectedData) {
                          final isOver = candidateData.isNotEmpty;
                          
                          // Long press dragging
                          return LongPressDraggable<BookCategory>(
                            data: category,
                            feedback: Material(
                              color: Colors.transparent,
                              child: SizedBox(
                                width: 90,
                                height: 145,
                                child: Opacity(
                                  opacity: 0.85,
                                  child: CategoryCard(
                                    category: category,
                                    docCount: ShelfServices.countDocuments(category.id),
                                  ),
                                ),
                              ),
                            ),
                            
                            // State of the category tile when dragging
                            childWhenDragging: Opacity(
                              opacity: 0.35,
                              child: CategoryCard(
                                category: category,
                                docCount: ShelfServices.countDocuments(category.id),
                              ),
                            ),
                            
                            // Indication for drop targates
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isOver
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.accent.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : [],
                              ),
                              
                              // Default Category tile state
                              child: CategoryCard(
                                category: category,
                                docCount: ShelfServices.countDocuments(category.id),
                                onTap: () => _openCategoryDetail(category),
                                onDoubleTap: () => _showOptions(context, category),
                              ),
                            ),
                          );
                        },
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
  
  // Reorder categories based on drag and drop
  void _reorderCategories(BookCategory draggedCategory, BookCategory targetCategory) async {
    final categories = ShelfServices.getCategories();
    final fromIndex = categories.indexWhere((c) => c.id == draggedCategory.id);
    final toIndex = categories.indexWhere((c) => c.id == targetCategory.id);
    
    if (fromIndex == -1 || toIndex == -1 || fromIndex == toIndex) return;
    
    setState(() {
      final item = categories.removeAt(fromIndex);
      categories.insert(toIndex, item);
      
      // Update order field for all categories
      for (int i = 0; i < categories.length; i++) {
        categories[i].order = i;
        ShelfServices.updateCategory(categories[i]);
      }
    });
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
  
  // Change name, icon or spine color of a category 
  void _editCategory(BuildContext context, BookCategory category) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => CategoryDialog(existing: category,),
    );
  }
  
  // Confirm and delete category  
  void _deleteCategory(BuildContext context, BookCategory category) async {
    showDialog(
      context: context,
      builder: (context) => ConfirmDialog(
        title: 'Delete Category?',
        message: '"${category.name.trim().isEmpty ? '???' : category.name}" and all its files will be permanently deleted.',
        onPressed: () async {
          Navigator.pop(context); // close dialog
          await ShelfServices.deleteCategory(category.id);
          if (context.mounted) {
            Navigator.pop(context); // close the options sheet
          }
        },
      ),
    );
  }
  
  void _showSearch(BuildContext context) {
   showSearch(context: context, delegate: CategorySearch());
  }
}