import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'prognosis.g.dart';

enum PrognosisLevel {
  critical,    // Danger immédiat - intervention urgente
  serious,     // Situation grave - surveillance étroite
  moderate,    // Surveillance nécessaire
  stable,      // État stable
}

@HiveType(typeId: 22)
class Prognosis extends Equatable {
  @HiveField(0)
  final PrognosisLevel level;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final List<CriticalFactor> criticalFactors;

  @HiveField(3)
  final List<String> initialRecommendations;

  @HiveField(4)
  final DateTime analyzedAt;

  const Prognosis({
    required this.level,
    required this.description,
    required this.criticalFactors,
    required this.initialRecommendations,
    required this.analyzedAt,
  });

  @override
  List<Object?> get props => [
        level,
        description,
        criticalFactors,
        initialRecommendations,
        analyzedAt,
      ];
}

@HiveType(typeId: 23)
class CriticalFactor extends Equatable {
  @HiveField(0)
  final String factor;

  @HiveField(1)
  final String severity; // high, medium, low

  @HiveField(2)
  final String description;

  const CriticalFactor({
    required this.factor,
    required this.severity,
    required this.description,
  });

  @override
  List<Object?> get props => [factor, severity, description];
}
