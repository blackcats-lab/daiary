import 'package:freezed_annotation/freezed_annotation.dart';

part 'album_summary.freezed.dart';

/// アルバム一覧画面・作成成功レスポンス用のサマリーエンティティ。
/// cover_thumbnail_path / photo_count を含む（GET /albums のレスポンス整形済み）。
@freezed
abstract class AlbumSummary with _$AlbumSummary {
  const factory AlbumSummary({
    required String id,
    required String name,
    String? coverPhotoId,
    String? coverThumbnailPath,
    @Default(false) bool isPublic,
    String? shareToken,
    @Default(0) int photoCount,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AlbumSummary;
}

AlbumSummary albumSummaryFromJson(Map<String, dynamic> json) => AlbumSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      coverPhotoId: json['cover_photo_id'] as String?,
      coverThumbnailPath: json['cover_thumbnail_path'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      shareToken: json['share_token'] as String?,
      photoCount: (json['photo_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
