import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/exceptions/ai_generate_failure.dart';
import '../../../photo/domain/entities/uploaded_photo.dart';
import '../../../photo/presentation/providers/photo_list_notifier.dart';
import '../../data/repositories/ai_generate_repository.dart';
import '../../domain/entities/caption_options.dart';
import 'ai_generate_state.dart';

part 'ai_generate_notifier.g.dart';

/// 撮影画像から hashtag / caption を生成し photos に保存するオーケストレータ。
/// hashtag は撮影直後に自動実行、caption はユーザー操作で起動・再生成される。
@Riverpod(keepAlive: false)
class AiGenerateNotifier extends _$AiGenerateNotifier {
  @override
  AiGenerateState build() => const AiGenerateState();

  // ===== Hashtag flow =====

  Future<void> generateHashtags(
    UploadedPhoto photo,
    File processedFile,
  ) async {
    state = state.copyWith(hashtag: const HashtagPhase.generating());

    final repo = ref.read(aiGenerateRepositoryProvider);

    final List<String> hashtags;
    try {
      final bytes = await processedFile.readAsBytes();
      final result = await repo.generateHashtags(bytes);
      hashtags = result.hashtags;
    } on AiGenerateFailure catch (f) {
      state = state.copyWith(hashtag: HashtagPhase.failure(f));
      return;
    } catch (e) {
      state = state.copyWith(
        hashtag: HashtagPhase.failure(
          AiGenerateFailure('unknown', 'タグ生成中に予期せぬエラー: $e'),
        ),
      );
      return;
    }

    state = state.copyWith(hashtag: HashtagPhase.saving(hashtags));
    try {
      await repo.updatePhotoTags(photo.id, hashtags);
    } on AiGenerateFailure catch (f) {
      state = state.copyWith(
        hashtag: HashtagPhase.failure(f, partialHashtags: hashtags),
      );
      return;
    } catch (e) {
      state = state.copyWith(
        hashtag: HashtagPhase.failure(
          AiGenerateFailure('service_failed', 'タグ保存中に予期せぬエラー: $e'),
          partialHashtags: hashtags,
        ),
      );
      return;
    }

    ref.read(photoListProvider.notifier).refresh();
    state = state.copyWith(hashtag: HashtagPhase.success(hashtags));
  }

  Future<void> retryHashtags(UploadedPhoto photo, File processedFile) =>
      generateHashtags(photo, processedFile);

  // ===== Caption flow =====

  Future<void> generateCaption(
    UploadedPhoto photo,
    File processedFile,
  ) async {
    // 生成中・保存中は二重実行を防ぐ
    final current = state.caption;
    if (current is CaptionGenerating || current is CaptionSaving) return;

    state = state.copyWith(caption: const CaptionPhase.generating());

    final repo = ref.read(aiGenerateRepositoryProvider);

    final String caption;
    final String? altText;
    try {
      final bytes = await processedFile.readAsBytes();
      final result = await repo.generateCaption(
        bytes,
        style: state.selectedStyle,
        length: state.selectedLength,
      );
      caption = result.caption;
      altText = result.altText;
    } on AiGenerateFailure catch (f) {
      state = state.copyWith(caption: CaptionPhase.failure(f));
      return;
    } catch (e) {
      state = state.copyWith(
        caption: CaptionPhase.failure(
          AiGenerateFailure('unknown', '投稿文生成中に予期せぬエラー: $e'),
        ),
      );
      return;
    }

    state = state.copyWith(
      caption: CaptionPhase.saving(caption: caption, altText: altText),
    );
    try {
      await repo.updatePhotoCaption(
        photo.id,
        caption: caption,
        altText: altText,
      );
    } on AiGenerateFailure catch (f) {
      state = state.copyWith(
        caption: CaptionPhase.failure(
          f,
          partialCaption: caption,
          partialAltText: altText,
        ),
      );
      return;
    } catch (e) {
      state = state.copyWith(
        caption: CaptionPhase.failure(
          AiGenerateFailure('service_failed', '投稿文保存中に予期せぬエラー: $e'),
          partialCaption: caption,
          partialAltText: altText,
        ),
      );
      return;
    }

    ref.read(photoListProvider.notifier).refresh();
    state = state.copyWith(
      caption: CaptionPhase.success(caption: caption, altText: altText),
    );
  }

  Future<void> retryCaption(UploadedPhoto photo, File processedFile) =>
      generateCaption(photo, processedFile);

  void setStyle(CaptionStyle style) {
    final phase = state.caption;
    if (phase is CaptionGenerating || phase is CaptionSaving) return;
    state = state.copyWith(selectedStyle: style);
  }

  void setLength(CaptionLength length) {
    final phase = state.caption;
    if (phase is CaptionGenerating || phase is CaptionSaving) return;
    state = state.copyWith(selectedLength: length);
  }
}
