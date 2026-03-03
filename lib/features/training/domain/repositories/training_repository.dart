import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/course.dart';

abstract class TrainingRepository {
  Future<Either<Failure, List<Course>>> getAllCourses();
  Future<Either<Failure, Course>> getCourseById(String id);
  Future<Either<Failure, List<Course>>> getCoursesByCategory(String category);
  Future<Either<Failure, List<Course>>> searchCourses(String query);
  Future<Either<Failure, void>> markCourseAsCompleted(String courseId);
  Future<Either<Failure, double>> getOverallProgress();
  Future<Either<Failure, List<String>>> getCategories();
}
