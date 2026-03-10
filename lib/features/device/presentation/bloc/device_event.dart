import 'package:equatable/equatable.dart';
import '../../domain/entities/device_settings.dart';

abstract class DeviceEvent extends Equatable {
  const DeviceEvent();

  @override
  List<Object?> get props => [];
}

class StartDeviceScan extends DeviceEvent {
  final Duration? timeout;

  const StartDeviceScan({this.timeout});

  @override
  List<Object?> get props => [timeout];
}

class StopDeviceScan extends DeviceEvent {
  const StopDeviceScan();
}

class ConnectToDevice extends DeviceEvent {
  final String deviceId;

  const ConnectToDevice(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class DisconnectFromDevice extends DeviceEvent {
  final String deviceId;

  const DisconnectFromDevice(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class StartVitalSignsMonitoring extends DeviceEvent {
  final String deviceId;

  const StartVitalSignsMonitoring(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class StopVitalSignsMonitoring extends DeviceEvent {
  const StopVitalSignsMonitoring();
}

class UpdateDeviceSettings extends DeviceEvent {
  final String deviceId;
  final DeviceSettings settings;

  const UpdateDeviceSettings({
    required this.deviceId,
    required this.settings,
  });

  @override
  List<Object?> get props => [deviceId, settings];
}

class LoadDeviceSettings extends DeviceEvent {
  final String deviceId;

  const LoadDeviceSettings(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class LoadVitalSignsHistory extends DeviceEvent {
  final String deviceId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadVitalSignsHistory({
    required this.deviceId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [deviceId, startDate, endDate];
}

class UpdateFirmware extends DeviceEvent {
  final String deviceId;
  final List<int> firmwareData;

  const UpdateFirmware({
    required this.deviceId,
    required this.firmwareData,
  });

  @override
  List<Object?> get props => [deviceId, firmwareData];
}

class LoadConnectedDevice extends DeviceEvent {
  const LoadConnectedDevice();
}
