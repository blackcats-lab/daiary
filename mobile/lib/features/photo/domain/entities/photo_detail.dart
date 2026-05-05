import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_detail.freezed.dart';

/// 写真詳細画面用のエンティティ。
/// PhotoListItem と異なり exif_data / alt_text / deleted_at / original_filename も保持する。
@freezed
abstract class PhotoDetail with _$PhotoDetail {
  const factory PhotoDetail({
    required String id,
    required String storagePath,
    String? thumbnailPath,
    String? originalFilename,
    int? fileSize,
    int? width,
    int? height,
    @Default(<String, dynamic>{}) Map<String, dynamic> exifData,
    @Default(<String>[]) List<String> aiTags,
    @Default(false) bool isFavorite,
    String? caption,
    String? altText,
    required DateTime createdAt,
    DateTime? deletedAt,
  }) = _PhotoDetail;
}

PhotoDetail photoDetailFromJson(Map<String, dynamic> json) => PhotoDetail(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      thumbnailPath: json['thumbnail_path'] as String?,
      originalFilename: json['original_filename'] as String?,
      fileSize: (json['file_size'] as num?)?.toInt(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      exifData:
          ((json['exif_data'] as Map?) ?? const {}).cast<String, dynamic>(),
      aiTags: ((json['ai_tags'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      isFavorite: json['is_favorite'] as bool? ?? false,
      caption: json['caption'] as String?,
      altText: json['alt_text'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      deletedAt: (json['deleted_at'] as String?) == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );
