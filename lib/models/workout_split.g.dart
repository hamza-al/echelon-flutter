// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_split.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WorkoutSplitAdapter extends TypeAdapter<WorkoutSplit> {
  @override
  final typeId = 8;

  @override
  WorkoutSplit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSplit(
      splitType: fields[0] as String,
      dayNames: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSplit obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.splitType)
      ..writeByte(1)
      ..write(obj.dayNames);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSplitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
