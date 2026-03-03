import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/training_repository.dart';
import 'training_event.dart';
import 'training_state.dart';

@injectable
class TrainingBloc extends Bloc<TrainingEvent, TrainingState> {
  final TrainingRepository repository;

  TrainingBloc(this.repository) : super(const TrainingInitial()) {
    on<LoadCourses>(_onLoadCourses);
    on<SelectCourse>(_onSelectCourse);
    on<MarkCourseCompleted>(_onMarkCourseCompleted);
    on<FilterByCategory>(_onFilterByCategory);
    on<SearchCourses>(_onSearchCourses);
    on<UpdateProgress>(_onUpdateProgress);
  }

  Future<void> _onLoadCourses(
    LoadCourses event,
    Emitter<TrainingState> emit,
  ) async {
    emit(const TrainingLoading());

    final coursesResult = await repository.getAllCourses();
    final categoriesResult = await repository.getCategories();
    final progressResult = await repository.getOverallProgress();

    coursesResult.fold(
      (failure) => emit(TrainingError(failure.message)),
      (courses) {
        categoriesResult.fold(
          (failure) => emit(TrainingError(failure.message)),
          (categories) {
            progressResult.fold(
              (failure) => emit(TrainingError(failure.message)),
              (progress) {
                emit(TrainingLoaded(
                  courses: courses,
                  categories: categories,
                  overallProgress: progress,
                ));
              },
            );
          },
        );
      },
    );
  }

  Future<void> _onSelectCourse(
    SelectCourse event,
    Emitter<TrainingState> emit,
  ) async {
    final courseResult = await repository.getCourseById(event.courseId);

    courseResult.fold(
      (failure) => emit(TrainingError(failure.message)),
      (course) => emit(CourseSelected(course)),
    );
  }

  Future<void> _onMarkCourseCompleted(
    MarkCourseCompleted event,
    Emitter<TrainingState> emit,
  ) async {
    final result = await repository.markCourseAsCompleted(event.courseId);

    result.fold(
      (failure) => emit(TrainingError(failure.message)),
      (_) {
        // Reload courses to update completion status
        add(const LoadCourses());
      },
    );
  }

  Future<void> _onFilterByCategory(
    FilterByCategory event,
    Emitter<TrainingState> emit,
  ) async {
    if (state is TrainingLoaded) {
      emit(const TrainingLoading());

      final coursesResult = await repository.getCoursesByCategory(event.category);
      final progressResult = await repository.getOverallProgress();

      coursesResult.fold(
        (failure) => emit(TrainingError(failure.message)),
        (courses) {
          progressResult.fold(
            (failure) => emit(TrainingError(failure.message)),
            (progress) {
              final currentState = state as TrainingLoaded;
              emit(TrainingLoaded(
                courses: courses,
                categories: currentState.categories,
                overallProgress: progress,
                selectedCategory: event.category,
              ));
            },
          );
        },
      );
    }
  }

  Future<void> _onSearchCourses(
    SearchCourses event,
    Emitter<TrainingState> emit,
  ) async {
    if (state is TrainingLoaded) {
      emit(const TrainingLoading());

      final coursesResult = event.query.isEmpty
          ? await repository.getAllCourses()
          : await repository.searchCourses(event.query);
      final progressResult = await repository.getOverallProgress();

      coursesResult.fold(
        (failure) => emit(TrainingError(failure.message)),
        (courses) {
          progressResult.fold(
            (failure) => emit(TrainingError(failure.message)),
            (progress) {
              final currentState = state as TrainingLoaded;
              emit(TrainingLoaded(
                courses: courses,
                categories: currentState.categories,
                overallProgress: progress,
                searchQuery: event.query,
              ));
            },
          );
        },
      );
    }
  }

  Future<void> _onUpdateProgress(
    UpdateProgress event,
    Emitter<TrainingState> emit,
  ) async {
    if (state is TrainingLoaded) {
      final progressResult = await repository.getOverallProgress();

      progressResult.fold(
        (failure) => emit(TrainingError(failure.message)),
        (progress) {
          final currentState = state as TrainingLoaded;
          emit(currentState.copyWith(overallProgress: progress));
        },
      );
    }
  }
}
