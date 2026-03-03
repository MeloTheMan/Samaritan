import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'media_asset.dart';

part 'course_step.g.dart';

@HiveType(typeId: 1)
class CourseStep extends Equatable {
  @HiveField(0)
  final int order;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final List<MediaAsset> media;

  @HiveField(4)
  final List<String> keyPoints;

  const CourseStep({
    required this.order,
    required this.title,
    required this.description,
    required this.media,
    required this.keyPoints,
  });

  factory CourseStep.fromJson(Map<String, dynamic> json) {
    return CourseStep(
      order: json['order'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      media: (json['media'] as List<dynamic>?)
              ?.map((e) => MediaAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      keyPoints: (json['keyPoints'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'title': title,
      'description': description,
      'media': media.map((e) => e.toJson()).toList(),
      'keyPoints': keyPoints,
    };
  }

  @override
  List<Object?> get props => [order, title, description, media, keyPoints];
}
