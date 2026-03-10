import 'package:equatable/equatable.dart';
import '../../domain/entities/take_charge_session.dart';

abstract class InterventionState extends Equatable {
  const InterventionState();

  @override
  List<Object?> get props => [];
}

class InterventionInitial extends InterventionState {
  const InterventionInitial();
}

class InterventionConnecting extends InterventionState {
  final String victimDeviceId;

  const InterventionConnecting({required this.victimDeviceId});

  @override
  List<Object?> get props => [victimDeviceId];
}

class InterventionActive extends InterventionState {
  final TakeChargeSession session;

  const InterventionActive({required this.session});

  @override
  List<Object?> get props => [session];
}

class InterventionVitalSignsUpdated extends InterventionState {
  final TakeChargeSession session;

  const InterventionVitalSignsUpdated({required this.session});

  @override
  List<Object?> get props => [session];
}

class InterventionCareActionAdded extends InterventionState {
  final TakeChargeSession session;

  const InterventionCareActionAdded({required this.session});

  @override
  List<Object?> get props => [session];
}

class InterventionEnding extends InterventionState {
  final TakeChargeSession session;

  const InterventionEnding({required this.session});

  @override
  List<Object?> get props => [session];
}

class InterventionCompleted extends InterventionState {
  final TakeChargeSession session;

  const InterventionCompleted({required this.session});

  @override
  List<Object?> get props => [session];
}

class InterventionHistoryLoaded extends InterventionState {
  final List<TakeChargeSession> history;

  const InterventionHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class InterventionError extends InterventionState {
  final String message;
  final TakeChargeSession? session;

  const InterventionError({
    required this.message,
    this.session,
  });

  @override
  List<Object?> get props => [message, session];
}
