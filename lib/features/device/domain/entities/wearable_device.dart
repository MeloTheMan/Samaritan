import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'vital_signs.dart';

part 'wearable_device.g.dart';

@HiveType(typeId: 11)
enum ConnectionStatus {
  @HiveField(0)
  disconnected,
  @HiveField(1)
  connecting,
  @HiveField(2)
  connected,
  @HiveField(3)
  error,
}

@HiveType(typeId: 12)
class WearableDevice extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String firmwareVersion;
  
  @HiveField(3)
  final int batteryLevel;
  
  @HiveField(4)
  final ConnectionStatus status;
  
  @HiveField(5)
  final VitalSigns? currentVitalSigns;
  
  @HiveField(6)
  final DateTime? lastConnected;
  
  @HiveField(7)
  final int signalStrength; // RSSI value

  const WearableDevice({
    required this.id,
    required this.name,
    required this.firmwareVersion,
    required this.batteryLevel,
    required this.status,
    this.currentVitalSigns,
    this.lastConnected,
    this.signalStrength = 0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        firmwareVersion,
        batteryLevel,
        status,
        currentVitalSigns,
        lastConnected,
        signalStrength,
      ];

  WearableDevice copyWith({
    String? id,
    String? name,
    String? firmwareVersion,
    int? batteryLevel,
    ConnectionStatus? status,
    VitalSigns? currentVitalSigns,
    DateTime? lastConnected,
    int? signalStrength,
  }) {
    return WearableDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      status: status ?? this.status,
      currentVitalSigns: currentVitalSigns ?? this.currentVitalSigns,
      lastConnected: lastConnected ?? this.lastConnected,
      signalStrength: signalStrength ?? this.signalStrength,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'firmwareVersion': firmwareVersion,
      'batteryLevel': batteryLevel,
      'status': status.name,
      'currentVitalSigns': currentVitalSigns?.toJson(),
      'lastConnected': lastConnected?.toIso8601String(),
      'signalStrength': signalStrength,
    };
  }

  factory WearableDevice.fromJson(Map<String, dynamic> json) {
    return WearableDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      firmwareVersion: json['firmwareVersion'] as String,
      batteryLevel: json['batteryLevel'] as int,
      status: ConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ConnectionStatus.disconnected,
      ),
      currentVitalSigns: json['currentVitalSigns'] != null
          ? VitalSigns.fromJson(json['currentVitalSigns'] as Map<String, dynamic>)
          : null,
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
      signalStrength: json['signalStrength'] as int? ?? 0,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  
  bool get needsBatteryCharge => batteryLevel < 20;
  
  String get signalQuality {
    if (signalStrength >= -50) return 'Excellent';
    if (signalStrength >= -60) return 'Good';
    if (signalStrength >= -70) return 'Fair';
    return 'Poor';
  }
}
