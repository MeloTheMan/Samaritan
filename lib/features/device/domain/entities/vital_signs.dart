import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'vital_signs.g.dart';

@HiveType(typeId: 10)
class VitalSigns extends Equatable {
  @HiveField(0)
  final double temperature; // Celsius
  
  @HiveField(1)
  final int heartRate; // BPM
  
  @HiveField(2)
  final int oxygenSaturation; // Percentage
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final bool fallDetected;
  
  @HiveField(5)
  final bool suddenMovement;

  const VitalSigns({
    required this.temperature,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.timestamp,
    this.fallDetected = false,
    this.suddenMovement = false,
  });

  @override
  List<Object?> get props => [
        temperature,
        heartRate,
        oxygenSaturation,
        timestamp,
        fallDetected,
        suddenMovement,
      ];

  VitalSigns copyWith({
    double? temperature,
    int? heartRate,
    int? oxygenSaturation,
    DateTime? timestamp,
    bool? fallDetected,
    bool? suddenMovement,
  }) {
    return VitalSigns(
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      timestamp: timestamp ?? this.timestamp,
      fallDetected: fallDetected ?? this.fallDetected,
      suddenMovement: suddenMovement ?? this.suddenMovement,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'heartRate': heartRate,
      'oxygenSaturation': oxygenSaturation,
      'timestamp': timestamp.toIso8601String(),
      'fallDetected': fallDetected,
      'suddenMovement': suddenMovement,
    };
  }

  factory VitalSigns.fromJson(Map<String, dynamic> json) {
    return VitalSigns(
      temperature: (json['temperature'] as num).toDouble(),
      heartRate: json['heartRate'] as int,
      oxygenSaturation: json['oxygenSaturation'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
      fallDetected: json['fallDetected'] as bool? ?? false,
      suddenMovement: json['suddenMovement'] as bool? ?? false,
    );
  }

  bool get isNormal {
    return temperature >= 36.0 &&
        temperature <= 37.5 &&
        heartRate >= 60 &&
        heartRate <= 100 &&
        oxygenSaturation >= 95;
  }

  bool get isCritical {
    return temperature < 35.0 ||
        temperature > 40.0 ||
        heartRate < 40 ||
        heartRate > 150 ||
        oxygenSaturation < 90 ||
        fallDetected;
  }
}
