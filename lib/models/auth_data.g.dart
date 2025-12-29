// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuthDataAdapter extends TypeAdapter<AuthData> {
  @override
  final typeId = 7;

  @override
  AuthData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthData(
      deviceId: fields[0] as String,
      jwtToken: fields[1] as String?,
      tokenExpiry: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AuthData obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.deviceId)
      ..writeByte(1)
      ..write(obj.jwtToken)
      ..writeByte(2)
      ..write(obj.tokenExpiry);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
