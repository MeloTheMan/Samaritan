import 'package:flutter/material.dart';
import '../../domain/entities/diagnostic_result.dart';

class DiagnosisCardWidget extends StatelessWidget {
  final DiagnosticResult diagnostic;

  const DiagnosisCardWidget({
    super.key,
    required this.diagnostic,
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
                    diagnostic.name,
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
                  'Confiance: ${diagnostic.confidenceScore}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            Text(
              diagnostic.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            
            // Actions
            if (diagnostic.recommendedActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...diagnostic.recommendedActions.map((action) => _buildAction(context, action)),
            ],
            
            // Avertissements
            if (diagnostic.warnings.isNotEmpty) ...[
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
                    ...diagnostic.warnings.map((warning) => Padding(
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
            if (diagnostic.relatedCourseId != null) ...[
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
    String urgencyText;

    switch (diagnostic.urgencyLevel) {
      case 'critique':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.emergency;
        urgencyText = 'CRITIQUE';
        break;
      case 'urgent':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.warning;
        urgencyText = 'URGENT';
        break;
      case 'modéré':
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.info;
        urgencyText = 'MODÉRÉ';
        break;
      case 'routine':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        urgencyText = 'ROUTINE';
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.help;
        urgencyText = 'INCONNU';
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
            urgencyText,
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

  Widget _buildAction(BuildContext context, String action) {
    // Détecter si c'est un appel d'urgence
    if (action.toLowerCase().contains('appeler') || action.contains('15') || action.contains('112')) {
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
                action,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Action normale
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              action,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
