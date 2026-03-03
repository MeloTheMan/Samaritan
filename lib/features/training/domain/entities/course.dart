import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'course_step.dart';
import 'difficulty_level.dart';

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

  const Course({
    required this.id,
    required this.title,
    required this.category,
    required this.steps,
    required this.thumbnailUrl,
    required this.estimatedDuration,
    required this.difficulty,
    this.isCompleted = false,
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
      ];
}
