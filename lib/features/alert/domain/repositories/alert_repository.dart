import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/emergency_alert.dart';

abstract class AlertRepository {
  /// Stream des alertes d'urgence reçues via BLE
  Stream<Either<Failure, EmergencyAlert>> getAlertStream();

  /// Marquer une alerte comme acquittée
  Future<Either<Failure, void>> acknowledgeAlert(String alertId);

  /// Ignorer une alerte
  Future<Either<Failure, void>> ignoreAlert(String alertId);

  /// Récupérer toutes les alertes actives
  Future<Either<Failure, List<EmergencyAlert>>> getActiveAlerts();

  /// Récupérer l'historique des alertes
  Future<Either<Failure, List<EmergencyAlert>>> getAlertHistory({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Mettre à jour le statut d'une alerte
  Future<Either<Failure, void>> updateAlertStatus(
    String alertId,
    AlertStatus status,
  );

  /// Calculer la distance et la direction vers une alerte
  Future<Either<Failure, EmergencyAlert>> updateAlertLocation(
    String alertId,
    double userLatitude,
    double userLongitude,
  );

  /// Sauvegarder une alerte
  Future<Either<Failure, void>> saveAlert(EmergencyAlert alert);

  /// Supprimer une alerte
  Future<Either<Failure, void>> deleteAlert(String alertId);
}
