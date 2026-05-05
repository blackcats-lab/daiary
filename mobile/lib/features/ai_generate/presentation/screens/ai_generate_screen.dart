import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/ai_generate_failure.dart';
import '../../../photo/domain/entities/uploaded_photo.dart';
import '../../domain/entities/caption_options.dart';
import '../providers/ai_generate_notifier.dart';
import '../providers/ai_generate_state.dart';

class AiGenerateScreen extends ConsumerStatefulWidget {
  const AiGenerateScreen({
    super.key,
    required this.photo,
    required this.processedFile,
  });

  final UploadedPhoto photo;
  final File processedFile;

  @override
  ConsumerState<AiGenerateScreen> createState() => _AiGenerateScreenState();
}

class _AiGenerateScreenState extends ConsumerState<AiGenerateScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(aiGenerateProvider.notifier)
          .generateHashtags(widget.photo, widget.processedFile);
    });
  }

  Future<void> _copyText(String text, String snack) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(snack)));
  }

  void _goHome() => context.go('/home');

  Future<void> _retryHashtags() => ref
      .read(aiGenerateProvider.notifier)
      .retryHashtags(widget.photo, widget.processedFile);

  Future<void> _generateCaption() => ref
      .read(aiGenerateProvider.notifier)
      .generateCaption(widget.photo, widget.processedFile);

  Future<void> _retryCaption() => ref
      .read(aiGenerateProvider.notifier)
      .retryCaption(widget.photo, widget.processedFile);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiGenerateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI で言葉を添える'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          widget.processedFile,
                          height: 160,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _HashtagSection(
                      phase: state.hashtag,
                      onCopy: (tags) => _copyText(tags.join(' '), 'コピーしました'),
                      onRetry: _retryHashtags,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    _CaptionSection(
                      phase: state.caption,
                      style: state.selectedStyle,
                      length: state.selectedLength,
                      onStyleChanged: (s) =>
                          ref.read(aiGenerateProvider.notifier).setStyle(s),
                      onLengthChanged: (l) =>
                          ref.read(aiGenerateProvider.notifier).setLength(l),
                      onGenerate: _generateCaption,
                      onRetry: _retryCaption,
                      onCopy: (text) => _copyText(text, 'コピーしました'),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _goHome,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('ホームに戻る'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Hashtag section
// ============================================================================

class _HashtagSection extends StatelessWidget {
  const _HashtagSection({
    required this.phase,
    required this.onCopy,
    required this.onRetry,
  });

  final HashtagPhase phase;
  final void Function(List<String> tags) onCopy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'ハッシュタグ',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (phase is HashtagSuccess)
              IconButton(
                icon: const Icon(Icons.copy, size: 18),
                tooltip: 'コピー',
                onPressed: () => onCopy((phase as HashtagSuccess).hashtags),
              ),
          ],
        ),
        const SizedBox(height: 4),
        switch (phase) {
          HashtagIdle() ||
          HashtagGenerating() ||
          HashtagSaving() =>
            const _InlineProgress(label: 'タグを生成中…'),
          HashtagSuccess(:final hashtags) => Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [for (final t in hashtags) Chip(label: Text(t))],
            ),
          HashtagFailure(:final failure, :final partialHashtags) =>
            _FailureBlock(
              failure: failure,
              partialView: partialHashtags == null || partialHashtags.isEmpty
                  ? null
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final t in partialHashtags) Chip(label: Text(t)),
                      ],
                    ),
              onRetry: onRetry,
            ),
        },
      ],
    );
  }
}

// ============================================================================
// Caption section
// ============================================================================

class _CaptionSection extends StatelessWidget {
  const _CaptionSection({
    required this.phase,
    required this.style,
    required this.length,
    required this.onStyleChanged,
    required this.onLengthChanged,
    required this.onGenerate,
    required this.onRetry,
    required this.onCopy,
  });

  final CaptionPhase phase;
  final CaptionStyle style;
  final CaptionLength length;
  final ValueChanged<CaptionStyle> onStyleChanged;
  final ValueChanged<CaptionLength> onLengthChanged;
  final VoidCallback onGenerate;
  final VoidCallback onRetry;
  final void Function(String text) onCopy;

  bool get _busy => phase is CaptionGenerating || phase is CaptionSaving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'キャプション',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        const Text(
          'スタイル',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<CaptionStyle>(
            segments: [
              for (final s in CaptionStyle.values)
                ButtonSegment(value: s, label: Text(s.label)),
            ],
            selected: {style},
            showSelectedIcon: false,
            onSelectionChanged:
                _busy ? null : (selection) => onStyleChanged(selection.first),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '文章の長さ',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        SegmentedButton<CaptionLength>(
          segments: [
            for (final l in CaptionLength.values)
              ButtonSegment(value: l, label: Text(l.label)),
          ],
          selected: {length},
          showSelectedIcon: false,
          onSelectionChanged:
              _busy ? null : (selection) => onLengthChanged(selection.first),
        ),
        const SizedBox(height: 16),
        switch (phase) {
          CaptionIdle() => Center(
              child: FilledButton.icon(
                onPressed: onGenerate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('投稿文を生成'),
              ),
            ),
          CaptionGenerating() => const _InlineProgress(label: '投稿文を生成中…'),
          CaptionSaving() => const _InlineProgress(label: '保存中…'),
          CaptionSuccess(:final caption) => _CaptionResultView(
              caption: caption,
              onCopy: () => onCopy(caption),
              onRetry: onRetry,
              busy: false,
            ),
          CaptionFailure(:final failure, :final partialCaption) =>
            _FailureBlock(
              failure: failure,
              partialView: partialCaption == null || partialCaption.isEmpty
                  ? null
                  : _CaptionResultView(
                      caption: partialCaption,
                      onCopy: () => onCopy(partialCaption),
                      onRetry: onRetry,
                      busy: false,
                      hint: '（生成済みですが保存はできていません）',
                    ),
              onRetry: onRetry,
            ),
        },
        const SizedBox(height: 8),
        const Text(
          '※ 再生成のたびに本日の利用回数を 1 回消費します',
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _CaptionResultView extends StatelessWidget {
  const _CaptionResultView({
    required this.caption,
    required this.onCopy,
    required this.onRetry,
    required this.busy,
    this.hint,
  });

  final String caption;
  final VoidCallback onCopy;
  final VoidCallback onRetry;
  final bool busy;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            caption,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint!,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: busy ? null : onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('再生成'),
            ),
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: busy ? null : onCopy,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('コピー'),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================================
// Common helpers
// ============================================================================

class _InlineProgress extends StatelessWidget {
  const _InlineProgress({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _FailureBlock extends StatelessWidget {
  const _FailureBlock({
    required this.failure,
    required this.partialView,
    required this.onRetry,
  });

  final AiGenerateFailure failure;
  final Widget? partialView;
  final VoidCallback onRetry;

  bool get _canRetry =>
      failure.code == 'network' || failure.code == 'service_failed';

  String get _message {
    if (failure.code == 'rate_limited') {
      final r = failure.remaining ?? 0;
      final l = failure.limit ?? 0;
      return '今日の上限に達しました（残り $r / $l）';
    }
    return failure.message;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(_message, style: const TextStyle(fontSize: 13)),
            ),
            if (_canRetry)
              TextButton(onPressed: onRetry, child: const Text('リトライ')),
          ],
        ),
        if (partialView != null) ...[
          const SizedBox(height: 8),
          partialView!,
        ],
      ],
    );
  }
}
