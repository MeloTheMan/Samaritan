// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'care_action.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CareActionAdapter extends TypeAdapter<CareAction> {
  @override
  final int typeId = 24;

  @override
  CareAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CareAction(
      actionId: fields[0] as String,
      description: fields[1] as String,
      performedAt: fields[2] as DateTime,
      duration: fields[3] as Duration,
      notes: fields[4] as String?,
      completed: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CareAction obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.actionId)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.performedAt)
      ..writeByte(3)
      ..write(obj.duration)
      ..writeByte(4)
      ..write(obj.notes)
      ..writeByte(5)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
