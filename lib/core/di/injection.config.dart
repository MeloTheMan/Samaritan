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
import 'package:hive_flutter/hive_flutter.dart' as _i986;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/ai_assistant/domain/services/rule_engine.dart' as _i122;
import '../../features/ai_assistant/domain/services/symptom_extractor.dart'
    as _i356;
import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart'
    as _i292;
import '../../features/training/data/repositories/training_repository_impl.dart'
    as _i550;
import '../../features/training/domain/repositories/training_repository.dart'
    as _i580;
import '../../features/training/presentation/bloc/training_bloc.dart' as _i669;
import '../network/network_info.dart' as _i932;
import '../services/authentication_service.dart' as _i551;
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
    gh.factory<_i356.SymptomExtractor>(() => _i356.SymptomExtractor());
    gh.lazySingleton<_i895.Connectivity>(() => injectionModule.connectivity);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
        () => injectionModule.secureStorage);
    gh.lazySingleton<_i152.LocalAuthentication>(
        () => injectionModule.localAuth);
    gh.lazySingleton<_i180.EncryptionService>(() => _i180.EncryptionService());
    gh.lazySingleton<_i165.PermissionService>(() => _i165.PermissionService());
    gh.lazySingleton<_i122.RuleEngine>(() => _i122.RuleEngine());
    gh.lazySingleton<_i580.TrainingRepository>(
        () => _i550.TrainingRepositoryImpl());
    gh.lazySingleton<_i932.NetworkInfo>(
        () => _i932.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.factory<_i669.TrainingBloc>(
        () => _i669.TrainingBloc(gh<_i580.TrainingRepository>()));
    gh.lazySingleton<_i535.SecureStorageService>(
        () => _i535.SecureStorageService(gh<_i558.FlutterSecureStorage>()));
    gh.factory<_i292.AIAssistantBloc>(() => _i292.AIAssistantBloc(
          ruleEngine: gh<_i122.RuleEngine>(),
          symptomExtractor: gh<_i356.SymptomExtractor>(),
        ));
    gh.lazySingleton<_i551.AuthenticationService>(
        () => _i551.AuthenticationService(
              gh<_i152.LocalAuthentication>(),
              gh<_i535.SecureStorageService>(),
            ));
    return this;
  }
}

class _$InjectionModule extends _i212.InjectionModule {}
