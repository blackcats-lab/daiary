import 'package:freezed_annotation/freezed_annotation.dart';

part 'album_photo.freezed.dart';

/// アルバム詳細画面で表示する写真。
/// album_photos の sort_order / added_at と photos の主要メタデータを持つ。
@freezed
abstract class AlbumPhoto with _$AlbumPhoto {
  const factory AlbumPhoto({
    required String id,
    required String storagePath,
    String? thumbnailPath,
    required int sortOrder,
    String? caption,
    @Default(<String>[]) List<String> aiTags,
    @Default(false) bool isFavorite,
    int? width,
    int? height,
    required DateTime addedAt,
  }) = _AlbumPhoto;
}

AlbumPhoto albumPhotoFromJson(Map<String, dynamic> json) => AlbumPhoto(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      caption: json['caption'] as String?,
      aiTags: ((json['ai_tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      isFavorite: json['is_favorite'] as bool? ?? false,
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      addedAt: DateTime.parse(json['added_at'] as String),
    );
