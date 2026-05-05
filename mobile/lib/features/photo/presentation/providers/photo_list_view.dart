import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/photo_list_item.dart';

part 'photo_list_view.freezed.dart';

/// PhotoListItem に取得済みの Signed URL を組み合わせた表示用ラッパー。
/// signedThumbnailUrl が null の場合は壊れアイコンで表示する。
@freezed
abstract class PhotoListItemView with _$PhotoListItemView {
  const factory PhotoListItemView({
    required PhotoListItem item,
    String? signedThumbnailUrl,
  }) = _PhotoListItemView;
}
