import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/ai_generate_failure.dart';
import '../../../photo/domain/entities/uploaded_photo.dart';
import '../../../photo/presentation/providers/photo_list_notifier.dart';
import '../../data/repositories/ai_generate_repository.dart';
import 'ai_generate_state.dart';

part 'ai_generate_notifier.g.dart';

/// 撮影画像から hashtag を生成して photos.ai_tags に保存するオーケストレータ。
@Riverpod(keepAlive: false)
class AiGenerateNotifier extends _$AiGenerateNotifier {
  @override
  AiGenerateState build() => const AiGenerateState.idle();

  Future<void> generate(UploadedPhoto photo, File processedFile) async {
    state = const AiGenerateState.generating();

    final repo = ref.read(aiGenerateRepositoryProvider);

    // ===== Generate =====
    final List<String> hashtags;
    try {
      final bytes = await processedFile.readAsBytes();
      final result = await repo.generateHashtags(bytes);
      hashtags = result.hashtags;
    } on AiGenerateFailure catch (f) {
      state = AiGenerateState.failure(f);
      return;
    } catch (e) {
      state = AiGenerateState.failure(
        AiGenerateFailure('unknown', 'タグ生成中に予期せぬエラー: $e'),
      );
      return;
    }

    // ===== Save =====
    state = AiGenerateState.saving(hashtags);
    try {
      await repo.updatePhotoTags(photo.id, hashtags);
    } on AiGenerateFailure catch (f) {
      state = AiGenerateState.failure(f, partialHashtags: hashtags);
      return;
    } catch (e) {
      state = AiGenerateState.failure(
        AiGenerateFailure('service_failed', 'タグ保存中に予期せぬエラー: $e'),
        partialHashtags: hashtags,
      );
      return;
    }

    // 一覧側の ai_tags を最新化
    ref.read(photoListProvider.notifier).refresh();

    state = AiGenerateState.success(hashtags);
  }

  Future<void> retry(UploadedPhoto photo, File processedFile) =>
      generate(photo, processedFile);

  void reset() {
    state = const AiGenerateState.idle();
  }
}
