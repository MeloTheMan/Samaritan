import 'package:equatable/equatable.dart';
import 'vital_signs.dart';

enum OperationMode {
  owner,        // Connected to owner's phone
  intervention, // Connected to rescuer's phone
  alert,        // Emergency alert active
}

class DeviceStatus extends Equatable {
  final OperationMode mode;
  final bool alertActive;
  final bool alertAcknowledged;
  final SensorStatus sensorStatus;
  final String firmwareVersion;

  const DeviceStatus({
    required this.mode,
    required this.alertActive,
    required this.alertAcknowledged,
    required this.sensorStatus,
    required this.firmwareVersion,
  });

  factory DeviceStatus.fromBytes(List<int> data) {
    if (data.length < 20) {
      throw Exception("Invalid device status data length: ${data.length}");
    }

    final mode = OperationMode.values[data[0]];
    final alertActive = data[1] == 1;
    final alertAcknowledged = data[2] == 1;
    final sensorStatus = SensorStatus.fromByte(data[3]);
    
    // Firmware version (16 bytes)
    final firmwareBytes = data.sublist(4, 20);
    final firmwareVersion = String.fromCharCodes(
      firmwareBytes.takeWhile((byte) => byte != 0),
    );

    return DeviceStatus(
      mode: mode,
      alertActive: alertActive,
      alertAcknowledged: alertAcknowledged,
      sensorStatus: sensorStatus,
      firmwareVersion: firmwareVersion,
    );
  }

  @override
  List<Object?> get props => [
        mode,
        alertActive,
        alertAcknowledged,
        sensorStatus,
        firmwareVersion,
      ];
}