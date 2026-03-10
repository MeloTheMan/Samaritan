import 'package:equatable/equatable.dart';

abstract class AlertEvent extends Equatable {
  const AlertEvent();

  @override
  List<Object?> get props => [];
}

class StartAlertListening extends AlertEvent {
  const StartAlertListening();
}

class StopAlertListening extends AlertEvent {
  const StopAlertListening();
}

class AcknowledgeAlert extends AlertEvent {
  final String alertId;

  const AcknowledgeAlert(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class IgnoreAlert extends AlertEvent {
  final String alertId;

  const IgnoreAlert(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

class LoadActiveAlerts extends AlertEvent {
  const LoadActiveAlerts();
}

class LoadAlertHistory extends AlertEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadAlertHistory({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

class UpdateAlertLocation extends AlertEvent {
  final String alertId;
  final double userLatitude;
  final double userLongitude;

  const UpdateAlertLocation({
    required this.alertId,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  List<Object?> get props => [alertId, userLatitude, userLongitude];
}

class NavigateToVictim extends AlertEvent {
  final String alertId;

  const NavigateToVictim(this.alertId);

  @override
  List<Object?> get props => [alertId];
}
