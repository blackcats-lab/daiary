import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/exceptions/photo_failure.dart';
import '../../domain/entities/photo_detail.dart';
import '../../domain/entities/uploaded_photo.dart';
import '../providers/photo_detail_notifier.dart';
import '../providers/photo_detail_state.dart';
import '../widgets/caption_edit_sheet.dart';
import '../widgets/tag_edit_sheet.dart';

class PhotoDetailScreen extends ConsumerStatefulWidget {
  const PhotoDetailScreen({super.key, required this.photoId});

  final String photoId;

  @override
  ConsumerState<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends ConsumerState<PhotoDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(photoDetailProvider(widget.photoId).notifier).load();
    });
  }

  Future<void> _toggleFavorite() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(photoDetailProvider(widget.photoId).notifier)
          .toggleFavorite();
    } on PhotoFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  Future<void> _share(PhotoDetail detail) async {
    final notifier = ref.read(photoDetailProvider(widget.photoId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    notifier.setSharing(true);
    try {
      final file = await notifier.prepareLocalFile();
      if (file == null) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/jpeg')],
          text: detail.caption ?? '',
        ),
      );
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('共有に失敗しました: $e')),
        );
      }
    } finally {
      // 画面 pop 済みなら autoDispose された notifier に触らない
      if (mounted) notifier.setSharing(false);
    }
  }

  /// 詳細画面から AI 生成画面へ遷移する。
  /// Storage から原寸を一時ファイルにダウンロードして UploadedPhoto を再構成し、
  /// 既存 /ai-generate ルートに渡す。autoStart=false で待機状態の画面を開く。
  Future<void> _goToAiGenerate(PhotoDetail detail) async {
    final notifier = ref.read(photoDetailProvider(widget.photoId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    notifier.setPreparingAi(true);
    try {
      final file = await notifier.prepareLocalFile();
      if (file == null) return;
      if (!mounted) return;
      await context.push(
        '/ai-generate',
        extra: (
          photo: _toUploaded(detail),
          processedFile: file,
          autoStart: false,
        ),
      );
      // 戻ってきたら caption / tags を最新化
      if (!mounted) return;
      await ref.read(photoDetailProvider(widget.photoId).notifier).load();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('画像の取得に失敗しました: $e')),
        );
      }
    } finally {
      // 画面 pop 済みなら autoDispose された notifier に触らない
      // （setPreparingAi は内部で state を読むため dispose 後の呼び出しは StateError になる）
      if (mounted) notifier.setPreparingAi(false);
    }
  }

  /// PhotoDetail → UploadedPhoto。thumbnailPath が無い場合は storagePath を fallback。
  UploadedPhoto _toUploaded(PhotoDetail d) => UploadedPhoto(
        id: d.id,
        storagePath: d.storagePath,
        thumbnailPath: d.thumbnailPath ?? d.storagePath,
        createdAt: d.createdAt,
      );

  Future<void> _editCaption(PhotoDetail detail) async {
    final messenger = ScaffoldMessenger.of(context);
    final result =
        await CaptionEditSheet.show(context, initial: detail.caption);
    if (result == null) return; // キャンセル
    try {
      await ref
          .read(photoDetailProvider(widget.photoId).notifier)
          .updateCaption(result);
    } on PhotoFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  Future<void> _editTags(PhotoDetail detail) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await TagEditSheet.show(context, initial: detail.aiTags);
    if (result == null) return; // キャンセル
    try {
      await ref
          .read(photoDetailProvider(widget.photoId).notifier)
          .updateTags(result);
    } on PhotoFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  /// 写真編集画面へ遷移する。原寸を一時ファイルに落として渡し、
  /// 戻ったらキャッシュバスター付きで再取得する。
  Future<void> _goToEdit(PhotoDetail detail) async {
    final notifier = ref.read(photoDetailProvider(widget.photoId).notifier);
    final messenger = ScaffoldMessenger.of(context);
    notifier.setPreparingAi(true);
    try {
      final file = await notifier.prepareLocalFile();
      if (file == null || !mounted) return;
      final result = await context.push<bool>(
        '/photo/${widget.photoId}/edit',
        extra: (
          sourceFile: file,
          storagePath: detail.storagePath,
          thumbnailPath: detail.thumbnailPath ?? detail.storagePath,
        ),
      );
      if (!mounted) return;
      if (result == true) {
        await notifier.reloadAfterEdit();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('画像の取得に失敗しました: $e')));
      }
    } finally {
      if (mounted) notifier.setPreparingAi(false);
    }
  }

  Future<void> _confirmDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('写真を削除'),
        content: const Text('この写真を削除しますか？\n（30 日以内なら復元可能です）'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(photoDetailProvider(widget.photoId).notifier).delete();
    } on PhotoFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('削除に失敗しました: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(photoDetailProvider(widget.photoId));

    // 削除完了時にホームへ戻す
    ref.listen<PhotoDetailState>(photoDetailProvider(widget.photoId),
        (prev, next) {
      if (next is PhotoDetailLoaded && next.deleted) {
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('写真'),
        actions: [
          if (state is PhotoDetailLoaded) ...[
            IconButton(
              icon: Icon(
                state.detail.isFavorite
                    ? Icons.favorite
                    : Icons.favorite_border,
                color: state.detail.isFavorite ? Colors.redAccent : null,
              ),
              tooltip: 'お気に入り',
              onPressed: state.favoriteUpdating ? null : _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: '編集',
              onPressed:
                  state.preparingAi ? null : () => _goToEdit(state.detail),
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: '共有',
              onPressed: state.sharing ? null : () => _share(state.detail),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '削除',
              onPressed: state.deleting ? null : _confirmDelete,
            ),
          ],
        ],
      ),
      body: switch (state) {
        PhotoDetailInitial() ||
        PhotoDetailLoading() =>
          const Center(child: CircularProgressIndicator()),
        PhotoDetailError(:final failure) => _ErrorView(
            message: failure.message,
            onRetry: () =>
                ref.read(photoDetailProvider(widget.photoId).notifier).load(),
          ),
        PhotoDetailLoaded() => _LoadedView(
            state: state,
            onGoToAiGenerate: () => _goToAiGenerate(state.detail),
            onEditCaption: () => _editCaption(state.detail),
            onEditTags: () => _editTags(state.detail),
          ),
      },
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.state,
    required this.onGoToAiGenerate,
    required this.onEditCaption,
    required this.onEditTags,
  });

  final PhotoDetailLoaded state;
  final VoidCallback onGoToAiGenerate;
  final VoidCallback onEditCaption;
  final VoidCallback onEditTags;

  @override
  Widget build(BuildContext context) {
    final d = state.detail;
    final ratio = (d.width != null && d.height != null && d.width! > 0)
        ? d.width! / d.height!
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1) 原寸画像
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: ratio ?? 1.0,
              child: state.signedOriginalUrl == null
                  ? const ColoredBox(
                      color: Color(0xFFEEEEEE),
                      child: Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: state.signedOriginalUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // 2) caption（編集可能）
          _SectionHeader(
            title: 'キャプション',
            onEdit: state.metaUpdating ? null : onEditCaption,
          ),
          if (d.caption != null && d.caption!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                d.caption!,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
            )
          else
            const Text(
              'キャプションはまだありません',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 12),

          // 3) ai_tags（編集可能）
          _SectionHeader(
            title: 'タグ',
            onEdit: state.metaUpdating ? null : onEditTags,
          ),
          if (d.aiTags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final t in d.aiTags)
                  Chip(
                    label: Text(t.startsWith('#') ? t : '#$t'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            )
          else
            const Text(
              'タグはまだありません',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          const SizedBox(height: 12),

          // 4) alt_text
          if (d.altText != null && d.altText!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '代替テキスト: ${d.altText!}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
          ],

          // 5) EXIF / 基本情報
          _MetadataSection(detail: d),

          const SizedBox(height: 24),

          // 6) AI 生成入口
          FilledButton.icon(
            onPressed: state.preparingAi ? null : onGoToAiGenerate,
            icon: state.preparingAi
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                state.preparingAi ? '画像を準備中…' : 'AI で言葉を添える',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onEdit});

  final String title;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: '編集',
          visualDensity: VisualDensity.compact,
          onPressed: onEdit,
        ),
      ],
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.detail});

  final PhotoDetail detail;

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[];

    if (detail.width != null && detail.height != null) {
      rows.add(('サイズ', '${detail.width} × ${detail.height}'));
    }
    if (detail.fileSize != null) {
      rows.add(('ファイルサイズ', _formatBytes(detail.fileSize!)));
    }
    if (detail.originalFilename != null) {
      rows.add(('ファイル名', detail.originalFilename!));
    }
    rows.add(('撮影日時', _formatDate(detail.createdAt.toLocal())));

    const exifLabels = {
      'DateTimeOriginal': '撮影日時 (EXIF)',
      'Make': 'メーカー',
      'Model': 'カメラ',
      'FNumber': '絞り',
      'ExposureTime': 'シャッター',
      'ISO': 'ISO',
      'FocalLength': '焦点距離',
    };
    for (final entry in exifLabels.entries) {
      final v = detail.exifData[entry.key];
      if (v != null && v.toString().isNotEmpty) {
        rows.add((entry.value, v.toString()));
      }
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '情報',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          for (final (k, v) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      k,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      v,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  static String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('再試行')),
        ],
      ),
    );
  }
}
