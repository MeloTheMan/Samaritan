import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/vital_signs.dart';
import '../../domain/entities/wearable_device.dart';
import '../widgets/vital_sign_card.dart';
import '../../../../core/services/demo_service.dart';
import '../../../../core/di/injection.dart';

/// Dashboard de santé en mode démo
class DemoHealthDashboardScreen extends StatefulWidget {
  final WearableDevice demoDevice;

  const DemoHealthDashboardScreen({
    super.key,
    required this.demoDevice,
  });

  @override
  State<DemoHealthDashboardScreen> createState() =>
      _DemoHealthDashboardScreenState();
}

class _DemoHealthDashboardScreenState extends State<DemoHealthDashboardScreen> {
  final DemoService _demoService = getIt<DemoService>();
  VitalSigns? _currentVitalSigns;
  final List<VitalSigns> _history = [];
  StreamSubscription<VitalSigns>? _subscription;

  @override
  void initState() {
    super.initState();
    _startDemoStream();
  }

  void _startDemoStream() {
    _subscription = _demoService.startVitalSignsStream().listen((vitalSigns) {
      setState(() {
        _currentVitalSigns = vitalSigns;
        _history.add(vitalSigns);
        // Garder seulement les 50 dernières mesures
        if (_history.length > 50) {
          _history.removeAt(0);
        }
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Santé (Démo)'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showDemoInfo(context);
            },
          ),
        ],
      ),
      body: _currentVitalSigns == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // Simuler un rafraîchissement
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bandeau mode démo
                    _buildDemoBanner(),
                    const SizedBox(height: 16),

                    // Status card
                    _buildStatusCard(_currentVitalSigns!),
                    const SizedBox(height: 16),

                    // Sensor status
                    _buildSensorStatusCard(_currentVitalSigns!.sensorStatus),
                    const SizedBox(height: 24),

                    // Vital signs
                    const Text(
                      'Signes Vitaux Corporels',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: VitalSignCard(
                            icon: Icons.thermostat,
                            label: 'Température',
                            value: '${_currentVitalSigns!.temperature.toStringAsFixed(1)}°C',
                            color: Colors.red,
                            isNormal: _currentVitalSigns!.temperature >= 36.0 &&
                                _currentVitalSigns!.temperature <= 38.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: VitalSignCard(
                            icon: Icons.favorite,
                            label: 'Pouls',
                            value: '${_currentVitalSigns!.heartRate} BPM',
                            color: Colors.pink,
                            isNormal: _currentVitalSigns!.heartRate >= 60 &&
                                _currentVitalSigns!.heartRate <= 100,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    VitalSignCard(
                      icon: Icons.air,
                      label: 'Saturation en Oxygène (SpO2)',
                      value: '${_currentVitalSigns!.oxygenSaturation}%',
                      color: Colors.blue,
                      isNormal: _currentVitalSigns!.oxygenSaturation >= 95,
                    ),
                    const SizedBox(height: 24),

                    // Movement detection
                    if (_currentVitalSigns!.fallDetected ||
                        _currentVitalSigns!.suddenMovement) ...[
                      const Text(
                        'Détection de Mouvement',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_currentVitalSigns!.fallDetected)
                        _buildAlertCard(
                          'Chute Détectée',
                          'Une chute a été détectée par l\'accéléromètre',
                          Icons.warning,
                          Colors.red,
                        ),
                      if (_currentVitalSigns!.suddenMovement)
                        _buildAlertCard(
                          'Mouvement Brusque',
                          'Un mouvement brusque a été détecté',
                          Icons.info,
                          Colors.orange,
                        ),
                      const SizedBox(height: 24),
                    ],

                    // Device info
                    const Text(
                      'Informations du Bracelet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildDeviceInfoCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDemoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: Colors.orange.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mode Démonstration',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
                Text(
                  'Données simulées pour test',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(VitalSigns vitalSigns) {
    final isHealthy = vitalSigns.temperature >= 36.0 &&
        vitalSigns.temperature <= 38.0 &&
        vitalSigns.heartRate >= 60 &&
        vitalSigns.heartRate <= 100 &&
        vitalSigns.oxygenSaturation >= 95 &&
        !vitalSigns.fallDetected;

    return Card(
      color: isHealthy ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.warning,
              color: isHealthy ? Colors.green : Colors.red,
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHealthy ? 'État de Santé Normal' : 'Attention Requise',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isHealthy ? Colors.green.shade900 : Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHealthy
                        ? 'Tous les signes vitaux sont normaux'
                        : 'Certains signes vitaux nécessitent une attention',
                    style: TextStyle(
                      color: isHealthy ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusCard(SensorStatus status) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'État des Capteurs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildSensorStatusRow('MAX30102 (HR/SpO2/Temp)', status.max30102Available),
            _buildSensorStatusRow('MPU6050 (Accéléromètre)', status.mpu6050Available),
            _buildSensorStatusRow('DHT11 (Température ambiante)', status.dht11Available),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusRow(String name, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.cancel,
            color: available ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }

  Widget _buildAlertCard(String title, String message, IconData icon, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(message),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow('Nom', widget.demoDevice.name),
            _buildInfoRow('ID', widget.demoDevice.id.substring(0, 20) + '...'),
            _buildInfoRow('Batterie', '${widget.demoDevice.batteryLevel}%'),
            _buildInfoRow('Signal', widget.demoDevice.signalQuality),
            _buildInfoRow('Firmware', widget.demoDevice.firmwareVersion),
            _buildInfoRow('État', widget.demoDevice.isConnected ? 'Connecté' : 'Déconnecté'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showDemoInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.science, color: Colors.orange),
            SizedBox(width: 8),
            Text('Mode Démonstration'),
          ],
        ),
        content: const Text(
          'Vous utilisez actuellement l\'application en mode démonstration. '
          'Les données affichées sont simulées et ne proviennent pas d\'un bracelet réel.\n\n'
          'Ce mode vous permet de découvrir toutes les fonctionnalités de l\'application '
          'sans avoir besoin d\'un bracelet Samaritan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }
}
