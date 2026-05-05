import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../domain/entities/album_with_photos.dart';

part 'album_detail_state.freezed.dart';

@freezed
sealed class AlbumDetailState with _$AlbumDetailState {
  const factory AlbumDetailState.initial() = AlbumDetailInitial;
  const factory AlbumDetailState.loading() = AlbumDetailLoading;

  /// 通常モード / 選択モードの切替と、サムネイルの Signed URL マップを保持する。
  const factory AlbumDetailState.loaded({
    required AlbumWithPhotos detail,
    @Default(<String, String?>{}) Map<String, String?> signedUrls,
    @Default(false) bool selectionMode,
    @Default(<String>{}) Set<String> selected,
    @Default(false) bool updating,
    @Default(false) bool deleting,
    @Default(false) bool removingPhotos,
    @Default(false) bool deleted, // アルバム削除完了
  }) = AlbumDetailLoaded;

  const factory AlbumDetailState.error(AlbumFailure failure) = AlbumDetailError;
}
