import 'package:flutter_test/flutter_test.dart';
import 'package:samaritan/features/ai_assistant/domain/services/response_generator.dart';
import 'package:samaritan/features/ai_assistant/domain/entities/diagnostic_result.dart';
import 'package:samaritan/features/ai_assistant/domain/entities/medical_data.dart';

void main() {
  late ResponseGenerator generator;

  setUp(() {
    generator = ResponseGenerator();
  });

  group('Génération de réponses avec diagnostics', () {
    test('Génère une réponse pour diagnostic critique', () {
      final diagnosis = DiagnosticResult(
        id: 'test-001',
        name: 'Arrêt Cardiaque',
        description: 'Situation urgente',
        confidenceScore: 95,
        urgencyLevel: 'critique',
        recommendedActions: ['APPELER LE 15'],
      );

      final data = MedicalData(
        consciousness: 'inconscient',
        breathing: 'absente',
        timestamp: DateTime.now(),
      );

      final response = generator.generateResponse(
        diagnostics: [diagnosis],
        data: data,
      );

      expect(response, isNotEmpty);
      expect(response, contains('Arrêt Cardiaque'));
      expect(response, contains('95%'));
    });

    test('Génère une réponse pour diagnostic urgent', () {
      final diagnosis = DiagnosticResult(
        id: 'test-002',
        name: 'Fièvre Élevée',
        description: 'Température élevée',
        confidenceScore: 80,
        urgencyLevel: 'urgent',
        recommendedActions: ['Consulter'],
      );

      final data = MedicalData(
        bodyTemperature: 40.0,
        timestamp: DateTime.now(),
      );

      final response = generator.generateResponse(
        diagnostics: [diagnosis],
        data: data,
      );

      expect(response, isNotEmpty);
      expect(response, contains('Fièvre Élevée'));
    });
  });

  group('Cas sans diagnostic', () {
    test('Génère une réponse appropriée', () {
      final data = MedicalData(timestamp: DateTime.now());

      final response = generator.generateResponse(
        diagnostics: [],
        data: data,
      );

      expect(response, isNotEmpty);
      expect(response, contains('15'));
    });
  });

  group('Messages utilitaires', () {
    test('Génère un message de bienvenue', () {
      final message = generator.generateWelcomeMessage();
      expect(message, isNotEmpty);
    });

    test('Génère un message d\'erreur', () {
      final message = generator.generateErrorMessage();
      expect(message, isNotEmpty);
    });

    test('Génère un message d\'acquittement', () {
      final message = generator.generateAcknowledgment();
      expect(message, isNotEmpty);
    });
  });

  group('Variations', () {
    test('Génère des réponses variées', () {
      final diagnosis = DiagnosticResult(
        id: 'test-001',
        name: 'Test',
        description: 'Description',
        confidenceScore: 70,
        urgencyLevel: 'routine',
        recommendedActions: ['Action'],
      );

      final data = MedicalData(timestamp: DateTime.now());

      final responses = <String>{};
      for (var i = 0; i < 10; i++) {
        responses.add(generator.generateResponse(
          diagnostics: [diagnosis],
          data: data,
        ));
      }

      expect(responses.length, greaterThan(1));
    });
  });
}
