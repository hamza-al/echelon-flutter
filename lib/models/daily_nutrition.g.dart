// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_nutrition.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyNutritionAdapter extends TypeAdapter<DailyNutrition> {
  @override
  final typeId = 5;

  @override
  DailyNutrition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyNutrition(
      id: fields[0] as String?,
      date: fields[1] as DateTime,
      entries: (fields[2] as List?)?.cast<FoodEntry>(),
      calorieGoal: fields[3] == null ? 2000 : (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DailyNutrition obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.entries)
      ..writeByte(3)
      ..write(obj.calorieGoal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyNutritionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
