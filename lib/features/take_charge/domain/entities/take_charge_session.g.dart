// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'take_charge_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TakeChargeSessionAdapter extends TypeAdapter<TakeChargeSession> {
  @override
  final int typeId = 26;

  @override
  TakeChargeSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TakeChargeSession(
      sessionId: fields[0] as String,
      victimDeviceId: fields[1] as String,
      volunteerId: fields[2] as String,
      startTime: fields[3] as DateTime,
      endTime: fields[4] as DateTime?,
      initialPrognosis: fields[5] as Prognosis,
      vitalSignsHistory: (fields[6] as List).cast<VitalSigns>(),
      actionsPerformed: (fields[7] as List).cast<CareAction>(),
      outcome: fields[8] as InterventionOutcome?,
      alertId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TakeChargeSession obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.victimDeviceId)
      ..writeByte(2)
      ..write(obj.volunteerId)
      ..writeByte(3)
      ..write(obj.startTime)
      ..writeByte(4)
      ..write(obj.endTime)
      ..writeByte(5)
      ..write(obj.initialPrognosis)
      ..writeByte(6)
      ..write(obj.vitalSignsHistory)
      ..writeByte(7)
      ..write(obj.actionsPerformed)
      ..writeByte(8)
      ..write(obj.outcome)
      ..writeByte(9)
      ..write(obj.alertId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TakeChargeSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
