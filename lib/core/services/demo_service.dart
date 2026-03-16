import 'dart:async';
import 'dart:math';
import 'package:injectable/injectable.dart';
import '../../features/device/domain/entities/vital_signs.dart';
import '../../features/device/domain/entities/wearable_device.dart';
import '../../features/alert/domain/entities/emergency_alert.dart';

/// Service pour générer des données de démonstration
@singleton
class DemoService {
  final Random _random = Random();
  Timer? _vitalSignsTimer;
  final StreamController<VitalSigns> _vitalSignsController =
      StreamController<VitalSigns>.broadcast();

  /// Génère un bracelet de démonstration
  WearableDevice generateDemoDevice() {
    return WearableDevice(
      id: 'DEMO_DEVICE_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Bracelet Démo',
      status: ConnectionStatus.connected,
      batteryLevel: 85,
      signalStrength: -45, // Excellent signal
      firmwareVersion: '1.0.0-demo',
      lastConnected: DateTime.now(),
    );
  }

  /// Génère des signes vitaux de démonstration (normaux)
  VitalSigns generateNormalVitalSigns() {
    return VitalSigns(
      temperature: 36.5 + (_random.nextDouble() * 1.0), // 36.5-37.5°C
      heartRate: 70 + _random.nextInt(20), // 70-90 BPM
      oxygenSaturation: 96 + _random.nextInt(4), // 96-99%
      timestamp: DateTime.now(),
      fallDetected: false,
      suddenMovement: false,
      sensorStatus: const SensorStatus(
        max30102Available: true,
        mpu6050Available: true,
        dht11Available: true,
      ),
    );
  }

  /// Génère des signes vitaux de démonstration (critiques)
  VitalSigns generateCriticalVitalSigns() {
    final scenarios = [
      // Hypothermie + bradycardie
      VitalSigns(
        temperature: 34.0 + (_random.nextDouble() * 1.0),
        heartRate: 35 + _random.nextInt(10),
        oxygenSaturation: 92 + _random.nextInt(4),
        timestamp: DateTime.now(),
        fallDetected: false,
        suddenMovement: false,
        sensorStatus: const SensorStatus(
          max30102Available: true,
          mpu6050Available: true,
          dht11Available: true,
        ),
      ),
      // Hyperthermie + tachycardie
      VitalSigns(
        temperature: 40.0 + (_random.nextDouble() * 1.5),
        heartRate: 150 + _random.nextInt(20),
        oxygenSaturation: 88 + _random.nextInt(5),
        timestamp: DateTime.now(),
        fallDetected: false,
        suddenMovement: true,
        sensorStatus: const SensorStatus(
          max30102Available: true,
          mpu6050Available: true,
          dht11Available: true,
        ),
      ),
      // Chute + hypoxie
      VitalSigns(
        temperature: 36.5 + (_random.nextDouble() * 0.5),
        heartRate: 110 + _random.nextInt(20),
        oxygenSaturation: 82 + _random.nextInt(5),
        timestamp: DateTime.now(),
        fallDetected: true,
        suddenMovement: false,
        sensorStatus: const SensorStatus(
          max30102Available: true,
          mpu6050Available: true,
          dht11Available: true,
        ),
      ),
    ];

    return scenarios[_random.nextInt(scenarios.length)];
  }

  /// Génère une alerte d'urgence de démonstration
  EmergencyAlert generateDemoAlert() {
    final vitalSigns = generateCriticalVitalSigns();
    
    return EmergencyAlert(
      alertId: 'DEMO_ALERT_${DateTime.now().millisecondsSinceEpoch}',
      victimDeviceId: 'DEMO_VICTIM_${_random.nextInt(1000)}',
      vitalSigns: vitalSigns,
      status: AlertStatus.active,
      receivedAt: DateTime.now(),
      distance: 50.0 + (_random.nextDouble() * 200.0), // 50-250m
      estimatedLocation: null,
    );
  }

  /// Démarre un stream de signes vitaux simulés
  Stream<VitalSigns> startVitalSignsStream({bool critical = false}) {
    _stopVitalSignsStream();

    // Émettre immédiatement
    _vitalSignsController.add(
      critical ? generateCriticalVitalSigns() : generateNormalVitalSigns(),
    );

    // Puis émettre toutes les 2 secondes
    _vitalSignsTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        if (!_vitalSignsController.isClosed) {
          _vitalSignsController.add(
            critical ? generateCriticalVitalSigns() : generateNormalVitalSigns(),
          );
        }
      },
    );

    return _vitalSignsController.stream;
  }

  /// Arrête le stream de signes vitaux
  void _stopVitalSignsStream() {
    _vitalSignsTimer?.cancel();
    _vitalSignsTimer = null;
  }

  /// Génère un historique de signes vitaux
  List<VitalSigns> generateVitalSignsHistory({
    required int count,
    required Duration interval,
    bool critical = false,
  }) {
    final history = <VitalSigns>[];
    final now = DateTime.now();

    for (int i = count - 1; i >= 0; i--) {
      final timestamp = now.subtract(interval * i);
      final vitalSigns = critical
          ? generateCriticalVitalSigns()
          : generateNormalVitalSigns();

      history.add(vitalSigns.copyWith(timestamp: timestamp));
    }

    return history;
  }

  void dispose() {
    _stopVitalSignsStream();
    _vitalSignsController.close();
  }
}
