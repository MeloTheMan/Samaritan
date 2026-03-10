import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/device_command.dart';

@lazySingleton
class BluetoothService {
  static const String SERVICE_UUID = "0000180d-0000-1000-8000-00805f9b34fb";
  static const String VITAL_SIGNS_CHARACTERISTIC_UUID = "00002a37-0000-1000-8000-00805f9b34fb";
  static const String COMMAND_CHARACTERISTIC_UUID = "00002a38-0000-1000-8000-00805f9b34fb";
  
  static const int MAX_RECONNECT_ATTEMPTS = 3;
  static const Duration RECONNECT_DELAY = Duration(seconds: 5);
  
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, StreamController<VitalSigns>> _vitalSignsControllers = {};
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
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection(deviceId);
        }
      });
      
    } catch (e) {
      throw Exception("Connection failed: $e");
    }
  }
  
  Future<void> disconnectFromDevice(String deviceId) async {
    try {
      // Cancel any pending reconnect timers
      _reconnectTimers[deviceId]?.cancel();
      _reconnectTimers.remove(deviceId);
      _reconnectAttempts.remove(deviceId);
      
      // Close vital signs stream
      await _vitalSignsControllers[deviceId]?.close();
      _vitalSignsControllers.remove(deviceId);
      
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
    
    _startVitalSignsMonitoring(deviceId, controller);
    
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
      
      final services = await device.discoverServices();
      final service = services.firstWhere(
        (s) => _normalizeUuid(s.uuid.toString()) == _normalizeUuid(SERVICE_UUID),
      );
      
      final characteristic = service.characteristics.firstWhere(
        (c) => _normalizeUuid(c.uuid.toString()) == _normalizeUuid(VITAL_SIGNS_CHARACTERISTIC_UUID),
      );
      
      // Enable notifications
      await characteristic.setNotifyValue(true);
      
      // Listen to characteristic updates
      characteristic.lastValueStream.listen(
        (value) {
          if (value.isNotEmpty) {
            final vitalSigns = _parseVitalSigns(value);
            controller.add(vitalSigns);
          }
        },
        onError: (error) {
          controller.addError(error);
        },
      );
    } catch (e) {
      controller.addError(Exception("Failed to start monitoring: $e"));
    }
  }
  
  VitalSigns _parseVitalSigns(List<int> data) {
    // Protocol from ESP32: 
    // [temperature(4bytes float)][heartRate(4bytes int)][oxygenSaturation(4bytes int)]
    // [timestamp(4bytes unsigned long)][fallDetected(1byte)][suddenMovement(1byte)]
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
    
    return VitalSigns(
      temperature: temperature,
      heartRate: heartRate,
      oxygenSaturation: oxygenSaturation,
      timestamp: DateTime.now(),
      fallDetected: fallDetected,
      suddenMovement: suddenMovement,
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
    // Simple command encoding: [commandType(1byte)][payload(variable)]
    final bytes = <int>[];
    bytes.add(command.type.index);
    bytes.addAll(command.payload);
    return bytes;
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
    
    // Disconnect all devices
    for (final deviceId in _connectedDevices.keys.toList()) {
      await disconnectFromDevice(deviceId);
    }
  }
}
