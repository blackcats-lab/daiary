import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/ai_generate_failure.dart';
import '../../../photo/domain/entities/uploaded_photo.dart';
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
          .generate(widget.photo, widget.processedFile);
    });
  }

  Future<void> _copyTags(List<String> hashtags) async {
    await Clipboard.setData(ClipboardData(text: hashtags.join(' ')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('コピーしました')),
    );
  }

  void _goHome() => context.go('/home');

  Future<void> _retry() => ref
      .read(aiGenerateProvider.notifier)
      .retry(widget.photo, widget.processedFile);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiGenerateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI で言葉を添える'),
        automaticallyImplyLeading: false,
      ),
      body: switch (state) {
        AiGenerateIdle() ||
        AiGenerateGenerating() =>
          const _ProgressView(label: 'タグを生成中…'),
        AiGenerateSaving() => const _ProgressView(label: '保存中…'),
        AiGenerateSuccess(:final hashtags) => _SuccessView(
            thumbnail: widget.processedFile,
            hashtags: hashtags,
            onCopy: () => _copyTags(hashtags),
            onDone: _goHome,
          ),
        AiGenerateFailureState(:final failure, :final partialHashtags) =>
          _FailureView(
            failure: failure,
            partialHashtags: partialHashtags,
            thumbnail: widget.processedFile,
            onRetry: _retry,
            onSkip: _goHome,
          ),
      },
    );
  }
}

class _ProgressView extends StatelessWidget {
  const _ProgressView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({
    required this.thumbnail,
    required this.hashtags,
    required this.onCopy,
    required this.onDone,
  });

  final File thumbnail;
  final List<String> hashtags;
  final VoidCallback onCopy;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  thumbnail,
                  height: 160,
                  width: 160,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '生成されたハッシュタグ',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final tag in hashtags) Chip(label: Text(tag)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy),
              label: const Text('コピー'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: onDone,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('完了'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.failure,
    required this.partialHashtags,
    required this.thumbnail,
    required this.onRetry,
    required this.onSkip,
  });

  final AiGenerateFailure failure;
  final List<String>? partialHashtags;
  final File thumbnail;
  final VoidCallback onRetry;
  final VoidCallback onSkip;

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
    final tags = partialHashtags;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  thumbnail,
                  height: 120,
                  width: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 8),
            Text(_message, textAlign: TextAlign.center),
            if (tags != null && tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '（生成済みのタグ。保存はできていません）',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [for (final tag in tags) Chip(label: Text(tag))],
                  ),
                ),
              ),
            ] else
              const Spacer(),
            if (_canRetry) ...[
              FilledButton(
                onPressed: onRetry,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('リトライ'),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onSkip,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('スキップしてホームへ'),
                ),
              ),
            ] else
              FilledButton(
                onPressed: onSkip,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('ホームへ'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
