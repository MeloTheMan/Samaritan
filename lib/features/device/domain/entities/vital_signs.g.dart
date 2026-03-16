// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vital_signs.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VitalSignsAdapter extends TypeAdapter<VitalSigns> {
  @override
  final int typeId = 10;

  @override
  VitalSigns read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VitalSigns(
      temperature: fields[0] as double,
      heartRate: fields[1] as int,
      oxygenSaturation: fields[2] as int,
      timestamp: fields[3] as DateTime,
      fallDetected: fields[4] as bool,
      suddenMovement: fields[5] as bool,
      ambientTemperature: fields[6] as double?,
      humidity: fields[7] as double?,
      sensorStatus: fields[8] as SensorStatus,
    );
  }

  @override
  void write(BinaryWriter writer, VitalSigns obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.temperature)
      ..writeByte(1)
      ..write(obj.heartRate)
      ..writeByte(2)
      ..write(obj.oxygenSaturation)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.fallDetected)
      ..writeByte(5)
      ..write(obj.suddenMovement)
      ..writeByte(6)
      ..write(obj.ambientTemperature)
      ..writeByte(7)
      ..write(obj.humidity)
      ..writeByte(8)
      ..write(obj.sensorStatus);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VitalSignsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SensorStatusAdapter extends TypeAdapter<SensorStatus> {
  @override
  final int typeId = 14;

  @override
  SensorStatus read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SensorStatus(
      max30102Available: fields[0] as bool,
      mpu6050Available: fields[1] as bool,
      dht11Available: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SensorStatus obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.max30102Available)
      ..writeByte(1)
      ..write(obj.mpu6050Available)
      ..writeByte(2)
      ..write(obj.dht11Available);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SensorStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
