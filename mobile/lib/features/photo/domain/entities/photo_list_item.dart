import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_list_item.freezed.dart';

@freezed
abstract class PhotoListItem with _$PhotoListItem {
  const factory PhotoListItem({
    required String id,
    required String storagePath,
    String? thumbnailPath,
    required DateTime createdAt,
    int? fileSize,
    int? width,
    int? height,
    @Default(false) bool isFavorite,
    @Default(<String>[]) List<String> aiTags,
    String? caption,
  }) = _PhotoListItem;
}

/// Edge Function /photos の JSON レスポンスから PhotoListItem を構築する。
/// Freezed の fromJson factory にすると json_serializable が .g.dart を
/// 期待してしまうため、別関数として定義する。
PhotoListItem photoListItemFromJson(Map<String, dynamic> json) => PhotoListItem(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      fileSize: (json['file_size'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      isFavorite: json['is_favorite'] as bool? ?? false,
      aiTags: ((json['ai_tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      caption: json['caption'] as String?,
    );
