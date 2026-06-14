import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../domain/entities/trash_item.dart';

part 'trash_state.freezed.dart';

/// ゴミ箱内アイテムに Signed URL を組み合わせた表示用ラッパー。
@freezed
abstract class TrashItemView with _$TrashItemView {
  const factory TrashItemView({
    required TrashItem item,
    String? signedThumbnailUrl,
  }) = _TrashItemView;
}

@freezed
sealed class TrashState with _$TrashState {
  const factory TrashState.initial() = TrashInitial;
  const factory TrashState.loading() = TrashLoading;
  const factory TrashState.loaded(List<TrashItemView> items) = TrashLoaded;
  const factory TrashState.error(PhotoFailure failure) = TrashError;
}
