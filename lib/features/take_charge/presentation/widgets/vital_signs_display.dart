import 'package:flutter/material.dart';
import '../../../device/domain/entities/vital_signs.dart';

class VitalSignsDisplay extends StatelessWidget {
  final VitalSigns vitalSigns;
  final bool showAmbientData;
  final bool showSensorStatus;

  const VitalSignsDisplay({
    super.key,
    required this.vitalSigns,
    this.showAmbientData = false,
    this.showSensorStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final sensorStatus = vitalSigns.sensorStatus;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sensor status indicator (if requested)
            if (showSensorStatus) ...[
              _buildSensorStatusRow(sensorStatus),
              const SizedBox(height: 16),
            ],
            
            // Main vital signs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalSign(
                  context,
                  icon: Icons.thermostat,
                  label: 'Température',
                  value: '${vitalSigns.temperature.toStringAsFixed(1)}°C',
                  isNormal: vitalSigns.temperature >= 36.0 && vitalSigns.temperature <= 38.0,
                  isAvailable: sensorStatus.max30102Available,
                ),
                _buildVitalSign(
                  context,
                  icon: Icons.favorite,
                  label: 'Pouls',
                  value: '${vitalSigns.heartRate} BPM',
                  isNormal: vitalSigns.heartRate >= 60 && vitalSigns.heartRate <= 100,
                  isAvailable: sensorStatus.max30102Available,
                ),
                _buildVitalSign(
                  context,
                  icon: Icons.air,
                  label: 'SpO2',
                  value: '${vitalSigns.oxygenSaturation}%',
                  isNormal: vitalSigns.oxygenSaturation >= 95,
                  isAvailable: sensorStatus.max30102Available,
                ),
              ],
            ),
            
            // Ambient data (if requested and available)
            if (showAmbientData && sensorStatus.dht11Available) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Conditions Ambiantes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildVitalSign(
                    context,
                    icon: Icons.wb_sunny,
                    label: 'Temp. Amb.',
                    value: vitalSigns.ambientTemperature != null
                        ? '${vitalSigns.ambientTemperature!.toStringAsFixed(1)}°C'
                        : 'N/A',
                    isNormal: vitalSigns.ambientTemperature != null &&
                             vitalSigns.ambientTemperature! >= 18.0 &&
                             vitalSigns.ambientTemperature! <= 26.0,
                    isAvailable: sensorStatus.dht11Available,
                  ),
                  _buildVitalSign(
                    context,
                    icon: Icons.water_drop,
                    label: 'Humidité',
                    value: vitalSigns.humidity != null
                        ? '${vitalSigns.humidity!.toStringAsFixed(0)}%'
                        : 'N/A',
                    isNormal: vitalSigns.humidity != null &&
                             vitalSigns.humidity! >= 30.0 &&
                             vitalSigns.humidity! <= 60.0,
                    isAvailable: sensorStatus.dht11Available,
                  ),
                  const SizedBox(width: 60), // Spacer for alignment
                ],
              ),
            ],
            
            // Movement alerts
            if (sensorStatus.mpu6050Available) ...[
              const SizedBox(height: 12),
              _buildMovementAlerts(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSensorStatusRow(SensorStatus status) {
    return Row(
      children: [
        Icon(
          status.allAvailable ? Icons.sensors : Icons.sensors_off,
          color: status.allAvailable ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Capteurs: ${status.availableCount}/3',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Row(
          children: [
            _buildSensorDot('MAX', status.max30102Available),
            const SizedBox(width: 4),
            _buildSensorDot('MPU', status.mpu6050Available),
            const SizedBox(width: 4),
            _buildSensorDot('DHT', status.dht11Available),
          ],
        ),
      ],
    );
  }

  Widget _buildSensorDot(String label, bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: available ? Colors.green : Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMovementAlerts() {
    final hasAlerts = vitalSigns.fallDetected || vitalSigns.suddenMovement;
    
    if (!hasAlerts) return const SizedBox.shrink();
    
    return Column(
      children: [
        if (vitalSigns.fallDetected)
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'CHUTE DÉTECTÉE',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        if (vitalSigns.suddenMovement)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.directions_run, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mouvement brusque détecté',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildVitalSign(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isNormal,
    bool isAvailable = true,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: !isAvailable 
              ? Colors.grey 
              : isNormal 
                  ? Colors.blue 
                  : Colors.red,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: !isAvailable ? Colors.grey : null,
          ),
        ),
        Text(
          isAvailable ? value : 'N/A',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: !isAvailable 
                    ? Colors.grey 
                    : isNormal 
                        ? null 
                        : Colors.red,
              ),
        ),
      ],
    );
  }
}
