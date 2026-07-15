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
///
/// 生成中に「ホームに戻る」等で画面を離れると provider は dispose されるが、
/// 生成は利用回数を消費済みのため、保存（photos への PATCH）は中断せず最後まで
/// 走らせる。dispose 後に禁止されるのは state 更新と ref の使用のみなので、
/// state 更新は [_update] で、ref 使用は await より前の取得で保護する。
@Riverpod(keepAlive: false)
class AiGenerateNotifier extends _$AiGenerateNotifier {
  bool _disposed = false;

  @override
  AiGenerateState build() {
    _disposed = false;
    ref.onDispose(() => _disposed = true);
    return const AiGenerateState();
  }

  /// dispose 済みなら state に触らない（読み書きとも StateError になるため）。
  void _update(AiGenerateState Function(AiGenerateState) updater) {
    if (_disposed) return;
    state = updater(state);
  }

  void _refreshPhotoList() {
    if (_disposed) return;
    ref.read(photoListProvider.notifier).refresh();
  }

  // ===== Hashtag flow =====

  Future<void> generateHashtags(
    UploadedPhoto photo,
    File processedFile,
  ) async {
    // repo は dispose 後に ref を触らずに済むよう await より前に取得する
    final repo = ref.read(aiGenerateRepositoryProvider);
    _update((s) => s.copyWith(hashtag: const HashtagPhase.generating()));

    final List<String> hashtags;
    try {
      final bytes = await processedFile.readAsBytes();
      final result = await repo.generateHashtags(bytes);
      hashtags = result.hashtags;
    } on AiGenerateFailure catch (f) {
      _update((s) => s.copyWith(hashtag: HashtagPhase.failure(f)));
      return;
    } catch (e) {
      _update((s) => s.copyWith(
            hashtag: HashtagPhase.failure(
              AiGenerateFailure('unknown', 'タグ生成中に予期せぬエラー: $e'),
            ),
          ));
      return;
    }

    await _saveHashtags(repo, photo.id, hashtags);
  }

  Future<void> _saveHashtags(
    AiGenerateRepository repo,
    String photoId,
    List<String> hashtags,
  ) async {
    _update((s) => s.copyWith(hashtag: HashtagPhase.saving(hashtags)));
    try {
      await repo.updatePhotoTags(photoId, hashtags);
    } on AiGenerateFailure catch (f) {
      _update((s) => s.copyWith(
            hashtag: HashtagPhase.failure(f, partialHashtags: hashtags),
          ));
      return;
    } catch (e) {
      _update((s) => s.copyWith(
            hashtag: HashtagPhase.failure(
              AiGenerateFailure('service_failed', 'タグ保存中に予期せぬエラー: $e'),
              partialHashtags: hashtags,
            ),
          ));
      return;
    }

    _refreshPhotoList();
    _update((s) => s.copyWith(hashtag: HashtagPhase.success(hashtags)));
  }

  /// リトライ。生成は成功して保存だけ失敗している場合（partialHashtags あり）は、
  /// 再生成せず保存のみやり直す（本日の利用回数を再消費しない・表示中のタグと
  /// 保存されるタグが食い違わない）。
  Future<void> retryHashtags(UploadedPhoto photo, File processedFile) async {
    final phase = state.hashtag;
    if (phase is HashtagFailure &&
        (phase.partialHashtags?.isNotEmpty ?? false)) {
      final repo = ref.read(aiGenerateRepositoryProvider);
      await _saveHashtags(repo, photo.id, phase.partialHashtags!);
      return;
    }
    await generateHashtags(photo, processedFile);
  }

  // ===== Caption flow =====

  Future<void> generateCaption(
    UploadedPhoto photo,
    File processedFile,
  ) async {
    // 生成中・保存中は二重実行を防ぐ
    final current = state.caption;
    if (current is CaptionGenerating || current is CaptionSaving) return;

    // dispose 後に state / ref を触らずに済むよう await より前に取得する
    final repo = ref.read(aiGenerateRepositoryProvider);
    final style = state.selectedStyle;
    final length = state.selectedLength;

    _update((s) => s.copyWith(caption: const CaptionPhase.generating()));

    final String caption;
    final String? altText;
    try {
      final bytes = await processedFile.readAsBytes();
      final result = await repo.generateCaption(
        bytes,
        style: style,
        length: length,
      );
      caption = result.caption;
      altText = result.altText;
    } on AiGenerateFailure catch (f) {
      _update((s) => s.copyWith(caption: CaptionPhase.failure(f)));
      return;
    } catch (e) {
      _update((s) => s.copyWith(
            caption: CaptionPhase.failure(
              AiGenerateFailure('unknown', '投稿文生成中に予期せぬエラー: $e'),
            ),
          ));
      return;
    }

    await _saveCaption(repo, photo.id, caption: caption, altText: altText);
  }

  Future<void> _saveCaption(
    AiGenerateRepository repo,
    String photoId, {
    required String caption,
    String? altText,
  }) async {
    _update((s) => s.copyWith(
          caption: CaptionPhase.saving(caption: caption, altText: altText),
        ));
    try {
      await repo.updatePhotoCaption(
        photoId,
        caption: caption,
        altText: altText,
      );
    } on AiGenerateFailure catch (f) {
      _update((s) => s.copyWith(
            caption: CaptionPhase.failure(
              f,
              partialCaption: caption,
              partialAltText: altText,
            ),
          ));
      return;
    } catch (e) {
      _update((s) => s.copyWith(
            caption: CaptionPhase.failure(
              AiGenerateFailure('service_failed', '投稿文保存中に予期せぬエラー: $e'),
              partialCaption: caption,
              partialAltText: altText,
            ),
          ));
      return;
    }

    _refreshPhotoList();
    _update((s) => s.copyWith(
          caption: CaptionPhase.success(caption: caption, altText: altText),
        ));
  }

  /// リトライ。保存だけ失敗している場合は再生成せず保存のみやり直す。
  Future<void> retryCaption(UploadedPhoto photo, File processedFile) async {
    final phase = state.caption;
    if (phase is CaptionFailure &&
        (phase.partialCaption?.isNotEmpty ?? false)) {
      final repo = ref.read(aiGenerateRepositoryProvider);
      await _saveCaption(
        repo,
        photo.id,
        caption: phase.partialCaption!,
        altText: phase.partialAltText,
      );
      return;
    }
    await generateCaption(photo, processedFile);
  }

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
