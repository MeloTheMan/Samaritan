// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_asset.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaAssetAdapter extends TypeAdapter<MediaAsset> {
  @override
  final int typeId = 2;

  @override
  MediaAsset read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaAsset(
      url: fields[0] as String,
      type: fields[1] as MediaType,
      caption: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MediaAsset obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.caption);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaAssetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
