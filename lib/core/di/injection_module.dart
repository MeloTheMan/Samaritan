import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/device/domain/entities/device_settings.dart';
import '../../features/device/domain/entities/vital_signs.dart';

@module
abstract class InjectionModule {
  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );

  @lazySingleton
  LocalAuthentication get localAuth => LocalAuthentication();

  @preResolve
  Future<SharedPreferences> get sharedPreferences =>
      SharedPreferences.getInstance();

  @preResolve
  Future<HiveInterface> get hive async {
    await Hive.initFlutter();
    return Hive;
  }
  
  @preResolve
  Future<Box<DeviceSettings>> get deviceSettingsBox async {
    return await Hive.openBox<DeviceSettings>('device_settings');
  }
  
  @preResolve
  Future<Box<VitalSigns>> get vitalSignsBox async {
    return await Hive.openBox<VitalSigns>('vital_signs');
  }
  
  @preResolve
  Future<Box<String>> get connectedDeviceBox async {
    return await Hive.openBox<String>('connected_device');
  }
}
