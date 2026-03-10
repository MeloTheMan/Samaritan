import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../domain/entities/emergency_alert.dart';
import 'alert_event.dart';
import 'alert_state.dart';

@injectable
class AlertBloc extends Bloc<AlertEvent, AlertState> {
  final AlertRepository repository;
  
  List<EmergencyAlert> _activeAlerts = [];

  AlertBloc({required this.repository}) : super(const AlertInitial()) {
    on<StartAlertListening>(_onStartAlertListening);
    on<StopAlertListening>(_onStopAlertListening);
    on<AcknowledgeAlert>(_onAcknowledgeAlert);
    on<IgnoreAlert>(_onIgnoreAlert);
    on<LoadActiveAlerts>(_onLoadActiveAlerts);
    on<LoadAlertHistory>(_onLoadAlertHistory);
    on<UpdateAlertLocation>(_onUpdateAlertLocation);
    on<NavigateToVictim>(_onNavigateToVictim);
  }

  Future<void> _onStartAlertListening(
    StartAlertListening event,
    Emitter<AlertState> emit,
  ) async {
    emit(AlertListening(activeAlerts: _activeAlerts));
    
    try {
      await emit.forEach<Either<Failure, EmergencyAlert>>(
        repository.getAlertStream(),
        onData: (result) {
          return result.fold(
            (failure) => AlertError(
              message: failure.message,
              activeAlerts: _activeAlerts,
            ),
            (alert) {
              // Ajouter l'alerte à la liste active
              _activeAlerts = [..._activeAlerts, alert];
              
              return AlertReceived(
                alert: alert,
                activeAlerts: _activeAlerts,
              );
            },
          );
        },
        onError: (error, stackTrace) {
          return AlertError(
            message: error.toString(),
            activeAlerts: _activeAlerts,
          );
        },
      );
    } catch (e) {
      emit(AlertError(
        message: e.toString(),
        activeAlerts: _activeAlerts,
      ));
    }
  }

  Future<void> _onStopAlertListening(
    StopAlertListening event,
    Emitter<AlertState> emit,
  ) async {
    // Le stream sera automatiquement annulé par emit.forEach
    emit(AlertInitial());
  }

  Future<void> _onAcknowledgeAlert(
    AcknowledgeAlert event,
    Emitter<AlertState> emit,
  ) async {
    final result = await repository.acknowledgeAlert(event.alertId);
    
    result.fold(
      (failure) => emit(AlertError(
        message: failure.message,
        activeAlerts: _activeAlerts,
      )),
      (_) {
        // Mettre à jour la liste locale
        _activeAlerts = _activeAlerts
            .map((a) => a.alertId == event.alertId
                ? a.copyWith(status: AlertStatus.acknowledged)
                : a)
            .toList();
        
        emit(AlertAcknowledged(
          alertId: event.alertId,
          activeAlerts: _activeAlerts,
        ));
      },
    );
  }

  Future<void> _onIgnoreAlert(
    IgnoreAlert event,
    Emitter<AlertState> emit,
  ) async {
    final result = await repository.ignoreAlert(event.alertId);
    
    result.fold(
      (failure) => emit(AlertError(
        message: failure.message,
        activeAlerts: _activeAlerts,
      )),
      (_) {
        // Retirer de la liste active
        _activeAlerts = _activeAlerts
            .where((a) => a.alertId != event.alertId)
            .toList();
        
        emit(AlertIgnored(
          alertId: event.alertId,
          activeAlerts: _activeAlerts,
        ));
      },
    );
  }

  Future<void> _onLoadActiveAlerts(
    LoadActiveAlerts event,
    Emitter<AlertState> emit,
  ) async {
    final result = await repository.getActiveAlerts();
    
    result.fold(
      (failure) => emit(AlertError(
        message: failure.message,
        activeAlerts: _activeAlerts,
      )),
      (alerts) {
        _activeAlerts = alerts;
        emit(AlertListening(activeAlerts: alerts));
      },
    );
  }

  Future<void> _onLoadAlertHistory(
    LoadAlertHistory event,
    Emitter<AlertState> emit,
  ) async {
    final result = await repository.getAlertHistory(
      startDate: event.startDate,
      endDate: event.endDate,
    );
    
    result.fold(
      (failure) => emit(AlertError(
        message: failure.message,
        activeAlerts: _activeAlerts,
      )),
      (history) => emit(AlertHistoryLoaded(history: history)),
    );
  }

  Future<void> _onUpdateAlertLocation(
    UpdateAlertLocation event,
    Emitter<AlertState> emit,
  ) async {
    final result = await repository.updateAlertLocation(
      event.alertId,
      event.userLatitude,
      event.userLongitude,
    );
    
    result.fold(
      (failure) => emit(AlertError(
        message: failure.message,
        activeAlerts: _activeAlerts,
      )),
      (updatedAlert) {
        // Mettre à jour dans la liste locale
        _activeAlerts = _activeAlerts
            .map((a) => a.alertId == event.alertId ? updatedAlert : a)
            .toList();
        
        emit(AlertLocationUpdated(alert: updatedAlert));
      },
    );
  }

  Future<void> _onNavigateToVictim(
    NavigateToVictim event,
    Emitter<AlertState> emit,
  ) async {
    final alert = _activeAlerts.firstWhere(
      (a) => a.alertId == event.alertId,
      orElse: () => throw Exception('Alerte non trouvée'),
    );
    
    emit(AlertNavigating(alert: alert));
  }

  @override
  Future<void> close() async {
    return super.close();
  }
}
