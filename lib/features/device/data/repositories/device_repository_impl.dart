import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/device_repository.dart';
import '../../domain/entities/wearable_device.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/device_settings.dart';
import '../../domain/entities/device_command.dart';
import '../services/bluetooth_service.dart';

@LazySingleton(as: DeviceRepository)
class DeviceRepositoryImpl implements DeviceRepository {
  final BluetoothService bluetoothService;
  final Box<DeviceSettings> settingsBox;
  final Box<VitalSigns> vitalSignsBox;
  final Box<String> connectedDeviceBox;

  DeviceRepositoryImpl({
    required this.bluetoothService,
    required this.settingsBox,
    required this.vitalSignsBox,
    required this.connectedDeviceBox,
  });

  @override
  Stream<Either<Failure, List<WearableDevice>>> scanForDevices({
    Duration? timeout,
  }) async* {
    try {
      await for (final scanResults in bluetoothService.scanForDevices(
        timeout: timeout ?? const Duration(seconds: 10),
      )) {
        final devices = scanResults.map((result) {
          return WearableDevice(
            id: result.device.remoteId.toString(),
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            firmwareVersion: 'Unknown',
            batteryLevel: 100,
            status: ConnectionStatus.disconnected,
            signalStrength: result.rssi,
          );
        }).toList();
        
        yield Right(devices);
      }
    } catch (e) {
      yield Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> stopScan() async {
    try {
      await bluetoothService.stopScan();
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WearableDevice>> connectToDevice(String deviceId) async {
    try {
      await bluetoothService.connectToDevice(deviceId);
      
      // Save as connected device
      await connectedDeviceBox.put('current', deviceId);
      
      final device = WearableDevice(
        id: deviceId,
        name: 'Samaritan Bracelet',
        firmwareVersion: '1.0.0',
        batteryLevel: 100,
        status: ConnectionStatus.connected,
        lastConnected: DateTime.now(),
      );
      
      return Right(device);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> disconnectFromDevice(String deviceId) async {
    try {
      await bluetoothService.disconnectFromDevice(deviceId);
      
      // Remove from connected device
      await connectedDeviceBox.delete('current');
      
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, VitalSigns>> getVitalSignsStream(String deviceId) async* {
    try {
      await for (final vitalSigns in bluetoothService.getVitalSignsStream(deviceId)) {
        // Save to local storage
        await saveVitalSigns(deviceId, vitalSigns);
        yield Right(vitalSigns);
      }
    } catch (e) {
      yield Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, DeviceSettings>> getDeviceSettings(String deviceId) async {
    try {
      final settings = settingsBox.get(deviceId);
      if (settings != null) {
        return Right(settings);
      }
      
      // Return default settings if not found
      final defaultSettings = DeviceSettings.defaultSettings();
      await settingsBox.put(deviceId, defaultSettings);
      return Right(defaultSettings);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDeviceSettings(
    String deviceId,
    DeviceSettings settings,
  ) async {
    try {
      // Save settings locally
      await settingsBox.put(deviceId, settings);
      
      // Send settings to device
      final command = DeviceCommand.setAlertThresholds(
        tempMin: settings.temperatureThresholdMin,
        tempMax: settings.temperatureThresholdMax,
        heartRateMin: settings.heartRateThresholdMin,
        heartRateMax: settings.heartRateThresholdMax,
        oxygenSatMin: settings.oxygenSaturationThresholdMin,
      );
      
      await bluetoothService.sendCommand(deviceId, command);
      
      // Update measurement frequency
      final freqCommand = DeviceCommand.setMeasurementFrequency(
        settings.measurementFrequency,
      );
      await bluetoothService.sendCommand(deviceId, freqCommand);
      
      // Update fall detection
      if (settings.fallDetectionEnabled) {
        await bluetoothService.sendCommand(
          deviceId,
          DeviceCommand.enableFallDetection(),
        );
      } else {
        await bluetoothService.sendCommand(
          deviceId,
          DeviceCommand.disableFallDetection(),
        );
      }
      
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendCommand(
    String deviceId,
    DeviceCommand command,
  ) async {
    try {
      await bluetoothService.sendCommand(deviceId, command);
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFirmware(
    String deviceId,
    List<int> firmwareData,
  ) async {
    try {
      await bluetoothService.updateFirmware(
        deviceId,
        Uint8List.fromList(firmwareData),
      );
      return const Right(null);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VitalSigns>>> getVitalSignsHistory(
    String deviceId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allVitalSigns = vitalSignsBox.values.toList();
      
      // Filter by date range if provided
      var filteredSigns = allVitalSigns;
      
      if (startDate != null) {
        filteredSigns = filteredSigns
            .where((vs) => vs.timestamp.isAfter(startDate))
            .toList();
      }
      
      if (endDate != null) {
        filteredSigns = filteredSigns
            .where((vs) => vs.timestamp.isBefore(endDate))
            .toList();
      }
      
      // Sort by timestamp descending
      filteredSigns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return Right(filteredSigns);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveVitalSigns(
    String deviceId,
    VitalSigns vitalSigns,
  ) async {
    try {
      final key = '${deviceId}_${vitalSigns.timestamp.millisecondsSinceEpoch}';
      await vitalSignsBox.put(key, vitalSigns);
      
      // Clean up old data (keep only last 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final keysToDelete = vitalSignsBox.keys
          .where((key) {
            final vs = vitalSignsBox.get(key);
            return vs != null && vs.timestamp.isBefore(thirtyDaysAgo);
          })
          .toList();
      
      for (final key in keysToDelete) {
        await vitalSignsBox.delete(key);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WearableDevice?>> getConnectedDevice() async {
    try {
      final deviceId = connectedDeviceBox.get('current');
      
      if (deviceId == null) {
        return const Right(null);
      }
      
      final isConnected = bluetoothService.isDeviceConnected(deviceId);
      
      if (!isConnected) {
        await connectedDeviceBox.delete('current');
        return const Right(null);
      }
      
      final device = WearableDevice(
        id: deviceId,
        name: 'Samaritan Bracelet',
        firmwareVersion: '1.0.0',
        batteryLevel: 100,
        status: ConnectionStatus.connected,
        lastConnected: DateTime.now(),
      );
      
      return Right(device);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isDeviceConnected(String deviceId) async {
    try {
      final isConnected = bluetoothService.isDeviceConnected(deviceId);
      return Right(isConnected);
    } catch (e) {
      return Left(BluetoothFailure(e.toString()));
    }
  }
}
