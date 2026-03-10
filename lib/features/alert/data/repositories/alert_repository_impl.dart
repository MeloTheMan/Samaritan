import 'package:dartz/dartz.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'dart:math' as math;
import '../../../../core/error/failures.dart';
import '../../domain/entities/emergency_alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../services/alert_listener_service.dart';

@Injectable(as: AlertRepository)
class AlertRepositoryImpl implements AlertRepository {
  final AlertListenerService _alertListenerService;
  static const String _alertBoxName = 'alerts';
  
  Box<EmergencyAlert>? _alertBox;

  AlertRepositoryImpl(this._alertListenerService);

  Future<Box<EmergencyAlert>> get _box async {
    if (_alertBox == null || !_alertBox!.isOpen) {
      _alertBox = await Hive.openBox<EmergencyAlert>(_alertBoxName);
    }
    return _alertBox!;
  }

  @override
  Stream<Either<Failure, EmergencyAlert>> getAlertStream() async* {
    try {
      final alertStream = _alertListenerService.startListening();
      
      await for (final alert in alertStream) {
        // Sauvegarder l'alerte
        await saveAlert(alert);
        yield Right(alert);
      }
    } catch (e) {
      yield Left(BluetoothFailure('Erreur lors de l\'écoute des alertes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> acknowledgeAlert(String alertId) async {
    try {
      return await updateAlertStatus(alertId, AlertStatus.acknowledged);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de l\'acquittement: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> ignoreAlert(String alertId) async {
    try {
      return await updateAlertStatus(alertId, AlertStatus.ignored);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de l\'ignorance: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<EmergencyAlert>>> getActiveAlerts() async {
    try {
      final box = await _box;
      final alerts = box.values
          .where((alert) => 
              alert.status == AlertStatus.active || 
              alert.status == AlertStatus.acknowledged)
          .toList();
      
      // Trier par date de réception (plus récent en premier)
      alerts.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      
      return Right(alerts);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la récupération des alertes: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<EmergencyAlert>>> getAlertHistory({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final box = await _box;
      var alerts = box.values.toList();
      
      if (startDate != null) {
        alerts = alerts.where((a) => a.receivedAt.isAfter(startDate)).toList();
      }
      
      if (endDate != null) {
        alerts = alerts.where((a) => a.receivedAt.isBefore(endDate)).toList();
      }
      
      // Trier par date (plus récent en premier)
      alerts.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      
      return Right(alerts);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la récupération de l\'historique: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateAlertStatus(
    String alertId,
    AlertStatus status,
  ) async {
    try {
      final box = await _box;
      final alert = box.values.firstWhere(
        (a) => a.alertId == alertId,
        orElse: () => throw Exception('Alerte non trouvée'),
      );
      
      final updatedAlert = alert.copyWith(status: status);
      await box.put(alertId, updatedAlert);
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la mise à jour: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, EmergencyAlert>> updateAlertLocation(
    String alertId,
    double userLatitude,
    double userLongitude,
  ) async {
    try {
      final box = await _box;
      final alert = box.values.firstWhere(
        (a) => a.alertId == alertId,
        orElse: () => throw Exception('Alerte non trouvée'),
      );
      
      if (alert.estimatedLocation == null) {
        return Right(alert);
      }
      
      // Calculer la distance et la direction
      final distance = _calculateDistance(
        userLatitude,
        userLongitude,
        alert.estimatedLocation!.latitude,
        alert.estimatedLocation!.longitude,
      );
      
      final bearing = _calculateBearing(
        userLatitude,
        userLongitude,
        alert.estimatedLocation!.latitude,
        alert.estimatedLocation!.longitude,
      );
      
      final updatedAlert = alert.copyWith(
        distance: distance,
        bearing: bearing,
      );
      
      await box.put(alertId, updatedAlert);
      
      return Right(updatedAlert);
    } catch (e) {
      return Left(CacheFailure('Erreur lors du calcul de position: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAlert(EmergencyAlert alert) async {
    try {
      final box = await _box;
      await box.put(alert.alertId, alert);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la sauvegarde: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAlert(String alertId) async {
    try {
      final box = await _box;
      await box.delete(alertId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Erreur lors de la suppression: ${e.toString()}'));
    }
  }

  /// Calcule la distance en mètres entre deux points GPS (formule de Haversine)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0; // mètres
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  /// Calcule la direction (bearing) en degrés entre deux points GPS
  double _calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);
    
    final y = math.sin(dLon) * math.cos(lat2Rad);
    final x = math.cos(lat1Rad) * math.sin(lat2Rad) -
        math.sin(lat1Rad) * math.cos(lat2Rad) * math.cos(dLon);
    
    final bearing = math.atan2(y, x);
    
    // Convertir en degrés et normaliser (0-360)
    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180.0;
  double _toDegrees(double radians) => radians * 180.0 / math.pi;
}
