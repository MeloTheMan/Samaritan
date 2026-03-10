// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intervention_outcome.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InterventionOutcomeAdapter extends TypeAdapter<InterventionOutcome> {
  @override
  final int typeId = 25;

  @override
  InterventionOutcome read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InterventionOutcome(
      type: fields[0] as OutcomeType,
      notes: fields[1] as String,
      recordedAt: fields[2] as DateTime,
      additionalDetails: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, InterventionOutcome obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.notes)
      ..writeByte(2)
      ..write(obj.recordedAt)
      ..writeByte(3)
      ..write(obj.additionalDetails);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InterventionOutcomeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
