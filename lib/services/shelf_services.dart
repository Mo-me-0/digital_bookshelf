import 'package:digital_bookshelf/models/book_category.dart';
import 'package:digital_bookshelf/models/book_document.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// To manage local persistent storage of categories and docs
class ShelfServices {
  static const String _categoryBox = 'categories';
  static const String _documentBox = 'documents';
  
  static Future<void> init() async {
    // register the generated adapter for BookCategory and BookDocuments
    Hive.registerAdapter(BookCategoryAdapter());
    Hive.registerAdapter(BookDocumentAdapter());
    
    // Opens the category storage box
    try {
      await Hive.openBox<BookCategory>(_categoryBox);
    } catch(e) {
      // If schema changes broke the old dev data, clear it and start fresh.
      await Hive.deleteBoxFromDisk(_categoryBox);
      await Hive.openBox<BookCategory>(_categoryBox);
    }
    
    // Opens the document storage box
    try {
     await Hive.openBox<BookDocument>(_documentBox); 
    } catch(e) {
      await Hive.deleteBoxFromDisk(_documentBox);
      await Hive.openBox<BookDocument>(_documentBox);
    }
  }
  
  // Access the boxes for category and document
  static Box<BookCategory> get _categories => Hive.box<BookCategory>(_categoryBox);
  static Box<BookDocument> get _documents => Hive.box<BookDocument>(_documentBox);
  
  // ---- Category Operations ---- //
  // For UI to reactively rebuild when categories change
  static ValueListenable<Box<BookCategory>> get categoriesListnable 
    => _categories.listenable();
  
  // To get all categories sorted by their order property, falling back to createdAt
  static List<BookCategory> getCategories(){
    return _categories.values.toList()
    ..sort((a, b) {
      final cmp = a.order.compareTo(b.order);
      if (cmp != 0) return cmp;
      return a.createdAt.compareTo(b.createdAt);
    });
  }
  
  // To add new category to category storage box
  static Future<void> addCategory(BookCategory category) => 
    _categories.put(category.id, category);
    
  // To persist changes on existing category
  static Future<void> updateCategory(BookCategory category) => category.save();
  
  // Remove category form storage box
  static Future<void> deleteCategory(String id) async {
    // Remove all documents inside the category first
    final toDelete = _documents.values
      .where((doc) => doc.categoryId == id)
      .map((doc) => doc.key)
      .toList();
    await _documents.deleteAll(toDelete);
    
    // finally delete the category
    await _categories.delete(id);
  }
  
  // ---- Document Operations ---- //
  // For UI to reactively rebuild when documents change
  static ValueListenable<Box<BookDocument>> get documentsListenable =>
      _documents.listenable();

  // Get list of documents inside a category
  static List<BookDocument> getDocuments(String categoryId)
    => _documents.values
          .where((d) => d.categoryId == categoryId)
          .toList()
        ..sort((a, b) => a.addedAt.compareTo(b.addedAt));

  // To add new document to storage box
  static Future<void> addDocument(BookDocument doc) => _documents.put(doc.id, doc);

  // Remove document form storage box
  static Future<void> deleteDocument(String id) => _documents.delete(id);

  // Get number of documents in a category
  static int countDocuments(String categoryId) =>
      _documents.values.where((d) => d.categoryId == categoryId).length;
}