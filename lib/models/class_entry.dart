import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

part 'class_entry.g.dart';

@HiveType(typeId: 9)
class ClassEntry extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  String className;

  @HiveField(2)
  DateTime timestamp;

  @HiveField(3)
  int? durationMinutes;

  @HiveField(4)
  String? notes;

  ClassEntry({
    String? id,
    required this.className,
    this.durationMinutes,
    this.notes,
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

  String get durationFormatted {
    if (durationMinutes == null) return '';
    if (durationMinutes! >= 60) {
      final hours = durationMinutes! ~/ 60;
      final mins = durationMinutes! % 60;
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${durationMinutes}m';
  }
}
