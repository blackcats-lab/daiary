import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/exceptions/ai_generate_failure.dart';

part 'ai_generate_state.freezed.dart';

@freezed
sealed class AiGenerateState with _$AiGenerateState {
  const factory AiGenerateState.idle() = AiGenerateIdle;
  const factory AiGenerateState.generating() = AiGenerateGenerating;
  const factory AiGenerateState.saving(List<String> hashtags) =
      AiGenerateSaving;
  const factory AiGenerateState.success(List<String> hashtags) =
      AiGenerateSuccess;

  /// 生成は成功したが photos PATCH に失敗したケースで partialHashtags を保持し、
  /// UI 側でタグ表示を続けつつエラー通知できるようにする。
  const factory AiGenerateState.failure(
    AiGenerateFailure failure, {
    List<String>? partialHashtags,
  }) = AiGenerateFailureState;
}
