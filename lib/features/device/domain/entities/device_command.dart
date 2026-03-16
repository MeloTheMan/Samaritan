import 'dart:typed_data';
import 'package:equatable/equatable.dart';

enum DeviceCommandType {
  // Legacy commands
  updateFirmware,
  setMeasurementFrequency,
  setAlertThresholds,
  calibrate,
  enableFallDetection,
  disableFallDetection,
  reboot,
  
  // Intervention commands
  takeCharge,
  endIntervention,
  acknowledgeAlert,
  cancelAlert,
  requestStatus,
  reset,
  calibrateTemperature,
}

class DeviceCommand extends Equatable {
  final DeviceCommandType type;
  final Uint8List payload;

  const DeviceCommand({
    required this.type,
    required this.payload,
  });

  @override
  List<Object?> get props => [type, payload];

  factory DeviceCommand.setMeasurementFrequency(int frequencySeconds) {
    final bytes = Uint8List(4);
    final byteData = ByteData.sublistView(bytes);
    byteData.setUint32(0, frequencySeconds, Endian.little);
    return DeviceCommand(
      type: DeviceCommandType.setMeasurementFrequency,
      payload: bytes,
    );
  }

  factory DeviceCommand.setAlertThresholds({
    required double tempMin,
    required double tempMax,
    required int heartRateMin,
    required int heartRateMax,
    required int oxygenSatMin,
  }) {
    final bytes = Uint8List(18);
    final byteData = ByteData.sublistView(bytes);
    byteData.setFloat32(0, tempMin, Endian.little);
    byteData.setFloat32(4, tempMax, Endian.little);
    byteData.setUint16(8, heartRateMin, Endian.little);
    byteData.setUint16(10, heartRateMax, Endian.little);
    byteData.setUint16(12, oxygenSatMin, Endian.little);
    return DeviceCommand(
      type: DeviceCommandType.setAlertThresholds,
      payload: bytes,
    );
  }

  factory DeviceCommand.enableFallDetection() {
    return DeviceCommand(
      type: DeviceCommandType.enableFallDetection,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.disableFallDetection() {
    return DeviceCommand(
      type: DeviceCommandType.disableFallDetection,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.reboot() {
    return DeviceCommand(
      type: DeviceCommandType.reboot,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.calibrate() {
    return DeviceCommand(
      type: DeviceCommandType.calibrate,
      payload: Uint8List(0),
    );
  }

  // Intervention command factories
  factory DeviceCommand.takeCharge() {
    return DeviceCommand(
      type: DeviceCommandType.takeCharge,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.endIntervention() {
    return DeviceCommand(
      type: DeviceCommandType.endIntervention,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.acknowledgeAlert() {
    return DeviceCommand(
      type: DeviceCommandType.acknowledgeAlert,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.cancelAlert() {
    return DeviceCommand(
      type: DeviceCommandType.cancelAlert,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.requestStatus() {
    return DeviceCommand(
      type: DeviceCommandType.requestStatus,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.reset() {
    return DeviceCommand(
      type: DeviceCommandType.reset,
      payload: Uint8List(0),
    );
  }

  factory DeviceCommand.calibrateTemperature(double offset) {
    final offsetStr = offset.toStringAsFixed(1);
    final bytes = Uint8List.fromList(offsetStr.codeUnits);
    return DeviceCommand(
      type: DeviceCommandType.calibrateTemperature,
      payload: bytes,
    );
  }
}
