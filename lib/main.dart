import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di/injection.dart';
import 'core/presentation/screens/main_screen.dart';
import 'features/training/domain/entities/course.dart';
import 'features/training/domain/entities/course_step.dart';
import 'features/training/domain/entities/media_asset.dart';
import 'features/training/domain/entities/quiz.dart';
import 'features/training/domain/entities/quiz_question.dart';
import 'features/training/domain/entities/quiz_result.dart';
import 'features/training/domain/entities/hive_adapters.dart';
import 'features/device/domain/entities/vital_signs.dart';
import 'features/device/domain/entities/wearable_device.dart';
import 'features/device/domain/entities/device_settings.dart';
import 'features/device/presentation/screens/device_connection_screen.dart';
import 'features/device/presentation/screens/device_settings_screen.dart';
import 'features/device/presentation/screens/health_dashboard_screen.dart';
import 'features/device/presentation/bloc/device_bloc.dart';
import 'features/alert/domain/entities/emergency_alert.dart';
import 'features/alert/domain/entities/hive_adapters.dart' as alert_adapters;
import 'features/take_charge/domain/entities/prognosis.dart';
import 'features/take_charge/domain/entities/care_action.dart';
import 'features/take_charge/domain/entities/intervention_outcome.dart';
import 'features/take_charge/domain/entities/take_charge_session.dart';
import 'features/take_charge/domain/entities/hive_adapters.dart' as intervention_adapters;
import 'core/utils/hive_migration.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Migrate old incompatible data
  await HiveMigration.migrateVitalSignsData();
  
  // Register Hive adapters
  Hive.registerAdapter(CourseAdapter());
  Hive.registerAdapter(CourseStepAdapter());
  Hive.registerAdapter(MediaAssetAdapter());
  Hive.registerAdapter(QuizAdapter());
  Hive.registerAdapter(QuizQuestionAdapter());
  Hive.registerAdapter(QuizResultAdapter());
  Hive.registerAdapter(DifficultyLevelAdapter());
  Hive.registerAdapter(MediaTypeAdapter());
  Hive.registerAdapter(DurationAdapter());
  Hive.registerAdapter(DateTimeAdapter());
  
  // Register device adapters
  Hive.registerAdapter(VitalSignsAdapter());
  Hive.registerAdapter(SensorStatusAdapter());
  Hive.registerAdapter(ConnectionStatusAdapter());
  Hive.registerAdapter(WearableDeviceAdapter());
  Hive.registerAdapter(DeviceSettingsAdapter());
  
  // Register alert adapters
  Hive.registerAdapter(EmergencyAlertAdapter());
  Hive.registerAdapter(AlertLocationAdapter());
  Hive.registerAdapter(alert_adapters.AlertStatusAdapter());
  
  // Register intervention adapters
  Hive.registerAdapter(PrognosisAdapter());
  Hive.registerAdapter(CriticalFactorAdapter());
  Hive.registerAdapter(CareActionAdapter());
  Hive.registerAdapter(InterventionOutcomeAdapter());
  Hive.registerAdapter(TakeChargeSessionAdapter());
  Hive.registerAdapter(intervention_adapters.PrognosisLevelAdapter());
  Hive.registerAdapter(intervention_adapters.OutcomeTypeAdapter());
  
  // Configure dependency injection
  await configureDependencies();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const SamaritanApp());
}

class SamaritanApp extends StatelessWidget {
  const SamaritanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Samaritan Health Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: const MainScreen(),
      routes: {
        '/device-dashboard': (context) => BlocProvider(
              create: (context) => getIt<DeviceBloc>(),
              child: const HealthDashboardScreen(),
            ),
        '/device-connection': (context) => BlocProvider(
              create: (context) => getIt<DeviceBloc>(),
              child: const DeviceConnectionScreen(),
            ),
        '/device-settings': (context) => BlocProvider(
              create: (context) => getIt<DeviceBloc>(),
              child: const DeviceSettingsScreen(),
            ),
      },
    );
  }
}
