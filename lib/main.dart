import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
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
    );
  }
}
