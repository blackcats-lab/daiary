import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../../domain/entities/album_summary.dart';

part 'album_create_state.freezed.dart';

@freezed
sealed class AlbumCreateState with _$AlbumCreateState {
  const factory AlbumCreateState.idle() = AlbumCreateIdle;
  const factory AlbumCreateState.submitting() = AlbumCreateSubmitting;
  const factory AlbumCreateState.success(AlbumSummary album) =
      AlbumCreateSuccess;
  const factory AlbumCreateState.failure(AlbumFailure failure) =
      AlbumCreateFailure;
}
