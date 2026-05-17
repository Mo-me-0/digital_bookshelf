import 'package:hive/hive.dart';

part 'book_document.g.dart';

// represent the pdfs or documents in a category
@HiveType(typeId: 1)
class BookDocument extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String categoryId;

  @HiveField(2)
  late String name;

  // Absolute path on-device
  @HiveField(3)
  late String filePath;

  // 'pdf' | 'docx' | 'pptx'
  @HiveField(4)
  late String fileType;

  @HiveField(5)
  late DateTime addedAt;

  @HiveField(6)
  late int fileSizeBytes;

  BookDocument({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.filePath,
    required this.fileType,
    required this.addedAt,
    required this.fileSizeBytes,
  });
}
