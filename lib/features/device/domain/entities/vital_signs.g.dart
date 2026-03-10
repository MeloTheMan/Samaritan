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
    );
  }

  @override
  void write(BinaryWriter writer, VitalSigns obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.suddenMovement);
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
