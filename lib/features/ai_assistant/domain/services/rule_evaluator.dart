import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import '../entities/medical_data.dart';
import '../entities/diagnostic_result.dart';

/// Évaluateur de règles décisionnelles
@lazySingleton
class RuleEvaluator {
  Map<String, dynamic>? _decisionTree;
  bool _initialized = false;

  /// Initialise le moteur en chargeant l'arbre décisionnel
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString('assets/ai/decision_tree.json');
      _decisionTree = json.decode(jsonString);
      _initialized = true;
      print('✅ [RuleEvaluator] Arbre décisionnel chargé: ${_decisionTree!['rules'].length} règles');
    } catch (e) {
      print('❌ [RuleEvaluator] Erreur chargement: $e');
      rethrow;
    }
  }

  /// Évalue les données médicales et retourne les diagnostics possibles
  Future<List<DiagnosticResult>> evaluate(MedicalData data) async {
    if (!_initialized) {
      await initialize();
    }

    print('🔍 [RuleEvaluator] Évaluation de: $data');

    final results = <DiagnosticResult>[];
    final rules = _decisionTree!['rules'] as List<dynamic>;
    final dataMap = data.toMap();

    for (final rule in rules) {
      final ruleMap = rule as Map<String, dynamic>;
      final ruleId = ruleMap['id'] as String;
      final conditions = ruleMap['conditions'] as Map<String, dynamic>;

      // Évaluer les conditions
      final matches = _evaluateConditions(conditions, dataMap);

      if (matches) {
        // Calculer le score
        final baseScore = ruleMap['baseScore'] as int;
        final finalScore = _calculateScore(baseScore, data);

        print('✅ [RuleEvaluator] Règle $ruleId correspond (score: $finalScore%)');

        // Créer le résultat
        final result = DiagnosticResult(
          id: ruleId,
          name: ruleMap['name'] as String,
          description: ruleMap['description'] as String,
          confidenceScore: finalScore,
          urgencyLevel: ruleMap['urgency'] as String,
          recommendedActions: (ruleMap['actions'] as List<dynamic>)
              .map((e) => e.toString())
              .toList(),
          relatedCourseId: ruleMap['courseId'] as String?,
          warnings: ruleMap['warnings'] != null
              ? (ruleMap['warnings'] as List<dynamic>)
                  .map((e) => e.toString())
                  .toList()
              : [],
        );

        results.add(result);
      }
    }

    // Trier par urgence puis par score
    results.sort((a, b) {
      final urgencyOrder = {'critique': 0, 'urgent': 1, 'modéré': 2, 'routine': 3};
      final urgencyCompare = (urgencyOrder[a.urgencyLevel] ?? 99)
          .compareTo(urgencyOrder[b.urgencyLevel] ?? 99);
      if (urgencyCompare != 0) return urgencyCompare;
      return b.confidenceScore.compareTo(a.confidenceScore);
    });

    print('🎯 [RuleEvaluator] ${results.length} diagnostic(s) trouvé(s)');
    return results;
  }

  /// Évalue un ensemble de conditions (AND/OR)
  bool _evaluateConditions(Map<String, dynamic> conditions, Map<String, dynamic> data) {
    final type = conditions['type'] as String;

    if (type == 'AND') {
      final rules = conditions['rules'] as List<dynamic>;
      return rules.every((rule) => _evaluateSingleCondition(rule as Map<String, dynamic>, data));
    } else if (type == 'OR') {
      final rules = conditions['rules'] as List<dynamic>;
      return rules.any((rule) => _evaluateSingleCondition(rule as Map<String, dynamic>, data));
    } else {
      // Condition simple
      return _evaluateSingleCondition(conditions, data);
    }
  }

  /// Évalue une condition simple
  bool _evaluateSingleCondition(Map<String, dynamic> condition, Map<String, dynamic> data) {
    // Si c'est un groupe AND/OR, évaluer récursivement
    if (condition.containsKey('type')) {
      return _evaluateConditions(condition, data);
    }

    final field = condition['field'] as String;
    final operator = condition['operator'] as String;
    final expectedValue = condition['value'];

    final actualValue = data[field];

    // Si la valeur n'existe pas, la condition échoue
    if (actualValue == null) {
      return false;
    }

    switch (operator) {
      case 'equals':
        return actualValue.toString() == expectedValue.toString();

      case 'in':
        final values = expectedValue as List<dynamic>;
        return values.contains(actualValue.toString());

      case 'lessThan':
        if (actualValue is num && expectedValue is num) {
          return actualValue < expectedValue;
        }
        return false;

      case 'greaterThan':
        if (actualValue is num && expectedValue is num) {
          return actualValue > expectedValue;
        }
        return false;

      case 'between':
        if (actualValue is num && expectedValue is Map) {
          final min = expectedValue['min'] as num;
          final max = expectedValue['max'] as num;
          return actualValue >= min && actualValue <= max;
        }
        return false;

      default:
        print('⚠️ [RuleEvaluator] Opérateur inconnu: $operator');
        return false;
    }
  }

  /// Calcule le score final en fonction des données
  int _calculateScore(int baseScore, MedicalData data) {
    var score = baseScore;

    // Bonus si données du bracelet (plus fiables)
    if (data.dataSource == 'bracelet' || data.dataSource == 'bracelet_merged') {
      score = (score * 1.05).round().clamp(0, 100);
    }

    // Bonus si multiples symptômes cohérents
    final symptomCount = _countSymptoms(data);
    if (symptomCount >= 3) {
      score = (score * 1.1).round().clamp(0, 100);
    }

    return score.clamp(0, 100);
  }

  /// Compte le nombre de symptômes présents
  int _countSymptoms(MedicalData data) {
    var count = 0;
    final map = data.toMap();

    for (final entry in map.entries) {
      final value = entry.value;
      if (value == true || 
          (value is String && value != 'normal' && value != 'user_prompt' && value != 'bracelet')) {
        count++;
      }
    }

    return count;
  }

  /// Génère des questions de clarification si le score est faible
  List<String> getSuggestedQuestions(MedicalData data) {
    final questions = <String>[];

    // Questions selon les symptômes présents
    if (data.hasHeadache && data.headacheIntensity == null) {
      questions.add("Quelle est l'intensité de votre mal de tête?");
    }

    if (data.bodyTemperature != null && data.bodyTemperature! > 38) {
      questions.add("Depuis combien de temps avez-vous de la fièvre?");
    }

    if (data.hasChestPain) {
      questions.add("La douleur irradie-t-elle dans le bras ou la mâchoire?");
    }

    if (data.breathing == 'difficile') {
      questions.add("Avez-vous des antécédents d'asthme ou d'allergies?");
    }

    if (data.hasBleeding && data.bleedingSeverity == null) {
      questions.add("Le saignement est-il abondant?");
    }

    // Questions générales si peu de données
    if (_countSymptoms(data) < 2) {
      questions.addAll([
        "Pouvez-vous décrire vos symptômes plus en détail?",
        "Depuis quand ressentez-vous ces symptômes?",
        "Avez-vous d'autres symptômes associés?",
      ]);
    }

    return questions.take(3).toList();
  }
}
