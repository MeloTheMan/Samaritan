// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wearable_device.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WearableDeviceAdapter extends TypeAdapter<WearableDevice> {
  @override
  final int typeId = 12;

  @override
  WearableDevice read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WearableDevice(
      id: fields[0] as String,
      name: fields[1] as String,
      firmwareVersion: fields[2] as String,
      batteryLevel: fields[3] as int,
      status: fields[4] as ConnectionStatus,
      currentVitalSigns: fields[5] as VitalSigns?,
      lastConnected: fields[6] as DateTime?,
      signalStrength: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, WearableDevice obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.firmwareVersion)
      ..writeByte(3)
      ..write(obj.batteryLevel)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.currentVitalSigns)
      ..writeByte(6)
      ..write(obj.lastConnected)
      ..writeByte(7)
      ..write(obj.signalStrength);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WearableDeviceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConnectionStatusAdapter extends TypeAdapter<ConnectionStatus> {
  @override
  final int typeId = 11;

  @override
  ConnectionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConnectionStatus.disconnected;
      case 1:
        return ConnectionStatus.connecting;
      case 2:
        return ConnectionStatus.connected;
      case 3:
        return ConnectionStatus.error;
      default:
        return ConnectionStatus.disconnected;
    }
  }

  @override
  void write(BinaryWriter writer, ConnectionStatus obj) {
    switch (obj) {
      case ConnectionStatus.disconnected:
        writer.writeByte(0);
        break;
      case ConnectionStatus.connecting:
        writer.writeByte(1);
        break;
      case ConnectionStatus.connected:
        writer.writeByte(2);
        break;
      case ConnectionStatus.error:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
