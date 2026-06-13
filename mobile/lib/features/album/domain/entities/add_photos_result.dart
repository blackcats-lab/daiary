import 'package:freezed_annotation/freezed_annotation.dart';

part 'add_photos_result.freezed.dart';

/// POST /albums/:id/photos のレスポンス。
/// added: 実際に追加された photo_id
/// skipped: 弾かれた photo_id と理由（already_in_album / not_owned_or_deleted）
@freezed
abstract class AddPhotosResult with _$AddPhotosResult {
  const factory AddPhotosResult({
    @Default(<String>[]) List<String> added,
    @Default(<SkippedPhoto>[]) List<SkippedPhoto> skipped,
  }) = _AddPhotosResult;
}

@freezed
abstract class SkippedPhoto with _$SkippedPhoto {
  const factory SkippedPhoto({
    required String photoId,
    required String reason,
  }) = _SkippedPhoto;
}

AddPhotosResult addPhotosResultFromJson(Map<String, dynamic> json) {
  final added = ((json['added'] as List?) ?? const []).cast<String>();
  final skippedRaw =
      ((json['skipped'] as List?) ?? const []).cast<Map<String, dynamic>>();
  return AddPhotosResult(
    added: added,
    skipped: skippedRaw
        .map((e) => SkippedPhoto(
              photoId: e['photo_id'] as String,
              reason: (e['reason'] as String?) ?? 'unknown',
            ))
        .toList(growable: false),
  );
}
