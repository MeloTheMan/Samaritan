import 'package:flutter/material.dart';
import '../../../device/domain/entities/vital_signs.dart';

class VitalSignsDisplay extends StatelessWidget {
  final VitalSigns vitalSigns;

  const VitalSignsDisplay({
    super.key,
    required this.vitalSigns,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalSign(
                  context,
                  icon: Icons.thermostat,
                  label: 'Température',
                  value: '${vitalSigns.temperature.toStringAsFixed(1)}°C',
                  isNormal: vitalSigns.temperature >= 36.0 && vitalSigns.temperature <= 38.0,
                ),
                _buildVitalSign(
                  context,
                  icon: Icons.favorite,
                  label: 'Pouls',
                  value: '${vitalSigns.heartRate} BPM',
                  isNormal: vitalSigns.heartRate >= 60 && vitalSigns.heartRate <= 100,
                ),
                _buildVitalSign(
                  context,
                  icon: Icons.air,
                  label: 'SpO2',
                  value: '${vitalSigns.oxygenSaturation}%',
                  isNormal: vitalSigns.oxygenSaturation >= 95,
                ),
              ],
            ),
            if (vitalSigns.fallDetected) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Chute détectée',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVitalSign(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isNormal,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isNormal ? Colors.blue : Colors.red,
          size: 32,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isNormal ? null : Colors.red,
              ),
        ),
      ],
    );
  }
}
