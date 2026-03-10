import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../../device/domain/entities/vital_signs.dart';
import 'prognosis.dart';
import 'care_action.dart';
import 'intervention_outcome.dart';

part 'take_charge_session.g.dart';

@HiveType(typeId: 26)
class TakeChargeSession extends Equatable {
  @HiveField(0)
  final String sessionId;

  @HiveField(1)
  final String victimDeviceId;

  @HiveField(2)
  final String volunteerId;

  @HiveField(3)
  final DateTime startTime;

  @HiveField(4)
  final DateTime? endTime;

  @HiveField(5)
  final Prognosis initialPrognosis;

  @HiveField(6)
  final List<VitalSigns> vitalSignsHistory;

  @HiveField(7)
  final List<CareAction> actionsPerformed;

  @HiveField(8)
  final InterventionOutcome? outcome;

  @HiveField(9)
  final String? alertId;

  const TakeChargeSession({
    required this.sessionId,
    required this.victimDeviceId,
    required this.volunteerId,
    required this.startTime,
    this.endTime,
    required this.initialPrognosis,
    required this.vitalSignsHistory,
    required this.actionsPerformed,
    this.outcome,
    this.alertId,
  });

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  bool get isActive => endTime == null;

  TakeChargeSession copyWith({
    String? sessionId,
    String? victimDeviceId,
    String? volunteerId,
    DateTime? startTime,
    DateTime? endTime,
    Prognosis? initialPrognosis,
    List<VitalSigns>? vitalSignsHistory,
    List<CareAction>? actionsPerformed,
    InterventionOutcome? outcome,
    String? alertId,
  }) {
    return TakeChargeSession(
      sessionId: sessionId ?? this.sessionId,
      victimDeviceId: victimDeviceId ?? this.victimDeviceId,
      volunteerId: volunteerId ?? this.volunteerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      initialPrognosis: initialPrognosis ?? this.initialPrognosis,
      vitalSignsHistory: vitalSignsHistory ?? this.vitalSignsHistory,
      actionsPerformed: actionsPerformed ?? this.actionsPerformed,
      outcome: outcome ?? this.outcome,
      alertId: alertId ?? this.alertId,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        victimDeviceId,
        volunteerId,
        startTime,
        endTime,
        initialPrognosis,
        vitalSignsHistory,
        actionsPerformed,
        outcome,
        alertId,
      ];
}
