import 'package:flutter/material.dart';
import '../../domain/entities/take_charge_session.dart';
import '../../domain/entities/intervention_outcome.dart';

class InterventionSummaryScreen extends StatefulWidget {
  final TakeChargeSession session;

  const InterventionSummaryScreen({
    super.key,
    required this.session,
  });

  @override
  State<InterventionSummaryScreen> createState() => _InterventionSummaryScreenState();
}

class _InterventionSummaryScreenState extends State<InterventionSummaryScreen> {
  OutcomeType? _selectedOutcome;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fin d\'intervention'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Résumé de l'intervention
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Résumé de l\'intervention',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      context,
                      icon: Icons.timer,
                      label: 'Durée',
                      value: _formatDuration(widget.session.duration),
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      context,
                      icon: Icons.medical_services,
                      label: 'Actions effectuées',
                      value: '${widget.session.actionsPerformed.length}',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      context,
                      icon: Icons.favorite,
                      label: 'Relevés de signes vitaux',
                      value: '${widget.session.vitalSignsHistory.length}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Sélection de l'issue
            Text(
              'Issue de l\'intervention *',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sélectionnez l\'état final de la victime',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),

            // Options d'issue
            ...OutcomeType.values.map(
              (outcome) => Card(
                color: _selectedOutcome == outcome
                    ? Colors.green.shade50
                    : null,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedOutcome = outcome;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Radio<OutcomeType>(
                          value: outcome,
                          groupValue: _selectedOutcome,
                          onChanged: (value) {
                            setState(() {
                              _selectedOutcome = value;
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getOutcomeLabel(outcome),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getOutcomeDescription(outcome),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _getOutcomeIcon(outcome),
                          color: _getOutcomeColor(outcome),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Notes additionnelles
            Text(
              'Notes additionnelles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ajoutez des détails sur l\'intervention...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),

            // Bouton de validation
            ElevatedButton.icon(
              onPressed: _selectedOutcome == null
                  ? null
                  : () {
                      // Retourner à l'écran principal
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      
                      // Afficher un message de confirmation
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Intervention terminée avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              icon: const Icon(Icons.check, size: 24),
              label: const Text(
                'TERMINER L\'INTERVENTION',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else if (minutes > 0) {
      return '${minutes}min ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _getOutcomeLabel(OutcomeType outcome) {
    switch (outcome) {
      case OutcomeType.resuscitated:
        return 'Victime réanimée';
      case OutcomeType.hospitalTransport:
        return 'Victime amenée à l\'hôpital';
      case OutcomeType.improved:
        return 'État de santé meilleur';
      case OutcomeType.stable:
        return 'État de santé stable';
      case OutcomeType.deteriorating:
        return 'État de santé en dégradation';
    }
  }

  String _getOutcomeDescription(OutcomeType outcome) {
    switch (outcome) {
      case OutcomeType.resuscitated:
        return 'La victime a repris conscience suite aux soins';
      case OutcomeType.hospitalTransport:
        return 'La victime a été transportée vers un établissement médical';
      case OutcomeType.improved:
        return 'L\'état de la victime s\'est amélioré';
      case OutcomeType.stable:
        return 'L\'état de la victime est stable';
      case OutcomeType.deteriorating:
        return 'L\'état de la victime s\'est dégradé';
    }
  }

  IconData _getOutcomeIcon(OutcomeType outcome) {
    switch (outcome) {
      case OutcomeType.resuscitated:
        return Icons.favorite;
      case OutcomeType.hospitalTransport:
        return Icons.local_hospital;
      case OutcomeType.improved:
        return Icons.trending_up;
      case OutcomeType.stable:
        return Icons.check_circle;
      case OutcomeType.deteriorating:
        return Icons.trending_down;
    }
  }

  Color _getOutcomeColor(OutcomeType outcome) {
    switch (outcome) {
      case OutcomeType.resuscitated:
        return Colors.green;
      case OutcomeType.hospitalTransport:
        return Colors.blue;
      case OutcomeType.improved:
        return Colors.green;
      case OutcomeType.stable:
        return Colors.blue;
      case OutcomeType.deteriorating:
        return Colors.orange;
    }
  }
}
