import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'photo_edit_state.freezed.dart';

/// 写真編集画面の状態。プレビュー対象ファイルと調整値・フィルタ選択を保持する。
@freezed
abstract class PhotoEditState with _$PhotoEditState {
  const factory PhotoEditState({
    /// プレビュー / 保存対象のローカルファイル（トリミング後はこれが差し替わる）。
    File? workingFile,
    @Default(0) int filterIndex,
    @Default(0.0) double brightness,
    @Default(0.0) double contrast,
    @Default(0.0) double saturation,
    @Default(false) bool saving,
    @Default(false) bool saved,
    String? errorMessage,
  }) = _PhotoEditState;

  const PhotoEditState._();

  bool get hasAdjustments =>
      filterIndex != 0 || brightness != 0 || contrast != 0 || saturation != 0;
}
