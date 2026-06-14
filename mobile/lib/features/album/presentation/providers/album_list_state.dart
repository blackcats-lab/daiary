import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/album_failure.dart';
import 'album_list_view.dart';

part 'album_list_state.freezed.dart';

@freezed
sealed class AlbumListState with _$AlbumListState {
  const factory AlbumListState.initial() = AlbumListInitial;
  const factory AlbumListState.loading() = AlbumListLoading;
  const factory AlbumListState.loaded({
    required List<AlbumListItemView> items,
  }) = AlbumListLoaded;
  const factory AlbumListState.error(AlbumFailure failure) = AlbumListError;
}
