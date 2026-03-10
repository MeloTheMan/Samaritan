// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prognosis.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrognosisAdapter extends TypeAdapter<Prognosis> {
  @override
  final int typeId = 22;

  @override
  Prognosis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Prognosis(
      level: fields[0] as PrognosisLevel,
      description: fields[1] as String,
      criticalFactors: (fields[2] as List).cast<CriticalFactor>(),
      initialRecommendations: (fields[3] as List).cast<String>(),
      analyzedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Prognosis obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.level)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.criticalFactors)
      ..writeByte(3)
      ..write(obj.initialRecommendations)
      ..writeByte(4)
      ..write(obj.analyzedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrognosisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CriticalFactorAdapter extends TypeAdapter<CriticalFactor> {
  @override
  final int typeId = 23;

  @override
  CriticalFactor read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CriticalFactor(
      factor: fields[0] as String,
      severity: fields[1] as String,
      description: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CriticalFactor obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.factor)
      ..writeByte(1)
      ..write(obj.severity)
      ..writeByte(2)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CriticalFactorAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
