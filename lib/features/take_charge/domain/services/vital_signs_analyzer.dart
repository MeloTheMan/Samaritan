import 'package:injectable/injectable.dart';
import '../../../device/domain/entities/vital_signs.dart';
import '../entities/prognosis.dart';

@injectable
class VitalSignsAnalyzer {
  // Seuils critiques pour l'analyse
  static const double criticalTempLow = 35.0;
  static const double criticalTempHigh = 40.0;
  static const int criticalHeartRateLow = 40;
  static const int criticalHeartRateHigh = 140;
  static const int criticalOxygenSaturation = 90;

  static const double seriousTempLow = 35.5;
  static const double seriousTempHigh = 39.0;
  static const int seriousHeartRateLow = 50;
  static const int seriousHeartRateHigh = 120;
  static const int seriousOxygenSaturation = 92;

  /// Analyse les signes vitaux et retourne un pronostic
  Prognosis analyzeVitalSigns(VitalSigns signs) {
    final criticalFactors = <CriticalFactor>[];
    PrognosisLevel level = PrognosisLevel.stable;

    // Analyse de la température
    if (signs.temperature < criticalTempLow || signs.temperature > criticalTempHigh) {
      level = PrognosisLevel.critical;
      criticalFactors.add(CriticalFactor(
        factor: 'Température',
        severity: 'high',
        description: signs.temperature < criticalTempLow
            ? 'Hypothermie sévère (${signs.temperature.toStringAsFixed(1)}°C)'
            : 'Hyperthermie sévère (${signs.temperature.toStringAsFixed(1)}°C)',
      ));
    } else if (signs.temperature < seriousTempLow || signs.temperature > seriousTempHigh) {
      if (level.index < PrognosisLevel.serious.index) {
        level = PrognosisLevel.serious;
      }
      criticalFactors.add(CriticalFactor(
        factor: 'Température',
        severity: 'medium',
        description: 'Température anormale (${signs.temperature.toStringAsFixed(1)}°C)',
      ));
    }

    // Analyse du rythme cardiaque
    if (signs.heartRate < criticalHeartRateLow || signs.heartRate > criticalHeartRateHigh) {
      level = PrognosisLevel.critical;
      criticalFactors.add(CriticalFactor(
        factor: 'Rythme cardiaque',
        severity: 'high',
        description: signs.heartRate < criticalHeartRateLow
            ? 'Bradycardie sévère (${signs.heartRate} BPM)'
            : 'Tachycardie sévère (${signs.heartRate} BPM)',
      ));
    } else if (signs.heartRate < seriousHeartRateLow || signs.heartRate > seriousHeartRateHigh) {
      if (level.index < PrognosisLevel.serious.index) {
        level = PrognosisLevel.serious;
      }
      criticalFactors.add(CriticalFactor(
        factor: 'Rythme cardiaque',
        severity: 'medium',
        description: 'Rythme cardiaque anormal (${signs.heartRate} BPM)',
      ));
    }

    // Analyse de la saturation en oxygène
    if (signs.oxygenSaturation < criticalOxygenSaturation) {
      level = PrognosisLevel.critical;
      criticalFactors.add(CriticalFactor(
        factor: 'Saturation en oxygène',
        severity: 'high',
        description: 'Hypoxie sévère (${signs.oxygenSaturation}%)',
      ));
    } else if (signs.oxygenSaturation < seriousOxygenSaturation) {
      if (level.index < PrognosisLevel.serious.index) {
        level = PrognosisLevel.serious;
      }
      criticalFactors.add(CriticalFactor(
        factor: 'Saturation en oxygène',
        severity: 'medium',
        description: 'Saturation basse (${signs.oxygenSaturation}%)',
      ));
    }

    // Détection de chute
    if (signs.fallDetected) {
      if (level.index < PrognosisLevel.moderate.index) {
        level = PrognosisLevel.moderate;
      }
      criticalFactors.add(const CriticalFactor(
        factor: 'Chute détectée',
        severity: 'medium',
        description: 'Chute récente détectée - risque de traumatisme',
      ));
    }

    final recommendations = _generateRecommendations(level, criticalFactors);
    final description = _generateDescription(level, criticalFactors);

    return Prognosis(
      level: level,
      description: description,
      criticalFactors: criticalFactors,
      initialRecommendations: recommendations,
      analyzedAt: DateTime.now(),
    );
  }

  List<String> _generateRecommendations(
    PrognosisLevel level,
    List<CriticalFactor> factors,
  ) {
    final recommendations = <String>[];

    switch (level) {
      case PrognosisLevel.critical:
        recommendations.add('⚠️ APPELER LES URGENCES IMMÉDIATEMENT (15 ou 112)');
        recommendations.add('Vérifier la conscience de la victime');
        recommendations.add('Libérer les voies respiratoires');
        
        if (factors.any((f) => f.factor == 'Rythme cardiaque')) {
          recommendations.add('Préparer une RCP si nécessaire');
        }
        if (factors.any((f) => f.factor == 'Saturation en oxygène')) {
          recommendations.add('Placer la victime en position latérale de sécurité si inconsciente');
        }
        break;

      case PrognosisLevel.serious:
        recommendations.add('Appeler les urgences (15 ou 112)');
        recommendations.add('Surveiller constamment les signes vitaux');
        recommendations.add('Rassurer la victime et la maintenir au calme');
        
        if (factors.any((f) => f.factor == 'Température')) {
          recommendations.add('Réguler la température corporelle');
        }
        break;

      case PrognosisLevel.moderate:
        recommendations.add('Surveiller l\'évolution des signes vitaux');
        recommendations.add('Maintenir la victime confortable');
        recommendations.add('Préparer à appeler les urgences si dégradation');
        
        if (factors.any((f) => f.factor == 'Chute détectée')) {
          recommendations.add('Vérifier les blessures visibles');
          recommendations.add('Ne pas déplacer si suspicion de fracture');
        }
        break;

      case PrognosisLevel.stable:
        recommendations.add('Continuer la surveillance');
        recommendations.add('Rassurer la victime');
        recommendations.add('Rester vigilant aux changements');
        break;
    }

    return recommendations;
  }

  String _generateDescription(
    PrognosisLevel level,
    List<CriticalFactor> factors,
  ) {
    if (factors.isEmpty) {
      return 'Signes vitaux dans les normes. État stable.';
    }

    final highSeverity = factors.where((f) => f.severity == 'high').length;
    final mediumSeverity = factors.where((f) => f.severity == 'medium').length;

    switch (level) {
      case PrognosisLevel.critical:
        return 'SITUATION CRITIQUE : $highSeverity facteur(s) critique(s) détecté(s). Intervention urgente requise.';
      case PrognosisLevel.serious:
        return 'Situation grave : $mediumSeverity anomalie(s) significative(s). Surveillance étroite nécessaire.';
      case PrognosisLevel.moderate:
        return 'Surveillance nécessaire : ${factors.length} facteur(s) à surveiller.';
      case PrognosisLevel.stable:
        return 'État stable avec surveillance recommandée.';
    }
  }
}
