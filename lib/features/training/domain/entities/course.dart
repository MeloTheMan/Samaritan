import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'course_step.dart';
import 'difficulty_level.dart';
import 'quiz.dart';

part 'course.g.dart';

@HiveType(typeId: 0)
class Course extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final List<CourseStep> steps;

  @HiveField(4)
  final String thumbnailUrl;

  @HiveField(5)
  final Duration estimatedDuration;

  @HiveField(6)
  final DifficultyLevel difficulty;

  @HiveField(7)
  final bool isCompleted;

  @HiveField(8)
  final Quiz? quiz;

  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.steps,
    required this.thumbnailUrl,
    required this.estimatedDuration,
    required this.difficulty,
    this.isCompleted = false,
    this.quiz,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => CourseStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      thumbnailUrl: json['thumbnailUrl'] as String,
      estimatedDuration: Duration(minutes: json['estimatedDuration'] as int),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == json['difficulty'],
        orElse: () => DifficultyLevel.beginner,
      ),
      isCompleted: json['isCompleted'] as bool? ?? false,
      quiz: json['quiz'] != null
          ? Quiz.fromJson(json['quiz'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'steps': steps.map((e) => e.toJson()).toList(),
      'thumbnailUrl': thumbnailUrl,
      'estimatedDuration': estimatedDuration.inMinutes,
      'difficulty': difficulty.name,
      'isCompleted': isCompleted,
      'quiz': quiz?.toJson(),
    };
  }

  Course copyWith({
    String? id,
    String? title,
    String? category,
    List<CourseStep>? steps,
    String? thumbnailUrl,
    Duration? estimatedDuration,
    DifficultyLevel? difficulty,
    bool? isCompleted,
    Quiz? quiz,
  }) {
    return Course(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      steps: steps ?? this.steps,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      difficulty: difficulty ?? this.difficulty,
      isCompleted: isCompleted ?? this.isCompleted,
      quiz: quiz ?? this.quiz,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        steps,
        thumbnailUrl,
        estimatedDuration,
        difficulty,
        isCompleted,
        quiz,
      ];
}
