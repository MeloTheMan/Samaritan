import 'package:flutter/material.dart';
import '../../domain/entities/emergency_alert.dart';
import 'navigation_screen.dart';
import '../../../../core/services/demo_service.dart';
import '../../../../core/di/injection.dart';

class AlertNotificationScreen extends StatelessWidget {
  final EmergencyAlert alert;

  const AlertNotificationScreen({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerte d\'urgence'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête d'alerte
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 64,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'PERSONNE EN DÉTRESSE',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.red.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Une personne à proximité a besoin d\'aide',
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Informations de distance
              if (alert.distance != null) ...[
                _buildInfoCard(
                  context,
                  icon: Icons.location_on,
                  title: 'Distance',
                  value: '${alert.distance!.toStringAsFixed(0)} m',
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
              ],

              // Signes vitaux
              _buildVitalSignsCard(context),
              const SizedBox(height: 12),

              // Heure de l'alerte
              _buildInfoCard(
                context,
                icon: Icons.access_time,
                title: 'Alerte reçue',
                value: _formatTime(alert.receivedAt),
                color: Colors.orange,
              ),

              const Spacer(),

              // Boutons d'action
              ElevatedButton.icon(
                onPressed: () {
                  // Naviguer vers l'écran de navigation
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NavigationScreen(alert: alert),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation, size: 28),
                label: const Text(
                  'ALLER VERS LA VICTIME',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  minimumSize: const Size(double.infinity, 60),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  // Fermer l'écran d'alerte
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
                label: const Text('Ignorer l\'alerte'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
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

  Widget _buildVitalSignsCard(BuildContext context) {
    final signs = alert.vitalSigns;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Signes vitaux',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildVitalSign(
                  context,
                  icon: Icons.thermostat,
                  label: 'Temp.',
                  value: '${signs.temperature.toStringAsFixed(1)}°C',
                  isAbnormal: signs.temperature < 36.0 || signs.temperature > 38.0,
                ),
                _buildVitalSign(
                  context,
                  icon: Icons.favorite,
                  label: 'Pouls',
                  value: '${signs.heartRate} BPM',
                  isAbnormal: signs.heartRate < 60 || signs.heartRate > 100,
                ),
                _buildVitalSign(
                  context,
                  icon: Icons.air,
                  label: 'SpO2',
                  value: '${signs.oxygenSaturation}%',
                  isAbnormal: signs.oxygenSaturation < 95,
                ),
              ],
            ),
            if (signs.fallDetected) ...[
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
    required bool isAbnormal,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: isAbnormal ? Colors.red : Colors.blue,
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
                color: isAbnormal ? Colors.red : null,
              ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) {
      return 'À l\'instant';
    } else if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
