import 'package:hive_ce/hive.dart';

part 'auth_data.g.dart';

@HiveType(typeId: 7)
class AuthData extends HiveObject {
  @HiveField(0)
  String deviceId;

  @HiveField(1)
  String? jwtToken;

  @HiveField(2)
  DateTime? tokenExpiry;

  AuthData({
    required this.deviceId,
    this.jwtToken,
    this.tokenExpiry,
  });
}

