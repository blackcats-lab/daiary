import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../domain/entities/photo_filter.dart';
import 'photo_list_view.dart';

part 'photo_search_state.freezed.dart';

/// 検索結果の状態。フィルタ条件 [filter] を常に保持し、結果は items に持つ。
/// フィード（photoListProvider）とは独立した autoDispose の状態として管理する。
@freezed
sealed class PhotoSearchState with _$PhotoSearchState {
  /// フィルタ未設定（検索モード OFF）。
  const factory PhotoSearchState.idle() = PhotoSearchIdle;
  const factory PhotoSearchState.loading(PhotoFilter filter) =
      PhotoSearchLoading;
  const factory PhotoSearchState.loaded({
    required PhotoFilter filter,
    required List<PhotoListItemView> items,
    DateTime? nextBefore,
    @Default(false) bool loadingMore,
  }) = PhotoSearchLoaded;
  const factory PhotoSearchState.error({
    required PhotoFilter filter,
    required PhotoFailure failure,
  }) = PhotoSearchError;
}
