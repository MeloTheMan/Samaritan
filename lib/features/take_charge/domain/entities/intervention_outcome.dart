import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'intervention_outcome.g.dart';

enum OutcomeType {
  resuscitated,      // Victime réanimée
  hospitalTransport, // Victime amenée à l'hôpital
  improved,          // État de santé meilleur
  stable,            // État de santé stable
  deteriorating,     // État de santé en dégradation
}

@HiveType(typeId: 25)
class InterventionOutcome extends Equatable {
  @HiveField(0)
  final OutcomeType type;

  @HiveField(1)
  final String notes;

  @HiveField(2)
  final DateTime recordedAt;

  @HiveField(3)
  final String? additionalDetails;

  const InterventionOutcome({
    required this.type,
    required this.notes,
    required this.recordedAt,
    this.additionalDetails,
  });

  String get displayName {
    switch (type) {
      case OutcomeType.resuscitated:
        return 'Victime réanimée';
      case OutcomeType.hospitalTransport:
        return 'Victime amenée à l\'hôpital';
      case OutcomeType.improved:
        return 'État de santé meilleur';
      case OutcomeType.stable:
        return 'État de santé stable';
      case OutcomeType.deteriorating:
        return 'État de santé en dégradation';
    }
  }

  @override
  List<Object?> get props => [type, notes, recordedAt, additionalDetails];
}
