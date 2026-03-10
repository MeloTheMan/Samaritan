import 'dart:math';
import 'package:injectable/injectable.dart';
import '../entities/diagnostic_result.dart';
import '../entities/medical_data.dart';

/// Générateur de réponses naturelles et variées
@injectable
class ResponseGenerator {
  final Random _random = Random();

  /// Génère une réponse complète à partir des diagnostics
  String generateResponse({
    required List<DiagnosticResult> diagnostics,
    required MedicalData data,
    List<String>? suggestedQuestions,
  }) {
    if (diagnostics.isEmpty) {
      return _generateNoMatchResponse(data, suggestedQuestions);
    }

    final buffer = StringBuffer();
    final primary = diagnostics.first;

    // Introduction variée selon l'urgence
    buffer.writeln(_getIntroduction(primary.urgencyLevel));
    buffer.writeln();

    // Diagnostic principal
    buffer.writeln(_formatDiagnosis(primary, isPrimary: true));

    // Autres diagnostics possibles (max 2)
    if (diagnostics.length > 1) {
      buffer.writeln();
      buffer.writeln(_getAlternativesHeader());
      for (var i = 1; i < diagnostics.length && i < 3; i++) {
        buffer.writeln('• ${diagnostics[i].name} (${diagnostics[i].confidenceScore}%)');
      }
    }

    // Questions de suivi si disponibles
    if (suggestedQuestions != null && suggestedQuestions.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_getQuestionsHeader());
      for (final question in suggestedQuestions.take(3)) {
        buffer.writeln('• $question');
      }
    }

    // Disclaimer médical
    buffer.writeln();
    buffer.writeln(_getDisclaimer());

    return buffer.toString();
  }

  /// Formate un diagnostic complet
  String _formatDiagnosis(DiagnosticResult diagnosis, {bool isPrimary = false}) {
    final buffer = StringBuffer();

    // Titre avec emoji d'urgence
    buffer.writeln('${diagnosis.urgencyEmoji} **${diagnosis.name}**');
    buffer.writeln('Confiance: ${diagnosis.confidenceScore}%');
    buffer.writeln();

    // Description
    buffer.writeln(diagnosis.description);
    buffer.writeln();

    // Actions recommandées
    if (diagnosis.recommendedActions.isNotEmpty) {
      buffer.writeln(_getActionsHeader(diagnosis.urgencyLevel));
      for (final action in diagnosis.recommendedActions) {
        buffer.writeln('${_getBulletPoint()} $action');
      }
    }

    // Avertissements
    if (diagnosis.warnings.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('⚠️ **Points importants:**');
      for (final warning in diagnosis.warnings) {
        buffer.writeln('• $warning');
      }
    }

    // Lien vers le cours si disponible
    if (diagnosis.relatedCourseId != null) {
      buffer.writeln();
      buffer.writeln(_getCourseReference());
    }

    return buffer.toString();
  }

  /// Génère une réponse quand aucun diagnostic ne correspond
  String _generateNoMatchResponse(MedicalData data, List<String>? questions) {
    final buffer = StringBuffer();

    // Introduction variée
    final intros = [
      'Je n\'ai pas pu identifier de diagnostic spécifique avec les informations fournies.',
      'Les symptômes décrits ne correspondent pas à un diagnostic clair pour le moment.',
      'J\'ai besoin de plus d\'informations pour établir un diagnostic précis.',
    ];
    buffer.writeln(intros[_random.nextInt(intros.length)]);
    buffer.writeln();

    // Demander plus de détails
    buffer.writeln('**Pour vous aider au mieux, pourriez-vous préciser:**');
    
    if (questions != null && questions.isNotEmpty) {
      for (final question in questions.take(3)) {
        buffer.writeln('• $question');
      }
    } else {
      buffer.writeln('• Vos symptômes principaux');
      buffer.writeln('• Depuis quand ils ont commencé');
      buffer.writeln('• Leur intensité et évolution');
    }

    buffer.writeln();
    buffer.writeln(_getEmergencyReminder());

    return buffer.toString();
  }

  // ===== VARIATIONS DE TEXTE =====

  String _getIntroduction(String urgency) {
    switch (urgency) {
      case 'critique':
        final options = [
          '🚨 **SITUATION D\'URGENCE VITALE DÉTECTÉE**',
          '🚨 **URGENCE MÉDICALE IMMÉDIATE**',
          '🚨 **INTERVENTION URGENTE NÉCESSAIRE**',
        ];
        return options[_random.nextInt(options.length)];

      case 'urgent':
        final options = [
          '⚠️ **Situation urgente détectée**',
          '⚠️ **Attention: intervention rapide nécessaire**',
          '⚠️ **Situation nécessitant une prise en charge urgente**',
        ];
        return options[_random.nextInt(options.length)];

      case 'modéré':
        final options = [
          '⏰ **Analyse des symptômes**',
          '⏰ **Évaluation médicale**',
          '⏰ **Diagnostic établi**',
        ];
        return options[_random.nextInt(options.length)];

      case 'routine':
        final options = [
          'ℹ️ **Voici mon analyse**',
          'ℹ️ **Analyse des symptômes**',
          'ℹ️ **Évaluation de la situation**',
        ];
        return options[_random.nextInt(options.length)];

      default:
        return 'ℹ️ **Analyse**';
    }
  }

  String _getActionsHeader(String urgency) {
    switch (urgency) {
      case 'critique':
        return '🚨 **ACTIONS IMMÉDIATES:**';
      case 'urgent':
        return '⚠️ **Actions à effectuer rapidement:**';
      case 'modéré':
        return '📋 **Actions recommandées:**';
      case 'routine':
        final options = [
          '💡 **Conseils:**',
          '📝 **Recommandations:**',
          '🔹 **Ce que vous pouvez faire:**',
        ];
        return options[_random.nextInt(options.length)];
      default:
        return '📋 **Actions:**';
    }
  }

  String _getAlternativesHeader() {
    final options = [
      '🔎 **Autres possibilités à considérer:**',
      '🔍 **Diagnostics alternatifs possibles:**',
      '📊 **Autres hypothèses:**',
    ];
    return options[_random.nextInt(options.length)];
  }

  String _getQuestionsHeader() {
    final options = [
      '❓ **Questions pour affiner le diagnostic:**',
      '💬 **Pour mieux vous aider:**',
      '🔍 **Informations complémentaires utiles:**',
    ];
    return options[_random.nextInt(options.length)];
  }

  String _getCourseReference() {
    final options = [
      '📚 Un cours de formation est disponible sur ce sujet dans l\'application.',
      '📖 Consultez le cours associé pour en savoir plus sur cette situation.',
      '🎓 Formation disponible: consultez le cours pour approfondir vos connaissances.',
    ];
    return options[_random.nextInt(options.length)];
  }

  String _getDisclaimer() {
    final options = [
      '⚕️ *Cette analyse est indicative. En cas de doute, consultez un professionnel de santé.*',
      '⚕️ *Cet outil est une aide à la décision. Seul un professionnel de santé peut établir un diagnostic définitif.*',
      '⚕️ *Cette évaluation ne remplace pas un avis médical professionnel.*',
    ];
    return options[_random.nextInt(options.length)];
  }

  String _getEmergencyReminder() {
    final options = [
      '🚨 **En cas d\'urgence vitale, appelez immédiatement le 15 (SAMU) ou le 112.**',
      '🚨 **Si vous pensez qu\'il s\'agit d\'une urgence, n\'hésitez pas à appeler le 15.**',
      '🚨 **Urgence? Composez le 15 (SAMU) ou le 112 sans attendre.**',
    ];
    return options[_random.nextInt(options.length)];
  }

  String _getBulletPoint() {
    final options = ['▸', '→', '•', '✓'];
    return options[_random.nextInt(options.length)];
  }

  /// Génère un message de bienvenue
  String generateWelcomeMessage() {
    final options = [
      'Bonjour! Je suis votre assistant médical IA. Décrivez-moi vos symptômes et je vous aiderai à identifier la situation.',
      'Bienvenue! Parlez-moi de vos symptômes, je suis là pour vous aider à évaluer la situation.',
      'Bonjour! Décrivez-moi ce que vous ressentez, je vais analyser vos symptômes.',
    ];
    return options[_random.nextInt(options.length)];
  }

  /// Génère un message d'erreur convivial
  String generateErrorMessage() {
    final options = [
      'Désolé, une erreur s\'est produite lors de l\'analyse. Pouvez-vous reformuler votre message?',
      'Je n\'ai pas pu traiter votre demande. Pourriez-vous décrire vos symptômes différemment?',
      'Une erreur est survenue. Essayez de décrire vos symptômes de manière plus détaillée.',
    ];
    return options[_random.nextInt(options.length)];
  }

  /// Génère un message d'encouragement pour plus de détails
  String generateNeedMoreInfoMessage() {
    final options = [
      'Pouvez-vous me donner plus de détails sur vos symptômes?',
      'J\'ai besoin de plus d\'informations pour vous aider efficacement.',
      'Pourriez-vous préciser davantage vos symptômes?',
    ];
    return options[_random.nextInt(options.length)];
  }

  /// Génère un message de confirmation de réception
  String generateAcknowledgment() {
    final options = [
      'J\'analyse vos symptômes...',
      'Un instant, je traite les informations...',
      'Analyse en cours...',
    ];
    return options[_random.nextInt(options.length)];
  }
}
