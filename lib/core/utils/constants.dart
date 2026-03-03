class AppConstants {
  // Bluetooth
  static const String alertServiceUuid = '0000180d-0000-1000-8000-00805f9b34fb';
  static const String alertCharacteristicUuid = '00002a37-0000-1000-8000-00805f9b34fb';
  static const double alertProximityRadius = 100.0; // meters
  
  // Timeouts
  static const Duration bluetoothConnectionTimeout = Duration(seconds: 10);
  static const Duration aiResponseTimeout = Duration(seconds: 5);
  static const Duration reconnectionInterval = Duration(seconds: 5);
  
  // Performance
  static const Duration appStartupTimeout = Duration(seconds: 3);
  static const int vitalSignsUpdateFrequency = 1; // Hz
  
  // Storage
  static const String hiveBoxVitalSigns = 'vital_signs';
  static const String hiveBoxUserProfile = 'user_profile';
  static const String hiveBoxCourses = 'courses';
  static const String hiveBoxInterventions = 'interventions';
  
  // Security
  static const String encryptionAlgorithm = 'AES-256';
}
