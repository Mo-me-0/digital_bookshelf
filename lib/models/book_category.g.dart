// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_category.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookCategoryAdapter extends TypeAdapter<BookCategory> {
  @override
  final int typeId = 0;

  @override
  BookCategory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookCategory(
      id: fields[0] as String,
      name: fields[1] as String,
      imagePath: fields[2] as String?,
      colorHex: fields[3] as String,
      createdAt: fields[4] as DateTime,
      order: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, BookCategory obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.imagePath)
      ..writeByte(3)
      ..write(obj.colorHex)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.order);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookCategoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
