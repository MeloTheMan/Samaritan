// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_alert.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmergencyAlertAdapter extends TypeAdapter<EmergencyAlert> {
  @override
  final int typeId = 20;

  @override
  EmergencyAlert read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmergencyAlert(
      alertId: fields[0] as String,
      victimDeviceId: fields[1] as String,
      vitalSigns: fields[2] as VitalSigns,
      estimatedLocation: fields[3] as AlertLocation?,
      distance: fields[4] as double?,
      bearing: fields[5] as double?,
      status: fields[6] as AlertStatus,
      receivedAt: fields[7] as DateTime,
      handledByUserId: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, EmergencyAlert obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.alertId)
      ..writeByte(1)
      ..write(obj.victimDeviceId)
      ..writeByte(2)
      ..write(obj.vitalSigns)
      ..writeByte(3)
      ..write(obj.estimatedLocation)
      ..writeByte(4)
      ..write(obj.distance)
      ..writeByte(5)
      ..write(obj.bearing)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.receivedAt)
      ..writeByte(8)
      ..write(obj.handledByUserId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyAlertAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlertLocationAdapter extends TypeAdapter<AlertLocation> {
  @override
  final int typeId = 21;

  @override
  AlertLocation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlertLocation(
      latitude: fields[0] as double,
      longitude: fields[1] as double,
      accuracy: fields[2] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, AlertLocation obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.latitude)
      ..writeByte(1)
      ..write(obj.longitude)
      ..writeByte(2)
      ..write(obj.accuracy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlertLocationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
