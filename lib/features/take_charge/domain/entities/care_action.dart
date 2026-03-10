import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'care_action.g.dart';

@HiveType(typeId: 24)
class CareAction extends Equatable {
  @HiveField(0)
  final String actionId;

  @HiveField(1)
  final String description;

  @HiveField(2)
  final DateTime performedAt;

  @HiveField(3)
  final Duration duration;

  @HiveField(4)
  final String? notes;

  @HiveField(5)
  final bool completed;

  const CareAction({
    required this.actionId,
    required this.description,
    required this.performedAt,
    required this.duration,
    this.notes,
    this.completed = false,
  });

  CareAction copyWith({
    String? actionId,
    String? description,
    DateTime? performedAt,
    Duration? duration,
    String? notes,
    bool? completed,
  }) {
    return CareAction(
      actionId: actionId ?? this.actionId,
      description: description ?? this.description,
      performedAt: performedAt ?? this.performedAt,
      duration: duration ?? this.duration,
      notes: notes ?? this.notes,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [
        actionId,
        description,
        performedAt,
        duration,
        notes,
        completed,
      ];
}
