import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_generate_result.freezed.dart';

@freezed
abstract class AiHashtagResult with _$AiHashtagResult {
  const factory AiHashtagResult({
    required List<String> hashtags,
    required String model,
    required int remaining,
    required int limit,
  }) = _AiHashtagResult;
}

@freezed
abstract class AiCaptionResult with _$AiCaptionResult {
  const factory AiCaptionResult({
    required String caption,
    String? altText,
    required String model,
    required int remaining,
    required int limit,
  }) = _AiCaptionResult;
}
