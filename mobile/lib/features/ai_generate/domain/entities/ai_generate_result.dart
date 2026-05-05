import 'package:freezed_annotation/freezed_annotation.dart';

part 'ai_generate_result.freezed.dart';

@freezed
abstract class AiGenerateResult with _$AiGenerateResult {
  const factory AiGenerateResult({
    required List<String> hashtags,
    required String model,
    required int remaining,
    required int limit,
  }) = _AiGenerateResult;
}
