// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      gender: fields[0] as String?,
      weight: fields[1] as String?,
      height: fields[2] as String?,
      goals: (fields[3] as List?)?.cast<String>(),
      hasPaidSubscription: fields[4] == null ? false : fields[4] as bool,
      createdAt: fields[5] as DateTime?,
      lastUpdated: fields[6] as DateTime?,
      longestStreak: fields[7] == null ? 0 : (fields[7] as num).toInt(),
      nutritionGoal: fields[8] as String?,
      targetCalories: (fields[9] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.gender)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.goals)
      ..writeByte(4)
      ..write(obj.hasPaidSubscription)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.lastUpdated)
      ..writeByte(7)
      ..write(obj.longestStreak)
      ..writeByte(8)
      ..write(obj.nutritionGoal)
      ..writeByte(9)
      ..write(obj.targetCalories);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
