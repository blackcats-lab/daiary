import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/exceptions/album_failure.dart';
import '../providers/album_detail_notifier.dart';
import '../providers/album_detail_state.dart';

class AlbumEditScreen extends ConsumerStatefulWidget {
  const AlbumEditScreen({super.key, required this.albumId});

  final String albumId;

  @override
  ConsumerState<AlbumEditScreen> createState() => _AlbumEditScreenState();
}

class _AlbumEditScreenState extends ConsumerState<AlbumEditScreen> {
  static const int _maxNameLength = 100;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final state = ref.read(albumDetailProvider(widget.albumId));
    final initial = state is AlbumDetailLoaded ? state.detail.album.name : '';
    _controller = TextEditingController(text: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(albumDetailProvider(widget.albumId).notifier)
          .updateName(_controller.text);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('アルバムを更新しました')),
      );
      context.pop();
    } on AlbumFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('更新に失敗しました: $e')));
    }
  }

  Future<void> _confirmDelete() async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('アルバムを削除'),
        content: const Text('このアルバムを削除しますか？\n（写真自体は削除されません）'),
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
      await ref
          .read(albumDetailProvider(widget.albumId).notifier)
          .deleteAlbum();
      if (!mounted) return;
      // 詳細画面を経由せず直接 /albums に戻る
      context.go('/albums');
    } on AlbumFailure catch (f) {
      messenger.showSnackBar(SnackBar(content: Text(f.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(albumDetailProvider(widget.albumId));
    final loaded = state is AlbumDetailLoaded ? state : null;
    final updating = loaded?.updating ?? false;
    final deleting = loaded?.deleting ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('アルバムを編集')),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _controller,
                      maxLength: _maxNameLength,
                      enabled: !updating && !deleting,
                      decoration: const InputDecoration(
                        labelText: 'アルバム名',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'アルバム名を入力してください';
                        if (v.length > _maxNameLength) {
                          return '$_maxNameLength 字以内で入力してください';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _save(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: updating || deleting ? null : _save,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('保存'),
                      ),
                    ),
                    const Divider(height: 48),
                    TextButton.icon(
                      onPressed: deleting ? null : _confirmDelete,
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      label: const Text(
                        'アルバムを削除',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (updating || deleting)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
