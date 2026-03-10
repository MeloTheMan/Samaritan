import 'package:injectable/injectable.dart';
import '../entities/medical_data.dart';

/// Processeur de langage naturel pour extraire les données médicales du texte
@injectable
class NaturalLanguageProcessor {
  /// Extrait les données médicales d'un texte en langage naturel
  MedicalData extractFromText(String text) {
    // Normaliser le texte
    final normalized = _normalizeText(text);
    
    print('🔍 [NLP] Texte normalisé: "$normalized"');

    return MedicalData(
      // Données vitales
      bodyTemperature: _extractTemperature(normalized),
      heartRate: _extractHeartRate(normalized),
      spo2: _extractSpo2(normalized),
      
      // Indicateurs d'état
      consciousness: _extractConsciousness(normalized),
      breathing: _extractBreathing(normalized),
      speech: _extractSpeech(normalized),
      mobility: _extractMobility(normalized),
      
      // Événements
      hasFallen: _detectKeywords(normalized, _fallKeywords),
      hasConvulsions: _detectKeywords(normalized, _convulsionKeywords),
      isShivering: _detectKeywords(normalized, _shiveringKeywords),
      hasBleeding: _detectKeywords(normalized, _bleedingKeywords),
      bleedingSeverity: _extractBleedingSeverity(normalized),
      hasBurn: _detectKeywords(normalized, _burnKeywords),
      burnDegree: _extractBurnDegree(normalized),
      
      // Symptômes
      hasChestPain: _detectKeywords(normalized, _chestPainKeywords),
      hasHeadache: _detectKeywords(normalized, _headacheKeywords),
      headacheIntensity: _extractIntensity(normalized, _headacheKeywords),
      hasDizziness: _detectKeywords(normalized, _dizzinessKeywords),
      hasNausea: _detectKeywords(normalized, _nauseaKeywords),
      hasVomiting: _detectKeywords(normalized, _vomitingKeywords),
      hasAbdominalPain: _detectKeywords(normalized, _abdominalPainKeywords),
      hasSkinRash: _detectKeywords(normalized, _rashKeywords),
      hasSwelling: _detectKeywords(normalized, _swellingKeywords),
      swellingLocation: _extractSwellingLocation(normalized),
      hasCyanosis: _detectKeywords(normalized, _cyanosisKeywords),
      isPale: _detectKeywords(normalized, _palenessKeywords),
      hasColdSweats: _detectKeywords(normalized, _coldSweatsKeywords),
      
      dataSource: "user_prompt",
    );
  }

  /// Normalise le texte (minuscules, espaces multiples, accents)
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // ===== EXTRACTION DE VALEURS NUMÉRIQUES =====

  double? _extractTemperature(String text) {
    // Patterns: "38°", "38.5°C", "39C", "fièvre de 39", "température de 38"
    final patterns = [
      RegExp(r'(\d{2}(?:\.\d)?)\s*°[cf]?'),
      RegExp(r'(\d{2}(?:\.\d)?)\s*[cf](?:\s|$)'),
      RegExp(r'(?:fièvre|température|temp)\s+(?:de\s+)?(\d{2}(?:\.\d)?)'),
      RegExp(r'(\d{2}(?:\.\d)?)\s+(?:de\s+)?(?:fièvre|température)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final temp = double.tryParse(match.group(1)!);
        if (temp != null && temp >= 30 && temp <= 45) {
          print('🔍 [NLP] Température détectée: $temp°C');
          return temp;
        }
      }
    }

    // Mots-clés pour fièvre sans valeur
    if (_detectKeywords(text, ['fièvre', 'fiévreux', 'chaud'])) {
      print('🔍 [NLP] Fièvre détectée (valeur par défaut: 38.5°C)');
      return 38.5;
    }

    return null;
  }

  int? _extractHeartRate(String text) {
    // Patterns: "120 bpm", "cœur à 100", "pouls de 80"
    final patterns = [
      RegExp(r'(\d{2,3})\s*(?:bpm|battements)'),
      RegExp(r'(?:cœur|coeur|pouls)\s+(?:à|de|bat à)\s+(\d{2,3})'),
      RegExp(r'(\d{2,3})\s+(?:battements|pulsations)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final hr = int.tryParse(match.group(1)!);
        if (hr != null && hr >= 30 && hr <= 250) {
          print('🔍 [NLP] Fréquence cardiaque détectée: $hr bpm');
          return hr;
        }
      }
    }

    // Mots-clés pour tachycardie
    if (_detectKeywords(text, ['cœur bat vite', 'coeur bat vite', 'cœur rapide', 'coeur rapide', 'tachycardie', 'bat très vite'])) {
      print('🔍 [NLP] Tachycardie détectée (valeur par défaut: 120 bpm)');
      return 120;
    }

    return null;
  }

  int? _extractSpo2(String text) {
    // Patterns: "SpO2 à 95%", "saturation de 92"
    final patterns = [
      RegExp(r'spo2?\s+(?:à|de|:)?\s*(\d{2,3})'),
      RegExp(r'saturation\s+(?:à|de|:)?\s*(\d{2,3})'),
      RegExp(r'oxygène\s+(?:à|de|:)?\s*(\d{2,3})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final spo2 = int.tryParse(match.group(1)!);
        if (spo2 != null && spo2 >= 50 && spo2 <= 100) {
          print('🔍 [NLP] SpO2 détectée: $spo2%');
          return spo2;
        }
      }
    }

    return null;
  }

  // ===== EXTRACTION D'ÉTATS =====

  String _extractConsciousness(String text) {
    if (_detectKeywords(text, ['inconscient', 'évanoui', 'ne répond pas', 'sans connaissance'])) {
      return 'inconscient';
    }
    if (_detectKeywords(text, ['confus', 'désorienté', 'ne sait plus', 'perdu'])) {
      return 'confus';
    }
    if (_detectKeywords(text, ['somnolent', 'endormi', 'léthargique', 'assoupi'])) {
      return 'somnolent';
    }
    return 'normal';
  }

  String _extractBreathing(String text) {
    if (_detectKeywords(text, ['ne respire pas', 'arrêt respiratoire', 'respiration absente'])) {
      return 'absente';
    }
    if (_detectKeywords(text, [
      'difficulté à respirer',
      'difficile de respirer',
      'du mal à respirer',
      'essoufflé',
      'dyspnée',
      'manque d\'air',
      'manque d air',
      'souffle court',
      'respire mal',
      'peine à respirer'
    ])) {
      return 'difficile';
    }
    if (_detectKeywords(text, ['sifflement', 'respiration sifflante', 'siffle'])) {
      return 'sifflante';
    }
    return 'normal';
  }

  String _extractSpeech(String text) {
    if (_detectKeywords(text, ['ne peut pas parler', 'impossible de parler', 'muet'])) {
      return 'impossible';
    }
    if (_detectKeywords(text, [
      'parole difficile',
      'trouble de la parole',
      'parle mal',
      'parole pâteuse',
      'parole pateuse',
      'parole est pâteuse',
      'parole est pateuse',
      'articule mal'
    ])) {
      return 'difficile';
    }
    return 'normal';
  }

  String _extractMobility(String text) {
    if (_detectKeywords(text, [
      'paralysé',
      'paralysie',
      'ne peut pas bouger',
      'immobile',
      'bras paralysé',
      'jambe paralysée'
    ])) {
      return 'paralysie';
    }
    if (_detectKeywords(text, [
      'faiblesse',
      'bras faible',
      'jambe faible',
      'ne peut lever',
      'lourd'
    ])) {
      return 'faiblesse';
    }
    return 'normal';
  }

  // ===== EXTRACTION D'INTENSITÉ =====

  String? _extractIntensity(String text, List<String> contextKeywords) {
    // Vérifier d'abord si le symptôme est présent
    if (!_detectKeywords(text, contextKeywords)) {
      return null;
    }

    if (_detectKeywords(text, ['insupportable', 'atroce', 'pire', 'jamais eu aussi mal'])) {
      return 'insupportable';
    }
    if (_detectKeywords(text, ['intense', 'très', 'sévère', 'fort', 'violent'])) {
      return 'sévère';
    }
    if (_detectKeywords(text, ['modéré', 'moyen', 'assez'])) {
      return 'modéré';
    }
    if (_detectKeywords(text, ['léger', 'petit', 'peu'])) {
      return 'léger';
    }
    
    return 'modéré'; // Par défaut
  }

  String? _extractBleedingSeverity(String text) {
    if (!_detectKeywords(text, _bleedingKeywords)) {
      return null;
    }

    if (_detectKeywords(text, ['hémorragie', 'saigne beaucoup', 'sang abondant'])) {
      return 'sévère';
    }
    if (_detectKeywords(text, ['sang artériel', 'jaillit', 'gicle'])) {
      return 'artériel';
    }
    if (_detectKeywords(text, ['saignement léger', 'un peu de sang'])) {
      return 'léger';
    }
    
    return 'modéré';
  }

  String? _extractBurnDegree(String text) {
    if (!_detectKeywords(text, _burnKeywords)) {
      return null;
    }

    if (_detectKeywords(text, ['3ème degré', 'troisième degré', 'brûlure grave'])) {
      return '3ème';
    }
    if (_detectKeywords(text, ['2ème degré', 'deuxième degré', 'cloque', 'ampoule'])) {
      return '2ème';
    }
    
    return '1er';
  }

  String? _extractSwellingLocation(String text) {
    if (!_detectKeywords(text, _swellingKeywords)) {
      return null;
    }

    if (_detectKeywords(text, ['gonflement visage', 'visage gonflé', 'face gonflée'])) {
      return 'visage';
    }
    if (_detectKeywords(text, ['gorge gonflée', 'gonflement gorge', 'gorge est gonflée'])) {
      return 'gorge';
    }
    if (_detectKeywords(text, ['langue gonflée', 'gonflement langue'])) {
      return 'langue';
    }
    if (_detectKeywords(text, ['lèvres gonflées', 'gonflement lèvres'])) {
      return 'lèvres';
    }
    if (_detectKeywords(text, ['gonflement généralisé', 'tout gonflé', 'partout', 'gonflé partout'])) {
      return 'généralisé';
    }
    
    return null;
  }

  // ===== DÉTECTION DE MOTS-CLÉS =====

  bool _detectKeywords(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  // ===== DICTIONNAIRES DE MOTS-CLÉS =====

  static const _fallKeywords = ['tombé', 'chute', 'chu', 'est tombé'];
  
  static const _convulsionKeywords = ['convulsion', 'convulse', 'crise', 'spasme'];
  
  static const _shiveringKeywords = ['frisson', 'grelotte', 'tremble', 'tremblements'];
  
  static const _bleedingKeywords = [
    'saigne',
    'saignement',
    'sang',
    'hémorragie',
    'perd du sang'
  ];
  
  static const _burnKeywords = ['brûlure', 'brûlé', 'brulure', 'brule'];
  
  static const _chestPainKeywords = [
    'douleur poitrine',
    'douleur thoracique',
    'douleur à la poitrine',
    'mal poitrine',
    'mal à la poitrine',
    'mal au thorax',
    'oppression poitrine',
    'serrement poitrine',
    'douleur dans la poitrine'
  ];
  
  static const _headacheKeywords = [
    'mal de tête',
    'mal à la tête',
    'maux de tête',
    'mal de crâne',
    'céphalée',
    'migraine',
    'tête qui fait mal',
    'douleur tête'
  ];
  
  static const _dizzinessKeywords = [
    'vertige',
    'vertiges',
    'étourdi',
    'étourdissement',
    'tourne',
    'tête qui tourne'
  ];
  
  static const _nauseaKeywords = [
    'nausée',
    'nausées',
    'envie de vomir',
    'mal au cœur',
    'écœuré'
  ];
  
  static const _vomitingKeywords = ['vomi', 'vomissement', 'vomis', 'rendu'];
  
  static const _abdominalPainKeywords = [
    'mal au ventre',
    'mal de ventre',
    'douleur abdominale',
    'douleur au ventre',
    'ventre qui fait mal',
    'douleur estomac',
    'mal à l\'estomac'
  ];
  
  static const _rashKeywords = [
    'éruption',
    'plaques',
    'boutons',
    'urticaire',
    'rougeurs'
  ];
  
  static const _swellingKeywords = [
    'gonflement',
    'gonflé',
    'enflé',
    'œdème'
  ];
  
  static const _cyanosisKeywords = [
    'bleu',
    'bleue',
    'cyanose',
    'lèvres bleues',
    'peau bleue'
  ];
  
  static const _palenessKeywords = ['pâle', 'blanc', 'blême', 'pâleur'];
  
  static const _coldSweatsKeywords = [
    'sueurs froides',
    'transpiration froide',
    'transpire froid'
  ];
}
