import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:samaritan/features/ai_assistant/domain/services/rule_evaluator.dart';
import 'package:samaritan/features/ai_assistant/domain/entities/medical_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late RuleEvaluator evaluator;

  setUp(() {
    evaluator = RuleEvaluator();
  });

  group('Initialisation', () {
    test('Charge l\'arbre décisionnel', () async {
      await evaluator.initialize();
      // Si pas d'exception, c'est bon
      expect(true, true);
    });
  });

  group('Règles critiques', () {
    test('Détecte arrêt cardiaque', () async {
      final data = MedicalData(
        consciousness: 'inconscient',
        breathing: 'absente',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      expect(results.first.name, 'Arrêt Cardiaque');
      expect(results.first.urgencyLevel, 'critique');
      expect(results.first.confidenceScore, greaterThanOrEqualTo(90));
    });

    test('Détecte hypothermie sévère', () async {
      final data = MedicalData(
        bodyTemperature: 30.0,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final hypothermia = results.firstWhere(
        (r) => r.name == 'Hypothermie Sévère',
        orElse: () => throw Exception('Hypothermie non détectée'),
      );
      expect(hypothermia.urgencyLevel, 'critique');
    });

    test('Détecte coup de chaleur', () async {
      final data = MedicalData(
        bodyTemperature: 41.0,
        consciousness: 'confus',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final heatstroke = results.firstWhere(
        (r) => r.name == 'Coup de Chaleur',
        orElse: () => throw Exception('Coup de chaleur non détecté'),
      );
      expect(heatstroke.urgencyLevel, 'critique');
    });

    test('Détecte hémorragie sévère', () async {
      final data = MedicalData(
        hasBleeding: true,
        bleedingSeverity: 'sévère',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final bleeding = results.firstWhere(
        (r) => r.name == 'Hémorragie Sévère',
        orElse: () => throw Exception('Hémorragie non détectée'),
      );
      expect(bleeding.urgencyLevel, 'critique');
    });

    test('Détecte choc anaphylactique', () async {
      final data = MedicalData(
        hasSwelling: true,
        swellingLocation: 'gorge',
        breathing: 'difficile',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final anaphylaxis = results.firstWhere(
        (r) => r.name == 'Choc Anaphylactique',
        orElse: () => throw Exception('Choc anaphylactique non détecté'),
      );
      expect(anaphylaxis.urgencyLevel, 'critique');
    });

    test('Détecte infarctus possible', () async {
      final data = MedicalData(
        hasChestPain: true,
        isPale: true,
        hasColdSweats: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final heartAttack = results.firstWhere(
        (r) => r.name == 'Infarctus Possible',
        orElse: () => throw Exception('Infarctus non détecté'),
      );
      expect(heartAttack.urgencyLevel, 'critique');
    });
  });

  group('Règles urgentes', () {
    test('Détecte détresse respiratoire', () async {
      final data = MedicalData(
        breathing: 'difficile',
        hasCyanosis: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final respiratory = results.firstWhere(
        (r) => r.name == 'Détresse Respiratoire',
        orElse: () => throw Exception('Détresse respiratoire non détectée'),
      );
      expect(respiratory.urgencyLevel, 'urgent');
    });

    test('Détecte hypothermie modérée', () async {
      final data = MedicalData(
        bodyTemperature: 33.5,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final hypothermia = results.firstWhere(
        (r) => r.name == 'Hypothermie Modérée',
        orElse: () => throw Exception('Hypothermie modérée non détectée'),
      );
      expect(hypothermia.urgencyLevel, 'urgent');
    });

    test('Détecte fièvre élevée', () async {
      final data = MedicalData(
        bodyTemperature: 40.0,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final fever = results.firstWhere(
        (r) => r.name == 'Fièvre Élevée',
        orElse: () => throw Exception('Fièvre élevée non détectée'),
      );
      expect(fever.urgencyLevel, 'urgent');
    });

    test('Détecte brûlure grave', () async {
      final data = MedicalData(
        hasBurn: true,
        burnDegree: '2ème',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final burn = results.firstWhere(
        (r) => r.name == 'Brûlure Grave',
        orElse: () => throw Exception('Brûlure grave non détectée'),
      );
      expect(burn.urgencyLevel, 'urgent');
    });
  });

  group('Règles modérées', () {
    test('Détecte syndrome grippal', () async {
      final data = MedicalData(
        bodyTemperature: 38.5,
        hasHeadache: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final flu = results.firstWhere(
        (r) => r.name == 'Syndrome Grippal',
        orElse: () => throw Exception('Syndrome grippal non détecté'),
      );
      expect(flu.urgencyLevel, 'modéré');
    });

    test('Détecte douleur thoracique simple', () async {
      final data = MedicalData(
        hasChestPain: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final chestPain = results.firstWhere(
        (r) => r.name == 'Douleur Thoracique Simple',
        orElse: () => throw Exception('Douleur thoracique non détectée'),
      );
      expect(chestPain.urgencyLevel, 'modéré');
    });
  });

  group('Règles routine', () {
    test('Détecte céphalée', () async {
      final data = MedicalData(
        hasHeadache: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final headache = results.firstWhere(
        (r) => r.name == 'Céphalée',
        orElse: () => throw Exception('Céphalée non détectée'),
      );
      expect(headache.urgencyLevel, 'routine');
    });

    test('Détecte troubles digestifs - nausées', () async {
      final data = MedicalData(
        hasNausea: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final digestive = results.firstWhere(
        (r) => r.name == 'Troubles Digestifs',
        orElse: () => throw Exception('Troubles digestifs non détectés'),
      );
      expect(digestive.urgencyLevel, 'routine');
    });

    test('Détecte troubles digestifs - vomissements', () async {
      final data = MedicalData(
        hasVomiting: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      expect(results.any((r) => r.name == 'Troubles Digestifs'), true);
    });

    test('Détecte troubles digestifs - douleur abdominale', () async {
      final data = MedicalData(
        hasAbdominalPain: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      expect(results.any((r) => r.name == 'Troubles Digestifs'), true);
    });

    test('Détecte vertiges', () async {
      final data = MedicalData(
        hasDizziness: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isNotEmpty, true);
      final dizziness = results.firstWhere(
        (r) => r.name == 'Vertiges',
        orElse: () => throw Exception('Vertiges non détectés'),
      );
      expect(dizziness.urgencyLevel, 'routine');
    });
  });

  group('Priorisation', () {
    test('Trie par urgence (critique avant urgent)', () async {
      final data = MedicalData(
        bodyTemperature: 40.5, // Fièvre élevée (urgent) + Coup de chaleur (critique)
        consciousness: 'confus',
        hasHeadache: true, // Céphalée (routine)
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.length, greaterThanOrEqualTo(2));
      // Le premier doit être critique
      expect(results.first.urgencyLevel, 'critique');
    });

    test('Trie par score si même urgence', () async {
      final data = MedicalData(
        hasHeadache: true, // Céphalée
        hasNausea: true, // Troubles digestifs
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.length, greaterThanOrEqualTo(2));
      // Tous doivent être routine
      for (final result in results) {
        expect(result.urgencyLevel, 'routine');
      }
      // Le premier doit avoir le score le plus élevé
      if (results.length > 1) {
        expect(
          results.first.confidenceScore,
          greaterThanOrEqualTo(results[1].confidenceScore),
        );
      }
    });
  });

  group('Bonus de score', () {
    test('Bonus pour données du bracelet', () async {
      final dataPrompt = MedicalData(
        bodyTemperature: 40.0,
        dataSource: 'user_prompt',
        timestamp: DateTime.now(),
      );

      final dataBracelet = MedicalData(
        bodyTemperature: 40.0,
        dataSource: 'bracelet',
        timestamp: DateTime.now(),
      );

      final resultsPrompt = await evaluator.evaluate(dataPrompt);
      final resultsBracelet = await evaluator.evaluate(dataBracelet);

      expect(resultsPrompt.isNotEmpty, true);
      expect(resultsBracelet.isNotEmpty, true);

      // Le score du bracelet doit être légèrement supérieur
      expect(
        resultsBracelet.first.confidenceScore,
        greaterThanOrEqualTo(resultsPrompt.first.confidenceScore),
      );
    });

    test('Bonus pour multiples symptômes', () async {
      final dataSimple = MedicalData(
        hasHeadache: true,
        timestamp: DateTime.now(),
      );

      final dataMultiple = MedicalData(
        hasHeadache: true,
        hasNausea: true,
        hasDizziness: true,
        bodyTemperature: 38.0,
        timestamp: DateTime.now(),
      );

      final resultsSimple = await evaluator.evaluate(dataSimple);
      final resultsMultiple = await evaluator.evaluate(dataMultiple);

      expect(resultsSimple.isNotEmpty, true);
      expect(resultsMultiple.isNotEmpty, true);

      // Les scores avec multiples symptômes doivent être plus élevés
      final simpleHeadache = resultsSimple.firstWhere((r) => r.name == 'Céphalée');
      final multipleHeadache = resultsMultiple.firstWhere((r) => r.name == 'Céphalée');

      expect(
        multipleHeadache.confidenceScore,
        greaterThan(simpleHeadache.confidenceScore),
      );
    });
  });

  group('Questions de clarification', () {
    test('Génère questions pour mal de tête sans intensité', () async {
      final data = MedicalData(
        hasHeadache: true,
        timestamp: DateTime.now(),
      );

      final questions = evaluator.getSuggestedQuestions(data);

      expect(questions.isNotEmpty, true);
      expect(
        questions.any((q) => q.toLowerCase().contains('intensité')),
        true,
      );
    });

    test('Génère questions pour fièvre', () async {
      final data = MedicalData(
        bodyTemperature: 39.0,
        timestamp: DateTime.now(),
      );

      final questions = evaluator.getSuggestedQuestions(data);

      expect(questions.isNotEmpty, true);
      expect(
        questions.any((q) => q.toLowerCase().contains('combien de temps')),
        true,
      );
    });

    test('Génère questions pour douleur thoracique', () async {
      final data = MedicalData(
        hasChestPain: true,
        timestamp: DateTime.now(),
      );

      final questions = evaluator.getSuggestedQuestions(data);

      expect(questions.isNotEmpty, true);
      expect(
        questions.any((q) => q.toLowerCase().contains('irradie')),
        true,
      );
    });

    test('Génère questions générales si peu de données', () async {
      final data = MedicalData(
        timestamp: DateTime.now(),
      );

      final questions = evaluator.getSuggestedQuestions(data);

      expect(questions.isNotEmpty, true);
      expect(questions.length, lessThanOrEqualTo(3));
    });
  });

  group('Cas négatifs', () {
    test('Aucun diagnostic si aucun symptôme', () async {
      final data = MedicalData(
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(results.isEmpty, true);
    });

    test('Ne détecte pas fièvre élevée si température normale', () async {
      final data = MedicalData(
        bodyTemperature: 37.0,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(
        results.any((r) => r.name.contains('Fièvre')),
        false,
      );
    });

    test('Ne détecte pas hémorragie si pas de saignement', () async {
      final data = MedicalData(
        hasBleeding: false,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);

      expect(
        results.any((r) => r.name.contains('Hémorragie')),
        false,
      );
    });
  });

  group('Opérateurs de conditions', () {
    test('Opérateur equals fonctionne', () async {
      final data = MedicalData(
        consciousness: 'inconscient',
        breathing: 'absente',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);
      expect(results.any((r) => r.name == 'Arrêt Cardiaque'), true);
    });

    test('Opérateur in fonctionne', () async {
      final data = MedicalData(
        hasBleeding: true,
        bleedingSeverity: 'artériel',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);
      expect(results.any((r) => r.name == 'Hémorragie Sévère'), true);
    });

    test('Opérateur lessThan fonctionne', () async {
      final data = MedicalData(
        bodyTemperature: 31.0,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);
      expect(results.any((r) => r.name == 'Hypothermie Sévère'), true);
    });

    test('Opérateur greaterThan fonctionne', () async {
      final data = MedicalData(
        bodyTemperature: 40.5,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);
      expect(results.any((r) => r.name == 'Fièvre Élevée'), true);
    });

    test('Opérateur between fonctionne', () async {
      final data = MedicalData(
        bodyTemperature: 38.5,
        hasHeadache: true,
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);
      expect(results.any((r) => r.name == 'Syndrome Grippal'), true);
    });

    test('Opérateur AND fonctionne', () async {
      final data = MedicalData(
        hasSwelling: true,
        swellingLocation: 'gorge',
        breathing: 'difficile',
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);
      expect(results.any((r) => r.name == 'Choc Anaphylactique'), true);
    });

    test('Opérateur OR fonctionne', () async {
      final data = MedicalData(
        hasNausea: true, // OR avec vomiting et abdominalPain
        timestamp: DateTime.now(),
      );

      final results = await evaluator.evaluate(data);
      expect(results.any((r) => r.name == 'Troubles Digestifs'), true);
    });
  });
}
