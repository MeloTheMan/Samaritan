import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'vital_signs.g.dart';

@HiveType(typeId: 10)
class VitalSigns extends Equatable {
  @HiveField(0)
  final double temperature; // Body temperature in Celsius
  
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

  @HiveField(6)
  final double? ambientTemperature; // Ambient temperature in Celsius
  
  @HiveField(7)
  final double? humidity; // Relative humidity percentage
  
  @HiveField(8)
  final SensorStatus sensorStatus; // Which sensors are available

  const VitalSigns({
    required this.temperature,
    required this.heartRate,
    required this.oxygenSaturation,
    required this.timestamp,
    this.fallDetected = false,
    this.suddenMovement = false,
    this.ambientTemperature,
    this.humidity,
    this.sensorStatus = const SensorStatus(),
  });

  @override
  List<Object?> get props => [
        temperature,
        heartRate,
        oxygenSaturation,
        timestamp,
        fallDetected,
        suddenMovement,
        ambientTemperature,
        humidity,
        sensorStatus,
      ];

  VitalSigns copyWith({
    double? temperature,
    int? heartRate,
    int? oxygenSaturation,
    DateTime? timestamp,
    bool? fallDetected,
    bool? suddenMovement,
    double? ambientTemperature,
    double? humidity,
    SensorStatus? sensorStatus,
  }) {
    return VitalSigns(
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      oxygenSaturation: oxygenSaturation ?? this.oxygenSaturation,
      timestamp: timestamp ?? this.timestamp,
      fallDetected: fallDetected ?? this.fallDetected,
      suddenMovement: suddenMovement ?? this.suddenMovement,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      humidity: humidity ?? this.humidity,
      sensorStatus: sensorStatus ?? this.sensorStatus,
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
      'ambientTemperature': ambientTemperature,
      'humidity': humidity,
      'sensorStatus': sensorStatus.toJson(),
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
      ambientTemperature: json['ambientTemperature'] != null 
          ? (json['ambientTemperature'] as num).toDouble() 
          : null,
      humidity: json['humidity'] != null 
          ? (json['humidity'] as num).toDouble() 
          : null,
      sensorStatus: json['sensorStatus'] != null
          ? SensorStatus.fromJson(json['sensorStatus'] as Map<String, dynamic>)
          : const SensorStatus(),
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

@HiveType(typeId: 14)
class SensorStatus extends Equatable {
  @HiveField(0)
  final bool max30102Available; // HR, SpO2, Body temp sensor
  
  @HiveField(1)
  final bool mpu6050Available; // Fall detection sensor
  
  @HiveField(2)
  final bool dht11Available; // Ambient temp/humidity sensor

  const SensorStatus({
    this.max30102Available = true,
    this.mpu6050Available = true,
    this.dht11Available = true,
  });

  factory SensorStatus.fromByte(int statusByte) {
    return SensorStatus(
      max30102Available: (statusByte & 0x01) != 0,
      mpu6050Available: (statusByte & 0x02) != 0,
      dht11Available: (statusByte & 0x04) != 0,
    );
  }

  int toByte() {
    int byte = 0;
    if (max30102Available) byte |= 0x01;
    if (mpu6050Available) byte |= 0x02;
    if (dht11Available) byte |= 0x04;
    return byte;
  }

  Map<String, dynamic> toJson() {
    return {
      'max30102Available': max30102Available,
      'mpu6050Available': mpu6050Available,
      'dht11Available': dht11Available,
    };
  }

  factory SensorStatus.fromJson(Map<String, dynamic> json) {
    return SensorStatus(
      max30102Available: json['max30102Available'] as bool? ?? true,
      mpu6050Available: json['mpu6050Available'] as bool? ?? true,
      dht11Available: json['dht11Available'] as bool? ?? true,
    );
  }

  int get availableCount {
    int count = 0;
    if (max30102Available) count++;
    if (mpu6050Available) count++;
    if (dht11Available) count++;
    return count;
  }

  bool get allAvailable => availableCount == 3;
  bool get noneAvailable => availableCount == 0;

  @override
  List<Object?> get props => [
        max30102Available,
        mpu6050Available,
        dht11Available,
      ];
}
