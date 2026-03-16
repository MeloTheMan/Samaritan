// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:hive_flutter/hive_flutter.dart' as _i986;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/ai_assistant/domain/services/natural_language_processor.dart'
    as _i593;
import '../../features/ai_assistant/domain/services/response_generator.dart'
    as _i47;
import '../../features/ai_assistant/domain/services/rule_evaluator.dart'
    as _i1025;
import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart'
    as _i292;
import '../../features/alert/data/repositories/alert_repository_impl.dart'
    as _i318;
import '../../features/alert/data/services/alert_listener_service.dart' as _i43;
import '../../features/alert/domain/repositories/alert_repository.dart'
    as _i130;
import '../../features/alert/presentation/bloc/alert_bloc.dart' as _i1006;
import '../../features/device/data/repositories/device_repository_impl.dart'
    as _i740;
import '../../features/device/data/services/bluetooth_service.dart' as _i980;
import '../../features/device/domain/entities/device_settings.dart' as _i512;
import '../../features/device/domain/entities/vital_signs.dart' as _i757;
import '../../features/device/domain/repositories/device_repository.dart'
    as _i985;
import '../../features/device/presentation/bloc/device_bloc.dart' as _i1022;
import '../../features/take_charge/data/repositories/intervention_repository_impl.dart'
    as _i719;
import '../../features/take_charge/domain/repositories/intervention_repository.dart'
    as _i862;
import '../../features/take_charge/domain/services/vital_signs_analyzer.dart'
    as _i666;
import '../../features/take_charge/presentation/bloc/intervention_bloc.dart'
    as _i951;
import '../../features/training/data/repositories/training_repository_impl.dart'
    as _i550;
import '../../features/training/domain/repositories/training_repository.dart'
    as _i580;
import '../../features/training/presentation/bloc/training_bloc.dart' as _i669;
import '../network/network_info.dart' as _i932;
import '../services/authentication_service.dart' as _i551;
import '../services/demo_service.dart' as _i656;
import '../services/encryption_service.dart' as _i180;
import '../services/permission_service.dart' as _i165;
import '../services/secure_storage_service.dart' as _i535;
import 'injection_module.dart' as _i212;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final injectionModule = _$InjectionModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => injectionModule.sharedPreferences,
      preResolve: true,
    );
    await gh.factoryAsync<_i986.HiveInterface>(
      () => injectionModule.hive,
      preResolve: true,
    );
    await gh.factoryAsync<_i986.Box<_i512.DeviceSettings>>(
      () => injectionModule.deviceSettingsBox,
      preResolve: true,
    );
    await gh.factoryAsync<_i986.Box<_i757.VitalSigns>>(
      () => injectionModule.vitalSignsBox,
      preResolve: true,
    );
    await gh.factoryAsync<_i986.Box<String>>(
      () => injectionModule.connectedDeviceBox,
      preResolve: true,
    );
    gh.factory<_i593.NaturalLanguageProcessor>(
        () => _i593.NaturalLanguageProcessor());
    gh.factory<_i47.ResponseGenerator>(() => _i47.ResponseGenerator());
    gh.factory<_i666.VitalSignsAnalyzer>(() => _i666.VitalSignsAnalyzer());
    gh.factory<_i43.AlertListenerService>(() => _i43.AlertListenerService());
    gh.singleton<_i656.DemoService>(() => _i656.DemoService());
    gh.lazySingleton<_i895.Connectivity>(() => injectionModule.connectivity);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => injectionModule.secureStorage);
    gh.lazySingleton<_i152.LocalAuthentication>(
        () => injectionModule.localAuth);
    gh.lazySingleton<_i180.EncryptionService>(() => _i180.EncryptionService());
    gh.lazySingleton<_i165.PermissionService>(() => _i165.PermissionService());
    gh.lazySingleton<_i1025.RuleEvaluator>(() => _i1025.RuleEvaluator());
    gh.lazySingleton<_i980.BluetoothService>(() => _i980.BluetoothService());
    gh.lazySingleton<_i580.TrainingRepository>(
        () => _i550.TrainingRepositoryImpl());
    gh.factory<_i862.InterventionRepository>(
        () => _i719.InterventionRepositoryImpl(gh<_i666.VitalSignsAnalyzer>()));
    gh.lazySingleton<_i932.NetworkInfo>(
        () => _i932.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.factory<_i292.AIAssistantBloc>(() => _i292.AIAssistantBloc(
          nlp: gh<_i593.NaturalLanguageProcessor>(),
          evaluator: gh<_i1025.RuleEvaluator>(),
          responseGenerator: gh<_i47.ResponseGenerator>(),
        ));
    gh.factory<_i669.TrainingBloc>(
        () => _i669.TrainingBloc(gh<_i580.TrainingRepository>()));
    gh.lazySingleton<_i985.DeviceRepository>(() => _i740.DeviceRepositoryImpl(
          bluetoothService: gh<_i980.BluetoothService>(),
          settingsBox: gh<_i979.Box<_i512.DeviceSettings>>(),
          vitalSignsBox: gh<_i979.Box<_i757.VitalSigns>>(),
          connectedDeviceBox: gh<_i979.Box<String>>(),
        ));
    gh.lazySingleton<_i535.SecureStorageService>(
        () => _i535.SecureStorageService(gh<_i558.FlutterSecureStorage>()));
    gh.factory<_i130.AlertRepository>(
        () => _i318.AlertRepositoryImpl(gh<_i43.AlertListenerService>()));
    gh.lazySingleton<_i551.AuthenticationService>(
        () => _i551.AuthenticationService(
              gh<_i152.LocalAuthentication>(),
              gh<_i535.SecureStorageService>(),
            ));
    gh.factory<_i951.InterventionBloc>(() => _i951.InterventionBloc(
          repository: gh<_i862.InterventionRepository>(),
          deviceRepository: gh<_i985.DeviceRepository>(),
        ));
    gh.factory<_i1022.DeviceBloc>(
        () => _i1022.DeviceBloc(repository: gh<_i985.DeviceRepository>()));
    gh.factory<_i1006.AlertBloc>(
        () => _i1006.AlertBloc(repository: gh<_i130.AlertRepository>()));
    return this;
  }
}

class _$InjectionModule extends _i212.InjectionModule {}
