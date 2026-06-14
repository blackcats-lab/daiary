import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/album_summary.dart';

part 'album_list_view.freezed.dart';

/// AlbumSummary に Signed URL を組み合わせた一覧表示用ラッパー。
@freezed
abstract class AlbumListItemView with _$AlbumListItemView {
  const factory AlbumListItemView({
    required AlbumSummary summary,
    String? signedCoverUrl,
  }) = _AlbumListItemView;
}
