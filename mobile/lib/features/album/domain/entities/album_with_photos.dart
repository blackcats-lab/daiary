import 'package:freezed_annotation/freezed_annotation.dart';

import 'album_photo.dart';
import 'album_summary.dart';

part 'album_with_photos.freezed.dart';

/// GET /albums/:id のレスポンスに対応するエンティティ。
/// album サマリーと写真リストを保持。photo_count は photos.length で算出。
@freezed
abstract class AlbumWithPhotos with _$AlbumWithPhotos {
  const factory AlbumWithPhotos({
    required AlbumSummary album,
    required List<AlbumPhoto> photos,
  }) = _AlbumWithPhotos;
}

AlbumWithPhotos albumWithPhotosFromJson(Map<String, dynamic> json) {
  final albumJson = (json['album'] as Map).cast<String, dynamic>();
  final photoJsons =
      ((json['photos'] as List?) ?? const []).cast<Map<String, dynamic>>();
  // GET /albums/:id では cover_thumbnail_path / photo_count を返さないので
  // 詳細画面では photos.length を photoCount として補完する。
  final summary = albumSummaryFromJson({
    ...albumJson,
    'photo_count': photoJsons.length,
  });
  return AlbumWithPhotos(
    album: summary,
    photos: photoJsons.map(albumPhotoFromJson).toList(growable: false),
  );
}
