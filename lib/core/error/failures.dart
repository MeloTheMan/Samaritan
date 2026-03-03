import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  List<Object?> get props => [message, code];
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message, 'NETWORK_ERROR');
}

class BluetoothFailure extends Failure {
  const BluetoothFailure(String message) : super(message, 'BLUETOOTH_ERROR');
}

class AuthenticationFailure extends Failure {
  const AuthenticationFailure(String message) : super(message, 'AUTH_ERROR');
}

class AIServiceFailure extends Failure {
  const AIServiceFailure(String message) : super(message, 'AI_ERROR');
}

class StorageFailure extends Failure {
  const StorageFailure(String message) : super(message, 'STORAGE_ERROR');
}

class PermissionFailure extends Failure {
  const PermissionFailure(String message) : super(message, 'PERMISSION_ERROR');
}

class LocationFailure extends Failure {
  const LocationFailure(String message) : super(message, 'LOCATION_ERROR');
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message, 'CACHE_ERROR');
}
