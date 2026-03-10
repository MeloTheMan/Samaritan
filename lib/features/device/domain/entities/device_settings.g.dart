// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_settings.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeviceSettingsAdapter extends TypeAdapter<DeviceSettings> {
  @override
  final int typeId = 13;

  @override
  DeviceSettings read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeviceSettings(
      temperatureThresholdMin: fields[0] as double,
      temperatureThresholdMax: fields[1] as double,
      heartRateThresholdMin: fields[2] as int,
      heartRateThresholdMax: fields[3] as int,
      oxygenSaturationThresholdMin: fields[4] as int,
      measurementFrequency: fields[5] as int,
      fallDetectionEnabled: fields[6] as bool,
      alertsEnabled: fields[7] as bool,
      vibrationEnabled: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DeviceSettings obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.temperatureThresholdMin)
      ..writeByte(1)
      ..write(obj.temperatureThresholdMax)
      ..writeByte(2)
      ..write(obj.heartRateThresholdMin)
      ..writeByte(3)
      ..write(obj.heartRateThresholdMax)
      ..writeByte(4)
      ..write(obj.oxygenSaturationThresholdMin)
      ..writeByte(5)
      ..write(obj.measurementFrequency)
      ..writeByte(6)
      ..write(obj.fallDetectionEnabled)
      ..writeByte(7)
      ..write(obj.alertsEnabled)
      ..writeByte(8)
      ..write(obj.vibrationEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceSettingsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
