import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/prognosis.dart';
import '../../domain/entities/care_action.dart';
import '../../domain/entities/take_charge_session.dart';
import '../widgets/vital_signs_display.dart';
import 'intervention_summary_screen.dart';
import 'intervention_ai_assistant_screen.dart';
import '../../../../core/services/demo_service.dart';
import '../../../../core/di/injection.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Écran de prise en charge en mode démo
class DemoTakeChargeScreen extends StatefulWidget {
  final int scenarioIndex;

  const DemoTakeChargeScreen({
    super.key,
    required this.scenarioIndex,
  });

  @override
  State<DemoTakeChargeScreen> createState() => _DemoTakeChargeScreenState();
}

class _DemoTakeChargeScreenState extends State<DemoTakeChargeScreen> {
  final DemoService _demoService = getIt<DemoService>();
  late TakeChargeSession _session;
  StreamSubscription? _vitalSignsSubscription;
  Timer? _durationTimer;

  @override
  void initState() {
    super.initState();
    _initializeSession();
    _startVitalSignsStream();
    _startDurationTimer();
  }

  void _initializeSession() {
    final vitalSigns = _demoService.generateCriticalVitalSigns();
    final history = _demoService.generateVitalSignsHistory(
      count: 10,
      interval: const Duration(seconds: 30),
      critical: true,
    );

    // Créer un pronostic basé sur les signes vitaux
    final prognosis = _generatePrognosis(vitalSigns);

    _session = TakeChargeSession(
      sessionId: 'DEMO_SESSION_${DateTime.now().millisecondsSinceEpoch}',
      victimDeviceId: 'DEMO_VICTIM',
      volunteerId: 'DEMO_VOLUNTEER',
      alertId: 'DEMO_ALERT',
      startTime: DateTime.now(),
      initialPrognosis: prognosis,
      vitalSignsHistory: history,
      actionsPerformed: [],
    );
  }

  Prognosis _generatePrognosis(dynamic vitalSigns) {
    final criticalFactors = <CriticalFactor>[];
    PrognosisLevel level = PrognosisLevel.stable;
    String description = '';

    // Analyser les signes vitaux
    if (vitalSigns.temperature < 35.0) {
      criticalFactors.add(const CriticalFactor(
        factor: 'Hypothermie',
        description: 'Température corporelle dangereusement basse',
        severity: 'high',
      ));
      level = PrognosisLevel.critical;
    } else if (vitalSigns.temperature > 40.0) {
      criticalFactors.add(const CriticalFactor(
        factor: 'Hyperthermie',
        description: 'Température corporelle dangereusement élevée',
        severity: 'high',
      ));
      level = PrognosisLevel.critical;
    }

    if (vitalSigns.heartRate < 40) {
      criticalFactors.add(const CriticalFactor(
        factor: 'Bradycardie sévère',
        description: 'Rythme cardiaque trop lent',
        severity: 'high',
      ));
      level = PrognosisLevel.critical;
    } else if (vitalSigns.heartRate > 150) {
      criticalFactors.add(const CriticalFactor(
        factor: 'Tachycardie',
        description: 'Rythme cardiaque trop rapide',
        severity: 'high',
      ));
      level = PrognosisLevel.critical;
    }

    if (vitalSigns.oxygenSaturation < 85) {
      criticalFactors.add(const CriticalFactor(
        factor: 'Hypoxie sévère',
        description: 'Saturation en oxygène critique',
        severity: 'high',
      ));
      level = PrognosisLevel.critical;
    }

    if (vitalSigns.fallDetected) {
      criticalFactors.add(const CriticalFactor(
        factor: 'Traumatisme',
        description: 'Chute détectée - risque de blessures',
        severity: 'high',
      ));
      if (level != PrognosisLevel.critical) {
        level = PrognosisLevel.serious;
      }
    }

    // Générer la description
    if (level == PrognosisLevel.critical) {
      description = 'État critique nécessitant une intervention immédiate. '
          'Plusieurs paramètres vitaux sont hors normes.';
    } else if (level == PrognosisLevel.serious) {
      description = 'État grave nécessitant une surveillance rapprochée.';
    } else {
      description = 'État stable mais nécessite une surveillance.';
    }

    // Générer les recommandations
    final recommendations = <String>[];
    if (vitalSigns.temperature < 35.0) {
      recommendations.add('Réchauffer progressivement la victime');
      recommendations.add('Surveiller la conscience');
    } else if (vitalSigns.temperature > 40.0) {
      recommendations.add('Refroidir la victime progressivement');
      recommendations.add('Hydrater si conscient');
    }

    if (vitalSigns.heartRate < 40 || vitalSigns.heartRate > 150) {
      recommendations.add('Surveiller le pouls en continu');
      recommendations.add('Préparer à appeler le 15');
    }

    if (vitalSigns.oxygenSaturation < 90) {
      recommendations.add('Assurer une bonne ventilation');
      recommendations.add('Position semi-assise si possible');
    }

    if (vitalSigns.fallDetected) {
      recommendations.add('Ne pas déplacer la victime');
      recommendations.add('Vérifier les blessures visibles');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Surveiller les signes vitaux');
      recommendations.add('Rassurer la victime');
    }

    return Prognosis(
      level: level,
      description: description,
      criticalFactors: criticalFactors,
      initialRecommendations: recommendations,
      analyzedAt: DateTime.now(),
    );
  }

  void _startVitalSignsStream() {
    _vitalSignsSubscription = _demoService.startVitalSignsStream(critical: true).listen((vitalSigns) {
      setState(() {
        _session = _session.copyWith(
          vitalSignsHistory: [..._session.vitalSignsHistory, vitalSigns],
        );
      });
    });
  }

  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // Force rebuild pour mettre à jour la durée
      });
    });
  }

  @override
  void dispose() {
    _vitalSignsSubscription?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prise en charge (Démo)'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bandeau démo
            _buildDemoBanner(),
            const SizedBox(height: 16),

            // Durée de l'intervention
            _buildDurationCard(context, _session.duration),
            const SizedBox(height: 16),

            // Pronostic vital
            _buildPrognosisCard(context, _session.initialPrognosis),
            const SizedBox(height: 16),

            // Signes vitaux en temps réel
            if (_session.vitalSignsHistory.isNotEmpty) ...[
              Text(
                'Signes vitaux actuels',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              VitalSignsDisplay(
                vitalSigns: _session.vitalSignsHistory.last,
                showAmbientData: true,
                showSensorStatus: true,
              ),
              const SizedBox(height: 16),
            ],

            // Recommandations de soins
            _buildRecommendationsCard(
              context,
              _session.initialPrognosis.initialRecommendations,
              _session.vitalSignsHistory.isNotEmpty ? _session.vitalSignsHistory.last : null,
            ),
            const SizedBox(height: 16),

            // Actions effectuées
            if (_session.actionsPerformed.isNotEmpty) ...[
              Text(
                'Actions effectuées (${_session.actionsPerformed.length})',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ..._session.actionsPerformed.map(
                (action) => Card(
                  child: ListTile(
                    leading: Icon(
                      action.completed ? Icons.check_circle : Icons.circle_outlined,
                      color: action.completed ? Colors.green : Colors.grey,
                    ),
                    title: Text(action.description),
                    subtitle: Text(
                      '${action.performedAt.hour}:${action.performedAt.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Boutons d'action
            ElevatedButton.icon(
              onPressed: () {
                _showAddActionDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une action de soins'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider(
                      create: (context) => getIt<AIAssistantBloc>(),
                      child: InterventionAIAssistantScreen(
                        session: _session,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.psychology),
              label: const Text('Affiner avec l\'IA'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Bouton terminer l'intervention
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InterventionSummaryScreen(
                      session: _session,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.done, size: 24),
              label: const Text(
                'TERMINER L\'INTERVENTION',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ],
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
                  'Intervention simulée avec données fictives',
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

  Widget _buildDurationCard(BuildContext context, Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer, size: 32, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              'Durée: ${minutes}min ${seconds}s',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrognosisCard(BuildContext context, Prognosis prognosis) {
    Color color;
    IconData icon;

    switch (prognosis.level) {
      case PrognosisLevel.critical:
        color = Colors.red;
        icon = Icons.warning;
        break;
      case PrognosisLevel.serious:
        color = Colors.orange;
        icon = Icons.error_outline;
        break;
      case PrognosisLevel.moderate:
        color = Colors.yellow.shade700;
        icon = Icons.info_outline;
        break;
      case PrognosisLevel.stable:
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
    }

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pronostic: ${_getPrognosisLabel(prognosis.level)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              prognosis.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (prognosis.criticalFactors.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Facteurs critiques:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...prognosis.criticalFactors.map(
                (factor) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: factor.severity == 'high' ? Colors.red : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${factor.factor}: ${factor.description}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(
    BuildContext context,
    List<String> recommendations,
    dynamic vitalSigns,
  ) {
    String? diagnosis;
    if (vitalSigns != null) {
      diagnosis = _getDiagnosisFromVitalSigns(vitalSigns);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommandations de soins',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            
            if (diagnosis != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.medical_information, color: Colors.blue.shade900, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Diagnostic possible',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      diagnosis,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade900,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
            ],
            
            Text(
              'Actions recommandées',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...recommendations.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String? _getDiagnosisFromVitalSigns(dynamic vitalSigns) {
    final temp = vitalSigns.temperature;
    final hr = vitalSigns.heartRate;
    final spo2 = vitalSigns.oxygenSaturation;
    final fall = vitalSigns.fallDetected;

    final issues = <String>[];

    if (temp < 35.0) {
      issues.add('hypothermie (température < 35°C)');
    } else if (temp > 40.0) {
      issues.add('hyperthermie sévère (température > 40°C)');
    }

    if (hr < 40 && hr > 0) {
      issues.add('bradycardie sévère (FC < 40 BPM)');
    } else if (hr > 150) {
      issues.add('tachycardie importante (FC > 150 BPM)');
    }

    if (spo2 < 85 && spo2 > 0) {
      issues.add('hypoxie sévère (SpO2 < 85%)');
    } else if (spo2 < 90 && spo2 > 0) {
      issues.add('hypoxie modérée (SpO2 < 90%)');
    }

    if (fall) {
      issues.add('traumatisme suite à une chute');
    }

    if (issues.isEmpty) {
      return 'Signes vitaux dans les normes. Surveillance continue recommandée.';
    }

    return 'Suspicion de ${issues.join(', ')}. Surveillance rapprochée nécessaire.';
  }

  String _getPrognosisLabel(PrognosisLevel level) {
    switch (level) {
      case PrognosisLevel.critical:
        return 'CRITIQUE';
      case PrognosisLevel.serious:
        return 'GRAVE';
      case PrognosisLevel.moderate:
        return 'MODÉRÉ';
      case PrognosisLevel.stable:
        return 'STABLE';
    }
  }

  void _showAddActionDialog(BuildContext context) {
    final actionController = TextEditingController();
    final notesController = TextEditingController();
    String selectedType = 'Évaluation';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ajouter une action de soins'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Type d\'action'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: const [
                  DropdownMenuItem(value: 'Évaluation', child: Text('Évaluation')),
                  DropdownMenuItem(value: 'Traitement', child: Text('Traitement')),
                  DropdownMenuItem(value: 'Surveillance', child: Text('Surveillance')),
                  DropdownMenuItem(value: 'Communication', child: Text('Communication')),
                ],
                onChanged: (value) {
                  if (value != null) selectedType = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: actionController,
                decoration: const InputDecoration(
                  labelText: 'Action effectuée',
                  hintText: 'Ex: Prise de tension artérielle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  hintText: 'Observations complémentaires',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (actionController.text.isNotEmpty) {
                final action = CareAction(
                  actionId: DateTime.now().millisecondsSinceEpoch.toString(),
                  description: '$selectedType: ${actionController.text}',
                  performedAt: DateTime.now(),
                  duration: const Duration(minutes: 1),
                  notes: notesController.text.isEmpty ? null : notesController.text,
                  completed: true,
                );
                
                setState(() {
                  _session = _session.copyWith(
                    actionsPerformed: [..._session.actionsPerformed, action],
                  );
                });
                
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Action ajoutée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
