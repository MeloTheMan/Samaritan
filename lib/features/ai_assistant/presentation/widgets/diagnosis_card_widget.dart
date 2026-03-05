import 'package:flutter/material.dart';
import '../../domain/entities/diagnosis.dart';

class DiagnosisCardWidget extends StatelessWidget {
  final Diagnosis diagnosis;

  const DiagnosisCardWidget({
    super.key,
    required this.diagnosis,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec condition et urgence
            Row(
              children: [
                Expanded(
                  child: Text(
                    diagnosis.condition,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                _buildUrgencyBadge(context),
              ],
            ),
            const SizedBox(height: 8),
            
            // Confiance
            Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Confiance: ${diagnosis.confidence}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              diagnosis.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // Actions
            if (diagnosis.actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...diagnosis.actions.map((action) => _buildAction(context, action)),
            ],
            
            // Avertissements
            if (diagnosis.warnings.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Avertissements',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...diagnosis.warnings.map((warning) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '• $warning',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ],
            
            // Lien vers cours
            if (diagnosis.relatedCourseId != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  // TODO: Naviguer vers le cours
                },
                icon: const Icon(Icons.school),
                label: const Text('Voir le cours complet'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyBadge(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (diagnosis.urgency) {
      case UrgencyLevel.immediate:
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.emergency;
        break;
      case UrgencyLevel.urgent:
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      case UrgencyLevel.moderate:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.info;
        break;
      case UrgencyLevel.routine:
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            diagnosis.urgency.name.toUpperCase(),
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, DiagnosisAction action) {
    if (action.type == ActionType.emergency_call) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          border: Border.all(color: Colors.red, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.phone, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                action.message ?? 'Appeler les secours',
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Appeler le 15
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Appeler 15'),
            ),
          ],
        ),
      );
    }

    if (action.type == ActionType.protocol && action.steps != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              action.title ?? 'Protocole',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...action.steps!.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
