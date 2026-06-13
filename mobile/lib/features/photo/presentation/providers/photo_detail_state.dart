import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../domain/entities/photo_detail.dart';

part 'photo_detail_state.freezed.dart';

@freezed
sealed class PhotoDetailState with _$PhotoDetailState {
  const factory PhotoDetailState.initial() = PhotoDetailInitial;
  const factory PhotoDetailState.loading() = PhotoDetailLoading;

  /// loaded 中は楽観更新のため favoriteUpdating / deleting / sharing /
  /// preparingAi の進行フラグを併せ持つ。
  /// deleted=true は削除完了通知（画面側 listen で pop する）。
  const factory PhotoDetailState.loaded({
    required PhotoDetail detail,
    String? signedOriginalUrl,
    @Default(false) bool favoriteUpdating,
    @Default(false) bool deleting,
    @Default(false) bool sharing,
    @Default(false) bool preparingAi,
    @Default(false) bool deleted,
  }) = PhotoDetailLoaded;

  const factory PhotoDetailState.error(PhotoFailure failure) = PhotoDetailError;
}
