import 'package:flutter/material.dart';
import '../../domain/entities/emergency_alert.dart';
import '../../../take_charge/presentation/screens/demo_take_charge_screen.dart';
import '../../../../core/services/demo_service.dart';
import '../../../../core/di/injection.dart';

/// Écran pour démarrer une intervention de démonstration
class DemoAlertScreen extends StatelessWidget {
  const DemoAlertScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Démo - Intervention'),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bandeau info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.orange.shade700, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Démonstration',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Testez le processus d\'intervention avec des données simulées',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Titre
            const Text(
              'Choisissez un scénario',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Sélectionnez le type de situation d\'urgence à simuler',
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Scénarios
            Expanded(
              child: ListView(
                children: [
                  _buildScenarioCard(
                    context,
                    title: 'Hypothermie + Bradycardie',
                    description: 'Température basse (34°C) et rythme cardiaque lent (35 BPM)',
                    icon: Icons.ac_unit,
                    color: Colors.blue,
                    severity: 'Critique',
                    onTap: () => _startDemoIntervention(context, 0),
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    context,
                    title: 'Hyperthermie + Tachycardie',
                    description: 'Température élevée (41°C) et rythme cardiaque rapide (160 BPM)',
                    icon: Icons.local_fire_department,
                    color: Colors.red,
                    severity: 'Critique',
                    onTap: () => _startDemoIntervention(context, 1),
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioCard(
                    context,
                    title: 'Chute + Hypoxie',
                    description: 'Chute détectée avec faible saturation en oxygène (83%)',
                    icon: Icons.warning,
                    color: Colors.orange,
                    severity: 'Grave',
                    onTap: () => _startDemoIntervention(context, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String severity,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            severity,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  void _startDemoIntervention(BuildContext context, int scenarioIndex) {
    // Naviguer vers l'écran d'intervention de démo
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DemoTakeChargeScreen(
          scenarioIndex: scenarioIndex,
        ),
      ),
    );
  }
}
