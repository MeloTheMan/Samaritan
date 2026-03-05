import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'quiz_result.g.dart';

@HiveType(typeId: 8)
class QuizResult extends Equatable {
  @HiveField(0)
  final String quizId;

  @HiveField(1)
  final int score;

  @HiveField(2)
  final int totalQuestions;

  @HiveField(3)
  final DateTime completedAt;

  @HiveField(4)
  final bool passed;

  const QuizResult({
    required this.quizId,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.passed,
  });

  int get percentage => ((score / totalQuestions) * 100).round();

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      quizId: json['quizId'] as String,
      score: json['score'] as int,
      totalQuestions: json['totalQuestions'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
      passed: json['passed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'score': score,
      'totalQuestions': totalQuestions,
      'completedAt': completedAt.toIso8601String(),
      'passed': passed,
    };
  }

  @override
  List<Object?> get props => [quizId, score, totalQuestions, completedAt, passed];
}
