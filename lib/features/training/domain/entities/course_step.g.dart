// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_step.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CourseStepAdapter extends TypeAdapter<CourseStep> {
  @override
  final int typeId = 1;

  @override
  CourseStep read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CourseStep(
      order: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String,
      media: (fields[3] as List).cast<MediaAsset>(),
      keyPoints: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, CourseStep obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.order)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.media)
      ..writeByte(4)
      ..write(obj.keyPoints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseStepAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
