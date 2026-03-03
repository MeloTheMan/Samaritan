import 'package:hive/hive.dart';
import 'difficulty_level.dart';
import 'media_asset.dart';

// DifficultyLevel Adapter
class DifficultyLevelAdapter extends TypeAdapter<DifficultyLevel> {
  @override
  final int typeId = 3;

  @override
  DifficultyLevel read(BinaryReader reader) {
    final index = reader.readByte();
    return DifficultyLevel.values[index];
  }

  @override
  void write(BinaryWriter writer, DifficultyLevel obj) {
    writer.writeByte(obj.index);
  }
}

// MediaType Adapter
class MediaTypeAdapter extends TypeAdapter<MediaType> {
  @override
  final int typeId = 4;

  @override
  MediaType read(BinaryReader reader) {
    final index = reader.readByte();
    return MediaType.values[index];
  }

  @override
  void write(BinaryWriter writer, MediaType obj) {
    writer.writeByte(obj.index);
  }
}

// Duration Adapter
class DurationAdapter extends TypeAdapter<Duration> {
  @override
  final int typeId = 5;

  @override
  Duration read(BinaryReader reader) {
    final microseconds = reader.readInt();
    return Duration(microseconds: microseconds);
  }

  @override
  void write(BinaryWriter writer, Duration obj) {
    writer.writeInt(obj.inMicroseconds);
  }
}
