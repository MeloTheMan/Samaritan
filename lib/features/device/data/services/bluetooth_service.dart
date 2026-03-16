import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/device_command.dart';
import '../../domain/entities/device_status.dart';
import '../../../alert/domain/entities/emergency_alert.dart';

@lazySingleton
class BluetoothService {
  static const String SERVICE_UUID = "0000180d-0000-1000-8000-00805f9b34fb";
  static const String VITAL_SIGNS_CHARACTERISTIC_UUID = "00002a37-0000-1000-8000-00805f9b34fb";
  static const String ALERT_CHARACTERISTIC_UUID = "00002a38-0000-1000-8000-00805f9b34fb";
  static const String COMMAND_CHARACTERISTIC_UUID = "00002a39-0000-1000-8000-00805f9b34fb";
  static const String STATUS_CHARACTERISTIC_UUID = "00002a3a-0000-1000-8000-00805f9b34fb";
  
  static const int MAX_RECONNECT_ATTEMPTS = 3;
  static const Duration RECONNECT_DELAY = Duration(seconds: 5);
  
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, StreamController<VitalSigns>> _vitalSignsControllers = {};
  final Map<String, StreamController<EmergencyAlert>> _alertControllers = {};
  final Map<String, StreamController<DeviceStatus>> _statusControllers = {};
  final Map<String, int> _reconnectAttempts = {};
  final Map<String, Timer?> _reconnectTimers = {};
  
  // Helper to normalize UUIDs for comparison
  // Handles both short (180d) and long (0000180d-0000-1000-8000-00805f9b34fb) formats
  String _normalizeUuid(String uuid) {
    String normalized = uuid.toLowerCase().replaceAll('-', '');
    
    // If it's a short UUID (4 characters), expand it to full 128-bit UUID
    if (normalized.length == 4) {
      normalized = '0000${normalized}00001000800000805f9b34fb';
    }
    
    return normalized;
  }
  
  // Stream for scan results
  Stream<List<ScanResult>> scanForDevices({Duration timeout = const Duration(seconds: 10)}) async* {
    final List<ScanResult> results = [];
    
    try {
      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception("Bluetooth not supported by this device");
      }
      
      // Start scanning - scan all devices without service filter for now
      await FlutterBluePlus.startScan(
        timeout: timeout,
        // Removed service filter to detect all BLE devices
        // withServices: [Guid(SERVICE_UUID)],
      );
      
      // Listen to scan results
      await for (final scanResults in FlutterBluePlus.scanResults) {
        results.clear();
        // Filter results to only include devices with our service or named "Samaritan"
        final filteredResults = scanResults.where((result) {
          final name = result.device.platformName;
          final hasService = result.advertisementData.serviceUuids
              .any((uuid) => uuid.toString().toLowerCase() == SERVICE_UUID.toLowerCase());
          final isSamaritan = name.toLowerCase().contains('samaritan');
          
          // Debug: afficher tous les appareils trouvés
          if (name.isNotEmpty) {
            print('📱 Device found: $name (${result.device.remoteId})');
            if (result.advertisementData.serviceUuids.isNotEmpty) {
              print('  Services: ${result.advertisementData.serviceUuids.map((u) => u.toString().substring(0, 4)).join(", ")}');
            }
          }
          
          return hasService || isSamaritan;
        }).toList();
        
        print('📡 Found ${filteredResults.length} BLE devices');
        
        results.addAll(filteredResults);
        yield List.from(results);
      }
    } catch (e) {
      throw Exception("Scan failed: $e");
    } finally {
      await FlutterBluePlus.stopScan();
    }
  }
  
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
  
  Future<void> connectToDevice(String deviceId) async {
    try {
      // Find the device from scan results
      final scanResults = FlutterBluePlus.lastScanResults;
      final scanResult = scanResults.firstWhere(
        (result) => result.device.remoteId.toString() == deviceId,
        orElse: () => throw Exception("Device not found"),
      );
      
      final device = scanResult.device;
      
      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 30),
        autoConnect: false,
      );
      
      print('✅ Device connected, waiting before discovering services...');
      
      // Attendre que la connexion soit stable (réduit à 1 seconde)
      await Future.delayed(const Duration(seconds: 1));
      
      // Discover services
      final services = await device.discoverServices();
      
      // Debug: print all available services
      print("📋 Available services:");
      for (var service in services) {
        print("  - ${service.uuid}");
      }
      
      final targetUuid = _normalizeUuid(SERVICE_UUID);
      
      // Verify the device has the required service
      final service = services.firstWhere(
        (s) => _normalizeUuid(s.uuid.toString()) == targetUuid,
        orElse: () => throw Exception("Required service not found. Expected: $SERVICE_UUID"),
      );
      
      print("✅ Found service: ${service.uuid}");
      
      // Store connected device
      _connectedDevices[deviceId] = device;
      _reconnectAttempts[deviceId] = 0;
      
      // Setup connection state listener for auto-reconnect
      device.connectionState.listen((state) {
        print('🔌 Connection state changed: $state');
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection(deviceId);
        }
      });
      
      print('✅ Connection setup complete');
      
    } catch (e) {
      print('❌ Connection error: $e');
      throw Exception("Connection failed: $e");
    }
  }
  
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      // Cancel any pending reconnect timers
      _reconnectTimers[deviceId]?.cancel();
      _reconnectTimers.remove(deviceId);
      _reconnectAttempts.remove(deviceId);
      
      // Close all streams
      await _vitalSignsControllers[deviceId]?.close();
      _vitalSignsControllers.remove(deviceId);
      
      await _alertControllers[deviceId]?.close();
      _alertControllers.remove(deviceId);
      
      await _statusControllers[deviceId]?.close();
      _statusControllers.remove(deviceId);
      
      // Disconnect device
      final device = _connectedDevices[deviceId];
      if (device != null) {
        await device.disconnect();
        _connectedDevices.remove(deviceId);
      }
    } catch (e) {
      throw Exception("Disconnection failed: $e");
    }
  }
  
  Stream<VitalSigns> getVitalSignsStream(String deviceId) {
    if (_vitalSignsControllers.containsKey(deviceId)) {
      return _vitalSignsControllers[deviceId]!.stream;
    }
    
    final controller = StreamController<VitalSigns>.broadcast();
    _vitalSignsControllers[deviceId] = controller;
    
    // Démarrer le monitoring de manière asynchrone pour ne pas bloquer
    Future.microtask(() => _startVitalSignsMonitoring(deviceId, controller));
    
    return controller.stream;
  }

  Stream<EmergencyAlert> getAlertStream(String deviceId) {
    if (_alertControllers.containsKey(deviceId)) {
      return _alertControllers[deviceId]!.stream;
    }
    
    final controller = StreamController<EmergencyAlert>.broadcast();
    _alertControllers[deviceId] = controller;
    
    // Démarrer le monitoring de manière asynchrone pour ne pas bloquer
    Future.microtask(() => _startAlertMonitoring(deviceId, controller));
    
    return controller.stream;
  }

  Stream<DeviceStatus> getStatusStream(String deviceId) {
    if (_statusControllers.containsKey(deviceId)) {
      return _statusControllers[deviceId]!.stream;
    }
    
    final controller = StreamController<DeviceStatus>.broadcast();
    _statusControllers[deviceId] = controller;
    
    // Démarrer le monitoring de manière asynchrone pour ne pas bloquer
    Future.microtask(() => _startStatusMonitoring(deviceId, controller));
    
    return controller.stream;
  }
  
  Future<void> _startVitalSignsMonitoring(
    String deviceId,
    StreamController<VitalSigns> controller,
  ) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw Exception("Device not connected");
      }
      
      print('🔍 Starting vital signs monitoring for $deviceId');
      
      // Attendre que la connexion soit stable
      await Future.delayed(const Duration(seconds: 1));
      
      // Vérifier que le device est toujours connecté
      final connectionState = await device.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        throw Exception("Device disconnected before monitoring could start");
      }
      
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => _normalizeUuid(s.uuid.toString()) == _normalizeUuid(SERVICE_UUID),
      );
      
      final characteristic = service.characteristics.firstWhere(
        (c) => _normalizeUuid(c.uuid.toString()) == _normalizeUuid(VITAL_SIGNS_CHARACTERISTIC_UUID),
      );
      
      print('📡 Found vital signs characteristic');
      
      // Vérifier si les notifications sont supportées
      if (!characteristic.properties.notify) {
        throw Exception("Characteristic does not support notifications");
      }
      
      // Enable notifications avec retry
      int retries = 3;
      while (retries > 0) {
        try {
          await characteristic.setNotifyValue(true);
          print('✅ Vital signs notifications enabled');
          break;
        } catch (e) {
          retries--;
          print('⚠️ Failed to enable notifications, retries left: $retries');
          if (retries == 0) rethrow;
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      
      // Listen to characteristic updates
      characteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            try {
              final vitalSigns = _parseVitalSigns(value);
              controller.add(vitalSigns);
            } catch (e) {
              print('⚠️ Error parsing vital signs: $e');
            }
          }
        },
        onError: (error) {
          print('⚠️ Vital signs stream error: $error');
          controller.addError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ Failed to start vital signs monitoring: $e');
      controller.addError(Exception("Failed to start monitoring: $e"));
    }
  }

  Future<void> _startAlertMonitoring(
    String deviceId,
    StreamController<EmergencyAlert> controller,
  ) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw Exception("Device not connected");
      }
      
      print('🔍 Starting alert monitoring for $deviceId');
      
      // Attendre que la connexion soit stable et que vital signs soit activé
      await Future.delayed(const Duration(seconds: 2));
      
      // Vérifier que le device est toujours connecté
      final connectionState = await device.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        throw Exception("Device disconnected before monitoring could start");
      }
      
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => _normalizeUuid(s.uuid.toString()) == _normalizeUuid(SERVICE_UUID),
      );
      
      final characteristic = service.characteristics.firstWhere(
        (c) => _normalizeUuid(c.uuid.toString()) == _normalizeUuid(ALERT_CHARACTERISTIC_UUID),
      );
      
      print('📡 Found alert characteristic');
      
      // Vérifier si les notifications sont supportées
      if (!characteristic.properties.notify) {
        throw Exception("Characteristic does not support notifications");
      }
      
      // Enable notifications avec retry
      int retries = 3;
      while (retries > 0) {
        try {
          await characteristic.setNotifyValue(true);
          print('✅ Alert notifications enabled');
          break;
        } catch (e) {
          retries--;
          print('⚠️ Failed to enable alert notifications, retries left: $retries');
          if (retries == 0) rethrow;
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      
      // Listen to characteristic updates
      characteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            try {
              final alert = _parseAlert(value, deviceId);
              controller.add(alert);
            } catch (e) {
              print('⚠️ Error parsing alert: $e');
            }
          }
        },
        onError: (error) {
          print('⚠️ Alert stream error: $error');
          controller.addError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ Failed to start alert monitoring: $e');
      controller.addError(Exception("Failed to start alert monitoring: $e"));
    }
  }

  Future<void> _startStatusMonitoring(
    String deviceId,
    StreamController<DeviceStatus> controller,
  ) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw Exception("Device not connected");
      }
      
      print('🔍 Starting status monitoring for $deviceId');
      
      // Attendre que les autres notifications soient activées
      await Future.delayed(const Duration(seconds: 3));
      
      // Vérifier que le device est toujours connecté
      final connectionState = await device.connectionState.first;
      if (connectionState != BluetoothConnectionState.connected) {
        throw Exception("Device disconnected before monitoring could start");
      }
      
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => _normalizeUuid(s.uuid.toString()) == _normalizeUuid(SERVICE_UUID),
      );
      
      final characteristic = service.characteristics.firstWhere(
        (c) => _normalizeUuid(c.uuid.toString()) == _normalizeUuid(STATUS_CHARACTERISTIC_UUID),
      );
      
      print('📡 Found status characteristic');
      
      // Vérifier si les notifications sont supportées
      if (!characteristic.properties.notify) {
        throw Exception("Characteristic does not support notifications");
      }
      
      // Enable notifications avec retry
      int retries = 3;
      while (retries > 0) {
        try {
          await characteristic.setNotifyValue(true);
          print('✅ Status notifications enabled');
          break;
        } catch (e) {
          retries--;
          print('⚠️ Failed to enable status notifications, retries left: $retries');
          if (retries == 0) rethrow;
          await Future.delayed(const Duration(milliseconds: 1000));
        }
      }
      
      // Listen to characteristic updates
      characteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            try {
              final status = DeviceStatus.fromBytes(value);
              controller.add(status);
            } catch (e) {
              print('⚠️ Error parsing status: $e');
            }
          }
        },
        onError: (error) {
          print('⚠️ Status stream error: $error');
          controller.addError(error);
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ Failed to start status monitoring: $e');
      controller.addError(Exception("Failed to start status monitoring: $e"));
    }
  }

  EmergencyAlert _parseAlert(List<int> data, String deviceId) {
    // Protocol: AlertType(1) + DeviceID(16) + VitalSigns(12) + Timestamp(8) + Sensors(1)
    if (data.length < 38) {
      throw Exception("Invalid alert data length: ${data.length}");
    }
    
    final bytes = Uint8List.fromList(data);
    final byteData = ByteData.sublistView(bytes);
    
    // Skip alert type (byte 0) and device ID (bytes 1-16)
    final temperature = byteData.getFloat32(17, Endian.little);
    final heartRate = byteData.getInt32(21, Endian.little);
    final oxygenSaturation = byteData.getInt32(25, Endian.little);
    final timestamp = byteData.getUint64(29, Endian.little);
    final sensorStatus = SensorStatus.fromByte(data[37]);
    
    final vitalSigns = VitalSigns(
      temperature: temperature,
      heartRate: heartRate,
      oxygenSaturation: oxygenSaturation,
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()),
      sensorStatus: sensorStatus,
    );
    
    return EmergencyAlert(
      alertId: DateTime.now().millisecondsSinceEpoch.toString(),
      victimDeviceId: deviceId,
      vitalSigns: vitalSigns,
      status: AlertStatus.active,
      receivedAt: DateTime.now(),
    );
  }
  
  VitalSigns _parseVitalSigns(List<int> data) {
    // Protocol from ESP32 (27 bytes):
    // [temperature(4bytes float)][heartRate(4bytes int)][oxygenSaturation(4bytes int)]
    // [timestamp(4bytes unsigned long)][fallDetected(1byte)][suddenMovement(1byte)]
    // [ambientTemp(4bytes float)][humidity(4bytes float)][sensorStatus(1byte)]
    
    if (data.length < 18) {
      throw Exception("Invalid data length: ${data.length}");
    }
    
    final bytes = Uint8List.fromList(data);
    final byteData = ByteData.sublistView(bytes);
    
    final temperature = byteData.getFloat32(0, Endian.little);
    final heartRate = byteData.getInt32(4, Endian.little);
    final oxygenSaturation = byteData.getInt32(8, Endian.little);
    // Skip timestamp (bytes 12-15)
    final fallDetected = data[16] == 1;
    final suddenMovement = data[17] == 1;
    
    // Extended data (optional - for new firmware)
    double? ambientTemperature;
    double? humidity;
    SensorStatus sensorStatus = const SensorStatus();
    
    if (data.length >= 27) {
      ambientTemperature = byteData.getFloat32(18, Endian.little);
      humidity = byteData.getFloat32(22, Endian.little);
      sensorStatus = SensorStatus.fromByte(data[26]);
    }
    
    return VitalSigns(
      temperature: temperature,
      heartRate: heartRate,
      oxygenSaturation: oxygenSaturation,
      timestamp: DateTime.now(),
      fallDetected: fallDetected,
      suddenMovement: suddenMovement,
      ambientTemperature: ambientTemperature,
      humidity: humidity,
      sensorStatus: sensorStatus,
    );
  }
  
  Future<void> sendCommand(String deviceId, DeviceCommand command) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw Exception("Device not connected");
      }
      
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => _normalizeUuid(s.uuid.toString()) == _normalizeUuid(SERVICE_UUID),
      );
      
      final characteristic = service.characteristics.firstWhere(
        (c) => _normalizeUuid(c.uuid.toString()) == _normalizeUuid(COMMAND_CHARACTERISTIC_UUID),
      );
      
      final commandData = _encodeCommand(command);
      await characteristic.write(commandData);
    } catch (e) {
      throw Exception("Failed to send command: $e");
    }
  }
  
  List<int> _encodeCommand(DeviceCommand command) {
    // Enhanced command encoding for intervention mode
    final bytes = <int>[];
    
    switch (command.type) {
      case DeviceCommandType.takeCharge:
        bytes.addAll('TAKE_CHARGE'.codeUnits);
        break;
      case DeviceCommandType.endIntervention:
        bytes.addAll('END_INTERVENTION'.codeUnits);
        break;
      case DeviceCommandType.acknowledgeAlert:
        bytes.addAll('ACKNOWLEDGE_ALERT'.codeUnits);
        break;
      case DeviceCommandType.cancelAlert:
        bytes.addAll('CANCEL_ALERT'.codeUnits);
        break;
      case DeviceCommandType.requestStatus:
        bytes.addAll('STATUS'.codeUnits);
        break;
      case DeviceCommandType.reset:
        bytes.addAll('RESET'.codeUnits);
        break;
      case DeviceCommandType.calibrateTemperature:
        final offset = command.payload.isNotEmpty 
            ? String.fromCharCodes(command.payload)
            : '6.5';
        bytes.addAll('CALIBRATE_TEMP:$offset'.codeUnits);
        break;
      default:
        // Legacy encoding
        bytes.add(command.type.index);
        bytes.addAll(command.payload);
    }
    
    return bytes;
  }

  // Convenience methods for intervention commands
  Future<void> takeCharge(String deviceId) async {
    await sendCommand(
      deviceId,
      DeviceCommand(
        type: DeviceCommandType.takeCharge,
        payload: Uint8List(0),
      ),
    );
  }

  Future<void> endIntervention(String deviceId) async {
    await sendCommand(
      deviceId,
      DeviceCommand(
        type: DeviceCommandType.endIntervention,
        payload: Uint8List(0),
      ),
    );
  }

  Future<void> acknowledgeAlert(String deviceId) async {
    await sendCommand(
      deviceId,
      DeviceCommand(
        type: DeviceCommandType.acknowledgeAlert,
        payload: Uint8List(0),
      ),
    );
  }

  Future<void> requestStatus(String deviceId) async {
    await sendCommand(
      deviceId,
      DeviceCommand(
        type: DeviceCommandType.requestStatus,
        payload: Uint8List(0),
      ),
    );
  }
  
  Future<void> updateFirmware(String deviceId, Uint8List firmwareData) async {
    try {
      final device = _connectedDevices[deviceId];
      if (device == null) {
        throw Exception("Device not connected");
      }
      
      // Firmware update would typically involve:
      // 1. Sending firmware update command
      // 2. Chunking firmware data
      // 3. Sending chunks with verification
      // 4. Waiting for device to reboot
      
      // Simplified implementation - send update command
      await sendCommand(
        deviceId,
        DeviceCommand(
          type: DeviceCommandType.updateFirmware,
          payload: firmwareData,
        ),
      );
    } catch (e) {
      throw Exception("Firmware update failed: $e");
    }
  }
  
  void _handleDisconnection(String deviceId) {
    final attempts = _reconnectAttempts[deviceId] ?? 0;
    
    if (attempts < MAX_RECONNECT_ATTEMPTS) {
      _reconnectAttempts[deviceId] = attempts + 1;
      
      // Schedule reconnection attempt
      _reconnectTimers[deviceId] = Timer(RECONNECT_DELAY, () async {
        try {
          await connectToDevice(deviceId);
          _reconnectAttempts[deviceId] = 0;
        } catch (e) {
          // Reconnection failed, will try again if under max attempts
          _handleDisconnection(deviceId);
        }
      });
    } else {
      // Max reconnection attempts reached
      _vitalSignsControllers[deviceId]?.addError(
        Exception("Connection lost after $MAX_RECONNECT_ATTEMPTS reconnection attempts"),
      );
    }
  }
  
  bool isDeviceConnected(String deviceId) {
    return _connectedDevices.containsKey(deviceId);
  }
  
  Future<void> dispose() async {
    // Cancel all reconnect timers
    for (final timer in _reconnectTimers.values) {
      timer?.cancel();
    }
    _reconnectTimers.clear();
    
    // Close all streams
    for (final controller in _vitalSignsControllers.values) {
      await controller.close();
    }
    _vitalSignsControllers.clear();
    
    for (final controller in _alertControllers.values) {
      await controller.close();
    }
    _alertControllers.clear();
    
    for (final controller in _statusControllers.values) {
      await controller.close();
    }
    _statusControllers.clear();
    
    // Disconnect all devices
    for (final deviceId in _connectedDevices.keys.toList()) {
      await disconnectFromDevice(deviceId);
    }
  }
}
