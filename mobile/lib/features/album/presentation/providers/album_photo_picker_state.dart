import 'package:freezed_annotation/freezed_annotation.dart';

part 'album_photo_picker_state.freezed.dart';

/// 写真ピッカーのローカル選択状態。
/// existingIds: アルバムに既に含まれる photo_id（disabled で表示）
/// selected: 今 picker で選択中の photo_id
/// submitting: POST /albums/:id/photos 進行中
@freezed
abstract class AlbumPhotoPickerState with _$AlbumPhotoPickerState {
  const factory AlbumPhotoPickerState({
    @Default(<String>{}) Set<String> existingIds,
    @Default(<String>{}) Set<String> selected,
    @Default(false) bool submitting,
  }) = _AlbumPhotoPickerState;
}
