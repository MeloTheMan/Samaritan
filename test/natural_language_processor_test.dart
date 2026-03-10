import 'package:flutter_test/flutter_test.dart';
import 'package:samaritan/features/ai_assistant/domain/services/natural_language_processor.dart';

void main() {
  late NaturalLanguageProcessor nlp;

  setUp(() {
    nlp = NaturalLanguageProcessor();
  });

  group('Extraction de température', () {
    test('Détecte température avec °C', () {
      final result = nlp.extractFromText("J'ai 39°C de fièvre");
      expect(result.bodyTemperature, 39.0);
    });

    test('Détecte température avec C', () {
      final result = nlp.extractFromText("J'ai 38.5C");
      expect(result.bodyTemperature, 38.5);
    });

    test('Détecte "fièvre de X"', () {
      final result = nlp.extractFromText("J'ai une fièvre de 40");
      expect(result.bodyTemperature, 40.0);
    });

    test('Détecte fièvre sans valeur (défaut 38.5)', () {
      final result = nlp.extractFromText("Je suis fiévreux");
      expect(result.bodyTemperature, 38.5);
    });

    test('Ne détecte pas de température invalide', () {
      final result = nlp.extractFromText("Il fait 25 degrés dehors");
      expect(result.bodyTemperature, null);
    });
  });

  group('Extraction de fréquence cardiaque', () {
    test('Détecte FC avec bpm', () {
      final result = nlp.extractFromText("Mon cœur bat à 120 bpm");
      expect(result.heartRate, 120);
    });

    test('Détecte "cœur à X"', () {
      final result = nlp.extractFromText("J'ai le cœur à 95");
      expect(result.heartRate, 95);
    });

    test('Détecte tachycardie (défaut 120)', () {
      final result = nlp.extractFromText("Mon cœur bat très vite");
      expect(result.heartRate, 120);
    });
  });

  group('Extraction de conscience', () {
    test('Détecte inconscient', () {
      final result = nlp.extractFromText("Il est inconscient");
      expect(result.consciousness, 'inconscient');
    });

    test('Détecte confus', () {
      final result = nlp.extractFromText("Elle est confuse et désorientée");
      expect(result.consciousness, 'confus');
    });

    test('Détecte somnolent', () {
      final result = nlp.extractFromText("Il est très somnolent");
      expect(result.consciousness, 'somnolent');
    });

    test('État normal par défaut', () {
      final result = nlp.extractFromText("Il va bien");
      expect(result.consciousness, 'normal');
    });
  });

  group('Extraction de respiration', () {
    test('Détecte respiration absente', () {
      final result = nlp.extractFromText("Il ne respire pas");
      expect(result.breathing, 'absente');
    });

    test('Détecte difficulté respiratoire', () {
      final result = nlp.extractFromText("J'ai du mal à respirer");
      expect(result.breathing, 'difficile');
    });

    test('Détecte respiration sifflante', () {
      final result = nlp.extractFromText("Ma respiration siffle");
      expect(result.breathing, 'sifflante');
    });

    test('Respiration normale par défaut', () {
      final result = nlp.extractFromText("Je respire normalement");
      expect(result.breathing, 'normal');
    });
  });

  group('Extraction de parole', () {
    test('Détecte parole impossible', () {
      final result = nlp.extractFromText("Il ne peut pas parler");
      expect(result.speech, 'impossible');
    });

    test('Détecte parole difficile', () {
      final result = nlp.extractFromText("Sa parole est pâteuse");
      expect(result.speech, 'difficile');
    });
  });

  group('Extraction de mobilité', () {
    test('Détecte paralysie', () {
      final result = nlp.extractFromText("Son bras est paralysé");
      expect(result.mobility, 'paralysie');
    });

    test('Détecte faiblesse', () {
      final result = nlp.extractFromText("J'ai une faiblesse dans la jambe");
      expect(result.mobility, 'faiblesse');
    });
  });

  group('Détection d\'événements', () {
    test('Détecte chute', () {
      final result = nlp.extractFromText("Il est tombé");
      expect(result.hasFallen, true);
    });

    test('Détecte convulsions', () {
      final result = nlp.extractFromText("Elle a des convulsions");
      expect(result.hasConvulsions, true);
    });

    test('Détecte frissons', () {
      final result = nlp.extractFromText("Je grelotte");
      expect(result.isShivering, true);
    });

    test('Détecte hémorragie avec sévérité', () {
      final result = nlp.extractFromText("Il saigne beaucoup");
      expect(result.hasBleeding, true);
      expect(result.bleedingSeverity, 'sévère');
    });

    test('Détecte brûlure avec degré', () {
      final result = nlp.extractFromText("Brûlure avec des cloques");
      expect(result.hasBurn, true);
      expect(result.burnDegree, '2ème');
    });
  });

  group('Détection de symptômes', () {
    test('Détecte douleur thoracique', () {
      final result = nlp.extractFromText("J'ai mal à la poitrine");
      expect(result.hasChestPain, true);
    });

    test('Détecte mal de tête avec intensité', () {
      final result = nlp.extractFromText("J'ai un mal de tête intense");
      expect(result.hasHeadache, true);
      expect(result.headacheIntensity, 'sévère');
    });

    test('Détecte vertiges', () {
      final result = nlp.extractFromText("J'ai des vertiges");
      expect(result.hasDizziness, true);
    });

    test('Détecte nausées', () {
      final result = nlp.extractFromText("J'ai envie de vomir");
      expect(result.hasNausea, true);
    });

    test('Détecte vomissements', () {
      final result = nlp.extractFromText("J'ai vomi");
      expect(result.hasVomiting, true);
    });

    test('Détecte douleur abdominale', () {
      final result = nlp.extractFromText("J'ai mal au ventre");
      expect(result.hasAbdominalPain, true);
    });

    test('Détecte éruption cutanée', () {
      final result = nlp.extractFromText("J'ai des plaques rouges");
      expect(result.hasSkinRash, true);
    });

    test('Détecte gonflement avec localisation', () {
      final result = nlp.extractFromText("Ma gorge est gonflée");
      expect(result.hasSwelling, true);
      expect(result.swellingLocation, 'gorge');
    });

    test('Détecte cyanose', () {
      final result = nlp.extractFromText("Ses lèvres sont bleues");
      expect(result.hasCyanosis, true);
    });

    test('Détecte pâleur', () {
      final result = nlp.extractFromText("Il est très pâle");
      expect(result.isPale, true);
    });

    test('Détecte sueurs froides', () {
      final result = nlp.extractFromText("J'ai des sueurs froides");
      expect(result.hasColdSweats, true);
    });
  });

  group('Cas complexes (multiples symptômes)', () {
    test('Cas 1: Fièvre + mal de tête', () {
      final result = nlp.extractFromText("J'ai 39°C de fièvre et mal à la tête");
      expect(result.bodyTemperature, 39.0);
      expect(result.hasHeadache, true);
    });

    test('Cas 2: Tachycardie + difficulté respiratoire', () {
      final result = nlp.extractFromText("Mon cœur bat à 130 et j'ai du mal à respirer");
      expect(result.heartRate, 130);
      expect(result.breathing, 'difficile');
    });

    test('Cas 3: Chute + hémorragie + inconscient', () {
      final result = nlp.extractFromText("Il est tombé, saigne beaucoup et est inconscient");
      expect(result.hasFallen, true);
      expect(result.hasBleeding, true);
      expect(result.bleedingSeverity, 'sévère');
      expect(result.consciousness, 'inconscient');
    });

    test('Cas 4: Douleur thoracique + pâleur + sueurs froides', () {
      final result = nlp.extractFromText("Douleur à la poitrine, il est pâle avec des sueurs froides");
      expect(result.hasChestPain, true);
      expect(result.isPale, true);
      expect(result.hasColdSweats, true);
    });

    test('Cas 5: Gonflement généralisé + difficulté respiratoire', () {
      final result = nlp.extractFromText("Gonflement partout et difficulté à respirer");
      expect(result.hasSwelling, true);
      expect(result.swellingLocation, 'généralisé');
      expect(result.breathing, 'difficile');
    });
  });

  group('Variations de formulation', () {
    test('Température - variations', () {
      expect(nlp.extractFromText("J'ai 38°").bodyTemperature, 38.0);
      expect(nlp.extractFromText("Température de 38.5").bodyTemperature, 38.5);
      expect(nlp.extractFromText("38 de fièvre").bodyTemperature, 38.0);
    });

    test('Mal de tête - variations', () {
      expect(nlp.extractFromText("J'ai mal de tête").hasHeadache, true);
      expect(nlp.extractFromText("Maux de tête").hasHeadache, true);
      expect(nlp.extractFromText("Céphalée").hasHeadache, true);
      expect(nlp.extractFromText("Migraine").hasHeadache, true);
    });

    test('Respiration - variations', () {
      expect(nlp.extractFromText("Essoufflé").breathing, 'difficile');
      expect(nlp.extractFromText("Manque d'air").breathing, 'difficile');
      expect(nlp.extractFromText("Souffle court").breathing, 'difficile');
    });
  });

  group('Cas négatifs (ne doit rien détecter)', () {
    test('Texte sans symptômes', () {
      final result = nlp.extractFromText("Je vais bien, tout va bien");
      expect(result.bodyTemperature, null);
      expect(result.heartRate, null);
      expect(result.hasHeadache, false);
      expect(result.hasChestPain, false);
    });

    test('Température ambiante (pas corporelle)', () {
      final result = nlp.extractFromText("Il fait 25 degrés");
      expect(result.bodyTemperature, null);
    });
  });
}
