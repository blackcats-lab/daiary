import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/photo_failure.dart';
import 'photo_list_view.dart';

part 'photo_list_state.freezed.dart';

@freezed
sealed class PhotoListState with _$PhotoListState {
  const factory PhotoListState.initial() = PhotoListInitial;
  const factory PhotoListState.loading() = PhotoListLoading;
  const factory PhotoListState.loaded({
    required List<PhotoListItemView> items,
    DateTime? nextBefore,
    @Default(false) bool loadingMore,
  }) = PhotoListLoaded;
  const factory PhotoListState.error(PhotoFailure failure) = PhotoListError;
}
