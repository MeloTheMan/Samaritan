import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/course.dart';
import '../../domain/repositories/training_repository.dart';

@LazySingleton(as: TrainingRepository)
class TrainingRepositoryImpl implements TrainingRepository {
  static const String _coursesBoxName = 'courses';
  static const String _completedCoursesKey = 'completed_courses';

  @override
  Future<Either<Failure, List<Course>>> getAllCourses() async {
    try {
      final coursesJson = await rootBundle.loadString('assets/courses/courses.json');
      final List<dynamic> coursesList = json.decode(coursesJson);
      
      final courses = coursesList
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Load completed status from Hive
      final box = await Hive.openBox(_coursesBoxName);
      final completedIds = box.get(_completedCoursesKey, defaultValue: <String>[]) as List;
      final completedSet = Set<String>.from(completedIds.cast<String>());
      
      final coursesWithStatus = courses.map((course) {
        return course.copyWith(isCompleted: completedSet.contains(course.id));
      }).toList();
      
      return Right(coursesWithStatus);
    } catch (e) {
      return Left(CacheFailure('Failed to load courses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Course>> getCourseById(String id) async {
    try {
      final coursesResult = await getAllCourses();
      return coursesResult.fold(
        (failure) => Left(failure),
        (courses) {
          final course = courses.firstWhere(
            (c) => c.id == id,
            orElse: () => throw Exception('Course not found'),
          );
          return Right(course);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Course not found: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Course>>> getCoursesByCategory(String category) async {
    try {
      final coursesResult = await getAllCourses();
      return coursesResult.fold(
        (failure) => Left(failure),
        (courses) {
          final filteredCourses = courses
              .where((c) => c.category.toLowerCase() == category.toLowerCase())
              .toList();
          return Right(filteredCourses);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to filter courses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Course>>> searchCourses(String query) async {
    try {
      final coursesResult = await getAllCourses();
      return coursesResult.fold(
        (failure) => Left(failure),
        (courses) {
          final lowerQuery = query.toLowerCase();
          final filteredCourses = courses.where((c) {
            return c.title.toLowerCase().contains(lowerQuery) ||
                c.category.toLowerCase().contains(lowerQuery);
          }).toList();
          return Right(filteredCourses);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to search courses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> markCourseAsCompleted(String courseId) async {
    try {
      final box = await Hive.openBox(_coursesBoxName);
      final completedIds = box.get(_completedCoursesKey, defaultValue: <String>[]) as List;
      final completedSet = Set<String>.from(completedIds.cast<String>());
      
      completedSet.add(courseId);
      await box.put(_completedCoursesKey, completedSet.toList());
      
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to mark course as completed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getOverallProgress() async {
    try {
      final coursesResult = await getAllCourses();
      return coursesResult.fold(
        (failure) => Left(failure),
        (courses) {
          if (courses.isEmpty) return const Right(0.0);
          
          final completedCount = courses.where((c) => c.isCompleted).length;
          final progress = completedCount / courses.length;
          return Right(progress);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to calculate progress: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getCategories() async {
    try {
      final coursesResult = await getAllCourses();
      return coursesResult.fold(
        (failure) => Left(failure),
        (courses) {
          final categories = courses.map((c) => c.category).toSet().toList();
          categories.sort();
          return Right(categories);
        },
      );
    } catch (e) {
      return Left(CacheFailure('Failed to get categories: ${e.toString()}'));
    }
  }
}
