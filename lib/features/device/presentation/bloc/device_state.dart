import 'package:equatable/equatable.dart';
import '../../domain/entities/wearable_device.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/device_settings.dart';

abstract class DeviceState extends Equatable {
  const DeviceState();

  @override
  List<Object?> get props => [];
}

class DeviceInitial extends DeviceState {
  const DeviceInitial();
}

class DeviceScanning extends DeviceState {
  final List<WearableDevice> devices;

  const DeviceScanning({this.devices = const []});

  @override
  List<Object?> get props => [devices];
}

class DeviceScanComplete extends DeviceState {
  final List<WearableDevice> devices;

  const DeviceScanComplete(this.devices);

  @override
  List<Object?> get props => [devices];
}

class DeviceConnecting extends DeviceState {
  final String deviceId;

  const DeviceConnecting(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class DeviceConnected extends DeviceState {
  final WearableDevice device;
  final VitalSigns? currentVitalSigns;
  final DeviceSettings? settings;

  const DeviceConnected({
    required this.device,
    this.currentVitalSigns,
    this.settings,
  });

  @override
  List<Object?> get props => [device, currentVitalSigns, settings];

  DeviceConnected copyWith({
    WearableDevice? device,
    VitalSigns? currentVitalSigns,
    DeviceSettings? settings,
  }) {
    return DeviceConnected(
      device: device ?? this.device,
      currentVitalSigns: currentVitalSigns ?? this.currentVitalSigns,
      settings: settings ?? this.settings,
    );
  }
}

class DeviceDisconnected extends DeviceState {
  const DeviceDisconnected();
}

class DeviceVitalSignsUpdated extends DeviceState {
  final WearableDevice device;
  final VitalSigns vitalSigns;
  final List<VitalSigns> history;

  const DeviceVitalSignsUpdated({
    required this.device,
    required this.vitalSigns,
    this.history = const [],
  });

  @override
  List<Object?> get props => [device, vitalSigns, history];
}

class DeviceSettingsLoaded extends DeviceState {
  final WearableDevice device;
  final DeviceSettings settings;

  const DeviceSettingsLoaded({
    required this.device,
    required this.settings,
  });

  @override
  List<Object?> get props => [device, settings];
}

class DeviceSettingsUpdated extends DeviceState {
  final WearableDevice device;
  final DeviceSettings settings;

  const DeviceSettingsUpdated({
    required this.device,
    required this.settings,
  });

  @override
  List<Object?> get props => [device, settings];
}

class DeviceHistoryLoaded extends DeviceState {
  final WearableDevice device;
  final List<VitalSigns> history;

  const DeviceHistoryLoaded({
    required this.device,
    required this.history,
  });

  @override
  List<Object?> get props => [device, history];
}

class DeviceFirmwareUpdating extends DeviceState {
  final WearableDevice device;
  final double progress;

  const DeviceFirmwareUpdating({
    required this.device,
    required this.progress,
  });

  @override
  List<Object?> get props => [device, progress];
}

class DeviceFirmwareUpdated extends DeviceState {
  final WearableDevice device;

  const DeviceFirmwareUpdated(this.device);

  @override
  List<Object?> get props => [device];
}

class DeviceError extends DeviceState {
  final String message;
  final WearableDevice? device;

  const DeviceError({
    required this.message,
    this.device,
  });

  @override
  List<Object?> get props => [message, device];
}
