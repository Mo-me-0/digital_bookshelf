import 'package:hive/hive.dart';

part 'book_category.g.dart';

// Ctagory that holds a collection for documents
@HiveType(typeId: 0)
class BookCategory extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  // path to the user-chosen cover image
  @HiveField(2)
  late String? imagePath;

  @HiveField(3)
  late String colorHex; // e.g. 'FF6D4C2A'

  @HiveField(4)
  late DateTime createdAt;
  
  @HiveField(5)
  late int order; // for reordering when displaying

  BookCategory({
    required this.id,
    required this.name,
    this.imagePath,
    required this.colorHex,
    required this.createdAt,
    required this.order,
  });
}
