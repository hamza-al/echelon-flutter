import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'food_entry.g.dart';

@HiveType(typeId: 4)
class FoodEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int calories;

  @HiveField(3)
  double? protein;

  @HiveField(4)
  DateTime timestamp;

  @HiveField(5)
  double? carbs;

  @HiveField(6)
  double? fats;

  FoodEntry({
    String? id,
    required this.name,
    required this.calories,
    this.protein,
    this.carbs,
    this.fats,
    DateTime? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  String get timeFormatted {
    final hour = timestamp.hour;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}

