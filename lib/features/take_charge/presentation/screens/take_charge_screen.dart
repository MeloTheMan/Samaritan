import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/intervention_bloc.dart';
import '../bloc/intervention_state.dart';
import '../bloc/intervention_event.dart';
import '../../domain/entities/prognosis.dart';
import '../../domain/entities/care_action.dart';
import '../widgets/vital_signs_display.dart';
import 'intervention_summary_screen.dart';

class TakeChargeScreen extends StatelessWidget {
  const TakeChargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prise en charge'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Afficher l'historique des actions
            },
          ),
        ],
      ),
      body: BlocConsumer<InterventionBloc, InterventionState>(
        listener: (context, state) {
          if (state is InterventionCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Intervention terminée avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is InterventionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InterventionConnecting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connexion au bracelet de la victime...'),
                ],
              ),
            );
          }

          if (state is InterventionActive ||
              state is InterventionVitalSignsUpdated ||
              state is InterventionCareActionAdded) {
            final session = (state is InterventionActive)
                ? state.session
                : (state is InterventionVitalSignsUpdated)
                    ? state.session
                    : (state as InterventionCareActionAdded).session;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Durée de l'intervention
                  _buildDurationCard(context, session.duration),
                  const SizedBox(height: 16),

                  // Pronostic vital
                  _buildPrognosisCard(context, session.initialPrognosis),
                  const SizedBox(height: 16),

                  // Signes vitaux en temps réel
                  if (session.vitalSignsHistory.isNotEmpty) ...[
                    Text(
                      'Signes vitaux actuels',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    VitalSignsDisplay(
                      vitalSigns: session.vitalSignsHistory.last,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Recommandations de soins
                  _buildRecommendationsCard(
                    context,
                    session.initialPrognosis.initialRecommendations,
                  ),
                  const SizedBox(height: 16),

                  // Actions effectuées
                  if (session.actionsPerformed.isNotEmpty) ...[
                    Text(
                      'Actions effectuées (${session.actionsPerformed.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...session.actionsPerformed.map(
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
                      _showAddActionDialog(context, session);
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
                      // TODO: Intégrer avec AI Assistant
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à venir : Affiner avec l\'IA'),
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

                  // Bouton d'urgence
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Appeler les urgences
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Appeler les urgences'),
                          content: const Text(
                            'Voulez-vous appeler le 15 (SAMU) ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Annuler'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Lancer l'appel
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Appeler'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone, size: 24),
                    label: const Text(
                      'APPELER LES URGENCES (15)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Bouton terminer l'intervention
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterventionSummaryScreen(
                            session: session,
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
            );
          }

          // État initial ou en attente
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initialisation de l\'intervention...'),
              ],
            ),
          );
        },
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
  ) {
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

  void _showAddActionDialog(BuildContext context, dynamic session) {
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
                
                context.read<InterventionBloc>().add(AddCareAction(action));
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
