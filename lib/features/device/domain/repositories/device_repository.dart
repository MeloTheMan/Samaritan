import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/wearable_device.dart';
import '../entities/vital_signs.dart';
import '../entities/device_settings.dart';
import '../entities/device_command.dart';

abstract class DeviceRepository {
  /// Scan for available devices
  Stream<Either<Failure, List<WearableDevice>>> scanForDevices({Duration? timeout});
  
  /// Stop scanning for devices
  Future<Either<Failure, void>> stopScan();
  
  /// Connect to a device
  Future<Either<Failure, WearableDevice>> connectToDevice(String deviceId);
  
  /// Disconnect from a device
  Future<Either<Failure, void>> disconnectFromDevice(String deviceId);
  
  /// Get real-time vital signs stream
  Stream<Either<Failure, VitalSigns>> getVitalSignsStream(String deviceId);
  
  /// Get device settings
  Future<Either<Failure, DeviceSettings>> getDeviceSettings(String deviceId);
  
  /// Update device settings
  Future<Either<Failure, void>> updateDeviceSettings(
    String deviceId,
    DeviceSettings settings,
  );
  
  /// Send command to device
  Future<Either<Failure, void>> sendCommand(
    String deviceId,
    DeviceCommand command,
  );
  
  /// Update device firmware
  Future<Either<Failure, void>> updateFirmware(
    String deviceId,
    List<int> firmwareData,
  );
  
  /// Get vital signs history
  Future<Either<Failure, List<VitalSigns>>> getVitalSignsHistory(
    String deviceId, {
    DateTime? startDate,
    DateTime? endDate,
  });
  
  /// Save vital signs to local storage
  Future<Either<Failure, void>> saveVitalSigns(
    String deviceId,
    VitalSigns vitalSigns,
  );
  
  /// Get connected device
  Future<Either<Failure, WearableDevice?>> getConnectedDevice();
  
  /// Check if device is connected
  Future<Either<Failure, bool>> isDeviceConnected(String deviceId);
}
