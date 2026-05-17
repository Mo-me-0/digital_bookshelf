// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_document.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookDocumentAdapter extends TypeAdapter<BookDocument> {
  @override
  final int typeId = 1;

  @override
  BookDocument read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookDocument(
      id: fields[0] as String,
      categoryId: fields[1] as String,
      name: fields[2] as String,
      filePath: fields[3] as String,
      fileType: fields[4] as String,
      addedAt: fields[5] as DateTime,
      fileSizeBytes: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BookDocument obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.categoryId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.filePath)
      ..writeByte(4)
      ..write(obj.fileType)
      ..writeByte(5)
      ..write(obj.addedAt)
      ..writeByte(6)
      ..write(obj.fileSizeBytes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookDocumentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
