import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'quiz_question.dart';

part 'quiz.g.dart';

@HiveType(typeId: 6)
class Quiz extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String courseId;

  @HiveField(2)
  final List<QuizQuestion> questions;

  @HiveField(3)
  final int passingScore;

  const Quiz({
    required this.id,
    required this.courseId,
    required this.questions,
    this.passingScore = 70,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      courseId: json['courseId'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      passingScore: json['passingScore'] as int? ?? 70,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'questions': questions.map((e) => e.toJson()).toList(),
      'passingScore': passingScore,
    };
  }

  @override
  List<Object?> get props => [id, courseId, questions, passingScore];
}
