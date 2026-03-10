import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import '../../../device/domain/entities/vital_signs.dart';

part 'emergency_alert.g.dart';

enum AlertStatus {
  active,
  acknowledged,
  beingHandled,
  resolved,
  ignored,
}

@HiveType(typeId: 20)
class EmergencyAlert extends Equatable {
  @HiveField(0)
  final String alertId;

  @HiveField(1)
  final String victimDeviceId;

  @HiveField(2)
  final VitalSigns vitalSigns;

  @HiveField(3)
  final AlertLocation? estimatedLocation;

  @HiveField(4)
  final double? distance; // meters

  @HiveField(5)
  final double? bearing; // degrees (0-360)

  @HiveField(6)
  final AlertStatus status;

  @HiveField(7)
  final DateTime receivedAt;

  @HiveField(8)
  final String? handledByUserId;

  const EmergencyAlert({
    required this.alertId,
    required this.victimDeviceId,
    required this.vitalSigns,
    this.estimatedLocation,
    this.distance,
    this.bearing,
    required this.status,
    required this.receivedAt,
    this.handledByUserId,
  });

  EmergencyAlert copyWith({
    String? alertId,
    String? victimDeviceId,
    VitalSigns? vitalSigns,
    AlertLocation? estimatedLocation,
    double? distance,
    double? bearing,
    AlertStatus? status,
    DateTime? receivedAt,
    String? handledByUserId,
  }) {
    return EmergencyAlert(
      alertId: alertId ?? this.alertId,
      victimDeviceId: victimDeviceId ?? this.victimDeviceId,
      vitalSigns: vitalSigns ?? this.vitalSigns,
      estimatedLocation: estimatedLocation ?? this.estimatedLocation,
      distance: distance ?? this.distance,
      bearing: bearing ?? this.bearing,
      status: status ?? this.status,
      receivedAt: receivedAt ?? this.receivedAt,
      handledByUserId: handledByUserId ?? this.handledByUserId,
    );
  }

  @override
  List<Object?> get props => [
        alertId,
        victimDeviceId,
        vitalSigns,
        estimatedLocation,
        distance,
        bearing,
        status,
        receivedAt,
        handledByUserId,
      ];
}

@HiveType(typeId: 21)
class AlertLocation extends Equatable {
  @HiveField(0)
  final double latitude;

  @HiveField(1)
  final double longitude;

  @HiveField(2)
  final double? accuracy;

  const AlertLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracy];
}
