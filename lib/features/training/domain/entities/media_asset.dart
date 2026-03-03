import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'media_asset.g.dart';

enum MediaType {
  image,
  video,
  animation,
}

@HiveType(typeId: 2)
class MediaAsset extends Equatable {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final MediaType type;

  @HiveField(2)
  final String? caption;

  const MediaAsset({
    required this.url,
    required this.type,
    this.caption,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      url: json['url'] as String,
      type: MediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MediaType.image,
      ),
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type.name,
      'caption': caption,
    };
  }

  @override
  List<Object?> get props => [url, type, caption];
}
