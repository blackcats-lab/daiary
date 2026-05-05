import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/ai_generate_failure.dart';
import '../../domain/entities/caption_options.dart';

part 'ai_generate_state.freezed.dart';

/// ハッシュタグ生成のフェーズ。撮影直後に自動実行される。
@freezed
sealed class HashtagPhase with _$HashtagPhase {
  const factory HashtagPhase.idle() = HashtagIdle;
  const factory HashtagPhase.generating() = HashtagGenerating;
  const factory HashtagPhase.saving(List<String> hashtags) = HashtagSaving;
  const factory HashtagPhase.success(List<String> hashtags) = HashtagSuccess;

  /// 生成成功後の保存に失敗したケースで partialHashtags を保持し、
  /// UI 側で表示を続けつつエラー通知できるようにする。
  const factory HashtagPhase.failure(
    AiGenerateFailure failure, {
    List<String>? partialHashtags,
  }) = HashtagFailure;
}

/// キャプション生成のフェーズ。ユーザー操作で起動・再生成される。
@freezed
sealed class CaptionPhase with _$CaptionPhase {
  const factory CaptionPhase.idle() = CaptionIdle;
  const factory CaptionPhase.generating() = CaptionGenerating;
  const factory CaptionPhase.saving({
    required String caption,
    String? altText,
  }) = CaptionSaving;
  const factory CaptionPhase.success({
    required String caption,
    String? altText,
  }) = CaptionSuccess;
  const factory CaptionPhase.failure(
    AiGenerateFailure failure, {
    String? partialCaption,
    String? partialAltText,
  }) = CaptionFailure;
}

/// AI 生成画面全体の state。ハッシュタグと caption は独立したフェーズを持つ。
@freezed
abstract class AiGenerateState with _$AiGenerateState {
  const factory AiGenerateState({
    @Default(HashtagPhase.idle()) HashtagPhase hashtag,
    @Default(CaptionPhase.idle()) CaptionPhase caption,
    @Default(CaptionStyle.casual) CaptionStyle selectedStyle,
    @Default(CaptionLength.medium) CaptionLength selectedLength,
  }) = _AiGenerateState;
}
