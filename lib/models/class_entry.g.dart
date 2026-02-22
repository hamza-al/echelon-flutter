// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'class_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClassEntryAdapter extends TypeAdapter<ClassEntry> {
  @override
  final typeId = 9;

  @override
  ClassEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClassEntry(
      id: fields[0] as String?,
      className: fields[1] as String,
      durationMinutes: (fields[3] as num?)?.toInt(),
      notes: fields[4] as String?,
      timestamp: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ClassEntry obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.className)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
