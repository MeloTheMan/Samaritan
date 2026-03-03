import 'package:equatable/equatable.dart';
import '../../domain/entities/course.dart';

abstract class TrainingState extends Equatable {
  const TrainingState();

  @override
  List<Object?> get props => [];
}

class TrainingInitial extends TrainingState {
  const TrainingInitial();
}

class TrainingLoading extends TrainingState {
  const TrainingLoading();
}

class TrainingLoaded extends TrainingState {
  final List<Course> courses;
  final List<String> categories;
  final double overallProgress;
  final String? selectedCategory;
  final String? searchQuery;

  const TrainingLoaded({
    required this.courses,
    required this.categories,
    required this.overallProgress,
    this.selectedCategory,
    this.searchQuery,
  });

  @override
  List<Object?> get props => [
        courses,
        categories,
        overallProgress,
        selectedCategory,
        searchQuery,
      ];

  TrainingLoaded copyWith({
    List<Course>? courses,
    List<String>? categories,
    double? overallProgress,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return TrainingLoaded(
      courses: courses ?? this.courses,
      categories: categories ?? this.categories,
      overallProgress: overallProgress ?? this.overallProgress,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class CourseSelected extends TrainingState {
  final Course course;

  const CourseSelected(this.course);

  @override
  List<Object?> get props => [course];
}

class TrainingError extends TrainingState {
  final String message;

  const TrainingError(this.message);

  @override
  List<Object?> get props => [message];
}
