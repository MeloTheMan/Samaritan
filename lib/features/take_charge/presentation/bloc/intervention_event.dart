import 'package:equatable/equatable.dart';
import '../../domain/entities/care_action.dart';
import '../../domain/entities/intervention_outcome.dart';
import '../../../device/domain/entities/vital_signs.dart';

abstract class InterventionEvent extends Equatable {
  const InterventionEvent();

  @override
  List<Object?> get props => [];
}

class InitiateTakeCharge extends InterventionEvent {
  final String victimDeviceId;
  final String volunteerId;
  final String alertId;

  const InitiateTakeCharge({
    required this.victimDeviceId,
    required this.volunteerId,
    required this.alertId,
  });

  @override
  List<Object?> get props => [victimDeviceId, volunteerId, alertId];
}

class LoadActiveSession extends InterventionEvent {
  const LoadActiveSession();
}

class AddCareAction extends InterventionEvent {
  final CareAction action;

  const AddCareAction(this.action);

  @override
  List<Object?> get props => [action];
}

class UpdateVitalSigns extends InterventionEvent {
  final VitalSigns vitalSigns;

  const UpdateVitalSigns(this.vitalSigns);

  @override
  List<Object?> get props => [vitalSigns];
}

class EndIntervention extends InterventionEvent {
  final InterventionOutcome outcome;

  const EndIntervention(this.outcome);

  @override
  List<Object?> get props => [outcome];
}

class LoadInterventionHistory extends InterventionEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadInterventionHistory({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class RefineWithAI extends InterventionEvent {
  final String additionalContext;

  const RefineWithAI(this.additionalContext);

  @override
  List<Object?> get props => [additionalContext];
}
