import 'package:digital_bookshelf/screens/category_detail_page.dart';
import 'package:digital_bookshelf/services/shelf_services.dart';
import 'package:flutter/material.dart';

class CategorySearch extends SearchDelegate<String>{
  // Clear/cancel button
  @override
  List<Widget> buildActions(BuildContext context) =>
    [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          //  return to home page if the query is empty
          if(query.trim().isEmpty) close(context, '');
          query = ''; // empty query 
        },
      ),
    ];

  // Back button
  @override
  Widget? buildLeading(BuildContext context) =>
    IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, ''), // return to home page
    );

  // Final result
  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  // Suggestin based on what user tries to search
  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);
  
  // List of searched categories
  Widget _buildList(BuildContext context) {
    // Fetch catagories from hive 
    final result = ShelfServices.getCategories()
      // filter the categories by comparing them with the query
      .where((category) => category.name.toLowerCase().contains(query.toLowerCase()))
      .toList(); // convert it to list
    
    // If no match found
    if(result.isEmpty){
      return const Center(
        child: Text('No categories found',
        style: TextStyle(fontSize: 16),
        ),
      );
    }
    
    // Create a list for the catagories found
    return Card(
      child: ListView(
        children: result
          .map( (category) => ListTile(
              leading: const Icon(Icons.shelves),
              title: Text(category.name.trim().isEmpty ? '???' 
                : category.name),
              subtitle: Text('${ShelfServices.countDocuments(category.id)} files'),
              onTap: () {
                close(context, category.id);
                Navigator.push(context, 
                  MaterialPageRoute(builder: (contect) => 
                    CategoryDetailPage(category: category),
                ));
              },
            ),
          ).toList(), // convert to list of 'ListTile' widget
      ),
    );
  }
}
