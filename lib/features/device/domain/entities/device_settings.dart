import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'device_settings.g.dart';

@HiveType(typeId: 13)
class DeviceSettings extends Equatable {
  @HiveField(0)
  final double temperatureThresholdMin;
  
  @HiveField(1)
  final double temperatureThresholdMax;
  
  @HiveField(2)
  final int heartRateThresholdMin;
  
  @HiveField(3)
  final int heartRateThresholdMax;
  
  @HiveField(4)
  final int oxygenSaturationThresholdMin;
  
  @HiveField(5)
  final int measurementFrequency; // seconds
  
  @HiveField(6)
  final bool fallDetectionEnabled;
  
  @HiveField(7)
  final bool alertsEnabled;
  
  @HiveField(8)
  final bool vibrationEnabled;

  const DeviceSettings({
    this.temperatureThresholdMin = 35.0,
    this.temperatureThresholdMax = 38.0,
    this.heartRateThresholdMin = 50,
    this.heartRateThresholdMax = 120,
    this.oxygenSaturationThresholdMin = 90,
    this.measurementFrequency = 1,
    this.fallDetectionEnabled = true,
    this.alertsEnabled = true,
    this.vibrationEnabled = true,
  });

  @override
  List<Object?> get props => [
        temperatureThresholdMin,
        temperatureThresholdMax,
        heartRateThresholdMin,
        heartRateThresholdMax,
        oxygenSaturationThresholdMin,
        measurementFrequency,
        fallDetectionEnabled,
        alertsEnabled,
        vibrationEnabled,
      ];

  DeviceSettings copyWith({
    double? temperatureThresholdMin,
    double? temperatureThresholdMax,
    int? heartRateThresholdMin,
    int? heartRateThresholdMax,
    int? oxygenSaturationThresholdMin,
    int? measurementFrequency,
    bool? fallDetectionEnabled,
    bool? alertsEnabled,
    bool? vibrationEnabled,
  }) {
    return DeviceSettings(
      temperatureThresholdMin: temperatureThresholdMin ?? this.temperatureThresholdMin,
      temperatureThresholdMax: temperatureThresholdMax ?? this.temperatureThresholdMax,
      heartRateThresholdMin: heartRateThresholdMin ?? this.heartRateThresholdMin,
      heartRateThresholdMax: heartRateThresholdMax ?? this.heartRateThresholdMax,
      oxygenSaturationThresholdMin: oxygenSaturationThresholdMin ?? this.oxygenSaturationThresholdMin,
      measurementFrequency: measurementFrequency ?? this.measurementFrequency,
      fallDetectionEnabled: fallDetectionEnabled ?? this.fallDetectionEnabled,
      alertsEnabled: alertsEnabled ?? this.alertsEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperatureThresholdMin': temperatureThresholdMin,
      'temperatureThresholdMax': temperatureThresholdMax,
      'heartRateThresholdMin': heartRateThresholdMin,
      'heartRateThresholdMax': heartRateThresholdMax,
      'oxygenSaturationThresholdMin': oxygenSaturationThresholdMin,
      'measurementFrequency': measurementFrequency,
      'fallDetectionEnabled': fallDetectionEnabled,
      'alertsEnabled': alertsEnabled,
      'vibrationEnabled': vibrationEnabled,
    };
  }

  factory DeviceSettings.fromJson(Map<String, dynamic> json) {
    return DeviceSettings(
      temperatureThresholdMin: (json['temperatureThresholdMin'] as num?)?.toDouble() ?? 35.0,
      temperatureThresholdMax: (json['temperatureThresholdMax'] as num?)?.toDouble() ?? 38.0,
      heartRateThresholdMin: json['heartRateThresholdMin'] as int? ?? 50,
      heartRateThresholdMax: json['heartRateThresholdMax'] as int? ?? 120,
      oxygenSaturationThresholdMin: json['oxygenSaturationThresholdMin'] as int? ?? 90,
      measurementFrequency: json['measurementFrequency'] as int? ?? 1,
      fallDetectionEnabled: json['fallDetectionEnabled'] as bool? ?? true,
      alertsEnabled: json['alertsEnabled'] as bool? ?? true,
      vibrationEnabled: json['vibrationEnabled'] as bool? ?? true,
    );
  }

  factory DeviceSettings.defaultSettings() {
    return const DeviceSettings();
  }

  bool isTemperatureNormal(double temperature) {
    return temperature >= temperatureThresholdMin && 
           temperature <= temperatureThresholdMax;
  }

  bool isHeartRateNormal(int heartRate) {
    return heartRate >= heartRateThresholdMin && 
           heartRate <= heartRateThresholdMax;
  }

  bool isOxygenSaturationNormal(int oxygenSaturation) {
    return oxygenSaturation >= oxygenSaturationThresholdMin;
  }
}
