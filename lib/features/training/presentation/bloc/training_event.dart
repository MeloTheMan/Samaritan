import 'package:equatable/equatable.dart';

abstract class TrainingEvent extends Equatable {
  const TrainingEvent();

  @override
  List<Object?> get props => [];
}

class LoadCourses extends TrainingEvent {
  const LoadCourses();
}

class SelectCourse extends TrainingEvent {
  final String courseId;

  const SelectCourse(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

class MarkCourseCompleted extends TrainingEvent {
  final String courseId;

  const MarkCourseCompleted(this.courseId);

  @override
  List<Object?> get props => [courseId];
}

class FilterByCategory extends TrainingEvent {
  final String category;

  const FilterByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class SearchCourses extends TrainingEvent {
  final String query;

  const SearchCourses(this.query);

  @override
  List<Object?> get props => [query];
}

class UpdateProgress extends TrainingEvent {
  const UpdateProgress();
}
