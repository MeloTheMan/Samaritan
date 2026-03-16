import 'dart:async';
import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../device/domain/entities/vital_signs.dart';
import '../../domain/entities/emergency_alert.dart';

@injectable
class AlertListenerService {
  // UUID pour le service d'alerte d'urgence
  static const String ALERT_SERVICE_UUID = '0000180d-0000-1000-8000-00805f9b34fb';
  static const String ALERT_CHARACTERISTIC_UUID = '00002a38-0000-1000-8000-00805f9b34fb';
  
  StreamController<EmergencyAlert>? _alertController;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final Map<String, DateTime> _processedAlerts = {};
  final Duration _alertCooldown = const Duration(seconds: 30);

  /// Démarre l'écoute des alertes BLE en arrière-plan
  Stream<EmergencyAlert> startListening() {
    _alertController = StreamController<EmergencyAlert>.broadcast();
    
    print('🔍 Starting BLE alert listener...');
    
    // Démarrer le scan BLE
    _startScanning();

    return _alertController!.stream;
  }

  Future<void> _startScanning() async {
    try {
      // Vérifier si le Bluetooth est disponible
      if (await FlutterBluePlus.isSupported == false) {
        print('❌ Bluetooth not supported on this device');
        _alertController?.addError('Bluetooth not supported');
        return;
      }

      // Vérifier si le Bluetooth est activé
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        print('❌ Bluetooth is OFF');
        _alertController?.addError('Bluetooth is OFF');
        return;
      }

      print('✓ Bluetooth is ready');
      
      // Scanner en continu pour les appareils
      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) {
          if (results.isNotEmpty) {
            print('📡 Found ${results.length} BLE devices');
          }
          for (ScanResult result in results) {
            _checkDeviceForAlert(result);
          }
        },
        onError: (error) {
          print('❌ Scan error: $error');
          _alertController?.addError(error);
        },
      );

      // Démarrer le scan avec un timeout long (4 secondes) et le relancer en boucle
      _continuousScanning();
      
      print('✓ BLE continuous scan started');
    } catch (e) {
      print('❌ Error starting scan: $e');
      _alertController?.addError(e);
    }
  }

  /// Scanner en continu avec des cycles de 4 secondes
  Future<void> _continuousScanning() async {
    while (_alertController != null && !_alertController!.isClosed) {
      try {
        print('🔄 Starting scan cycle...');
        await FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 4),
          androidUsesFineLocation: true,
        );
        
        // Attendre la fin du scan
        await Future.delayed(const Duration(seconds: 4));
        
        // Petite pause avant le prochain cycle
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('⚠️ Scan cycle error: $e');
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Arrête l'écoute des alertes
  Future<void> stopListening() async {
    print('🛑 Stopping BLE alert listener...');
    
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print('Error stopping scan: $e');
    }
    
    await _scanSubscription?.cancel();
    await _alertController?.close();
    _scanSubscription = null;
    _alertController = null;
    _processedAlerts.clear();
    
    print('✓ Alert listener stopped');
  }

  /// Vérifie si un appareil émet une alerte
  Future<void> _checkDeviceForAlert(ScanResult result) async {
    try {
      final device = result.device;
      final deviceId = device.remoteId.toString();
      final deviceName = result.advertisementData.advName;
      
      // DEBUG: Log tous les devices
      print('🔍 Checking device: $deviceName ($deviceId)');
      
      // Vérifier si l'appareil a le service d'alerte
      final serviceUuids = result.advertisementData.serviceUuids;
      
      // DEBUG: Log les services
      if (serviceUuids.isNotEmpty) {
        print('  Services: ${serviceUuids.map((u) => u.toString()).join(", ")}');
      } else {
        print('  No services advertised');
      }
      
      final hasAlertService = serviceUuids.any((uuid) {
        final uuidStr = uuid.toString().toLowerCase();
        return uuidStr == '180d' || 
               uuidStr == ALERT_SERVICE_UUID.toLowerCase() ||
               uuidStr.contains('180d');
      });

      if (!hasAlertService) {
        return; // Pas un bracelet Samaritan
      }
      
      print('✅ Samaritan device found: $deviceName');

      // Lire les manufacturer data pour détecter une alerte
      final manufacturerDataMap = result.advertisementData.manufacturerData;
      
      // DEBUG: Log manufacturer data
      print('  Manufacturer data map: $manufacturerDataMap');
      
      if (manufacturerDataMap.isNotEmpty) {
        // Extraire les données du premier manufacturer (généralement la clé est le company ID)
        final manufacturerData = manufacturerDataMap.values.first;
        
        print('  Manufacturer data bytes: $manufacturerData');
        
        // Format: AlertFlag(1) + HeartRate(1) + SpO2(1) + Temp(1)
        if (manufacturerData.length >= 4) {
          final int alertFlag = manufacturerData[0];
          final int heartRate = manufacturerData[1];
          final int spo2 = manufacturerData[2];
          final int temp = manufacturerData[3];
          
          print('  Alert Flag: 0x${alertFlag.toRadixString(16).padLeft(2, '0')}');
          print('  HR: $heartRate, SpO2: $spo2%, Temp: $temp°C');
          
          // Vérifier si une alerte est active
          if (alertFlag == 0xFF) {
            print('🚨 ALERT detected from $deviceName ($deviceId)');
            
            // Vérifier le cooldown pour éviter les doublons
            if (_processedAlerts.containsKey(deviceId)) {
              final lastAlert = _processedAlerts[deviceId]!;
              if (DateTime.now().difference(lastAlert) < _alertCooldown) {
                print('  ⏭️ Skipping (cooldown)');
                return; // Trop tôt pour une nouvelle alerte
              }
            }
            
            // Créer une alerte à partir des manufacturer data
            final alert = _createAlertFromAdvertisement(
              deviceId,
              heartRate,
              spo2,
              temp.toDouble(),
            );
            
            // Marquer comme traité
            _processedAlerts[deviceId] = DateTime.now();
            
            // Émettre l'alerte
            _alertController?.add(alert);
            
            print('✅ Alert emitted: ${alert.alertId}');
          } else {
            print('  ℹ️ No alert (flag: 0x${alertFlag.toRadixString(16).padLeft(2, '0')})');
          }
        } else {
          print('  ⚠️ Manufacturer data too short: ${manufacturerData.length} bytes');
        }
      } else {
        print('  ⚠️ No manufacturer data');
      }
      
    } catch (e, stackTrace) {
      print('❌ Error checking device: $e');
      print('Stack trace: $stackTrace');
    }
  }
  
  /// Crée une alerte à partir des données d'advertisement
  EmergencyAlert _createAlertFromAdvertisement(
    String deviceId,
    int heartRate,
    int spo2,
    double temperature,
  ) {
    final vitalSigns = VitalSigns(
      temperature: temperature,
      heartRate: heartRate,
      oxygenSaturation: spo2,
      timestamp: DateTime.now(),
      sensorStatus: const SensorStatus(
        max30102Available: true,
        mpu6050Available: false,
        dht11Available: false,
      ),
    );
    
    return EmergencyAlert(
      alertId: '${deviceId}_${DateTime.now().millisecondsSinceEpoch}',
      victimDeviceId: deviceId,
      vitalSigns: vitalSigns,
      status: AlertStatus.active,
      receivedAt: DateTime.now(),
    );
  }

  /// Parse les données brutes d'une alerte BLE
  /// Format: AlertType(1) + DeviceID(16) + VitalSigns(12) + Timestamp(8)
  EmergencyAlert parseAlertData(Uint8List data, String deviceId) {
    print('📊 Parsing alert data: ${data.length} bytes');
    
    if (data.length < 37) {
      print('⚠️ Alert data too short, using minimal format');
      // Format minimal: juste les signes vitaux
      if (data.length >= 12) {
        final vitalSigns = _parseVitalSigns(data.sublist(0, 12));
        return EmergencyAlert(
          alertId: '${deviceId}_${DateTime.now().millisecondsSinceEpoch}',
          victimDeviceId: deviceId,
          vitalSigns: vitalSigns,
          status: AlertStatus.active,
          receivedAt: DateTime.now(),
        );
      }
      throw FormatException('Invalid alert data length: ${data.length}');
    }

    int index = 0;
    
    // Parse alert type (1 byte)
    final alertType = data[index];
    index += 1;
    print('  Alert type: $alertType');
    
    // Parse device ID (16 bytes)
    final deviceIdBytes = data.sublist(index, index + 16);
    final victimDeviceId = _bytesToUuid(deviceIdBytes);
    index += 16;
    print('  Victim device: $victimDeviceId');
    
    // Parse vital signs (12 bytes)
    final vitalSignsBytes = data.sublist(index, index + 12);
    final vitalSigns = _parseVitalSigns(vitalSignsBytes);
    index += 12;
    print('  Vital signs: T=${vitalSigns.temperature}°C HR=${vitalSigns.heartRate} SpO2=${vitalSigns.oxygenSaturation}%');
    
    // Parse timestamp (8 bytes)
    final timestampBytes = data.sublist(index, index + 8);
    final timestamp = _parseTimestamp(timestampBytes);
    print('  Timestamp: $timestamp');

    return EmergencyAlert(
      alertId: '${victimDeviceId}_${timestamp.millisecondsSinceEpoch}',
      victimDeviceId: victimDeviceId,
      vitalSigns: vitalSigns,
      status: AlertStatus.active,
      receivedAt: DateTime.now(),
    );
  }

  String _bytesToUuid(Uint8List bytes) {
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  VitalSigns _parseVitalSigns(Uint8List bytes) {
    final buffer = ByteData.sublistView(bytes);
    
    final temperature = buffer.getFloat32(0, Endian.little);
    final heartRate = buffer.getInt32(4, Endian.little);
    final oxygenSaturation = buffer.getInt32(8, Endian.little);
    
    return VitalSigns(
      temperature: temperature,
      heartRate: heartRate,
      oxygenSaturation: oxygenSaturation,
      timestamp: DateTime.now(),
      fallDetected: false,
      suddenMovement: false,
    );
  }

  DateTime _parseTimestamp(Uint8List bytes) {
    final buffer = ByteData.sublistView(bytes);
    final milliseconds = buffer.getInt64(0, Endian.little);
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  bool get isListening => _alertController != null && !_alertController!.isClosed;
}
