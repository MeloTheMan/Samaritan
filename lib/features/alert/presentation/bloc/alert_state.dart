import 'package:equatable/equatable.dart';
import '../../domain/entities/emergency_alert.dart';

abstract class AlertState extends Equatable {
  const AlertState();

  @override
  List<Object?> get props => [];
}

class AlertInitial extends AlertState {
  const AlertInitial();
}

class AlertListening extends AlertState {
  final List<EmergencyAlert> activeAlerts;

  const AlertListening({this.activeAlerts = const []});

  @override
  List<Object?> get props => [activeAlerts];
}

class AlertReceived extends AlertState {
  final EmergencyAlert alert;
  final List<EmergencyAlert> activeAlerts;

  const AlertReceived({
    required this.alert,
    required this.activeAlerts,
  });

  @override
  List<Object?> get props => [alert, activeAlerts];
}

class AlertNavigating extends AlertState {
  final EmergencyAlert alert;

  const AlertNavigating({required this.alert});

  @override
  List<Object?> get props => [alert];
}

class AlertAcknowledged extends AlertState {
  final String alertId;
  final List<EmergencyAlert> activeAlerts;

  const AlertAcknowledged({
    required this.alertId,
    required this.activeAlerts,
  });

  @override
  List<Object?> get props => [alertId, activeAlerts];
}

class AlertIgnored extends AlertState {
  final String alertId;
  final List<EmergencyAlert> activeAlerts;

  const AlertIgnored({
    required this.alertId,
    required this.activeAlerts,
  });

  @override
  List<Object?> get props => [alertId, activeAlerts];
}

class AlertHistoryLoaded extends AlertState {
  final List<EmergencyAlert> history;

  const AlertHistoryLoaded({required this.history});

  @override
  List<Object?> get props => [history];
}

class AlertLocationUpdated extends AlertState {
  final EmergencyAlert alert;

  const AlertLocationUpdated({required this.alert});

  @override
  List<Object?> get props => [alert];
}

class AlertError extends AlertState {
  final String message;
  final List<EmergencyAlert>? activeAlerts;

  const AlertError({
    required this.message,
    this.activeAlerts,
  });

  @override
  List<Object?> get props => [message, activeAlerts];
}
