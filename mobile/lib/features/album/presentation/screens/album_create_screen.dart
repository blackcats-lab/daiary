import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/album_create_notifier.dart';
import '../providers/album_create_state.dart';

class AlbumCreateScreen extends ConsumerStatefulWidget {
  const AlbumCreateScreen({super.key});

  @override
  ConsumerState<AlbumCreateScreen> createState() => _AlbumCreateScreenState();
}

class _AlbumCreateScreenState extends ConsumerState<AlbumCreateScreen> {
  static const int _maxNameLength = 100;

  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(albumCreateProvider.notifier).create(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(albumCreateProvider);

    // success / failure を listen して画面遷移 / SnackBar
    ref.listen<AlbumCreateState>(albumCreateProvider, (prev, next) {
      if (next is AlbumCreateSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('アルバムを作成しました')),
        );
        ref.read(albumCreateProvider.notifier).reset();
        context.pop();
      } else if (next is AlbumCreateFailure) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.failure.message)));
      }
    });

    final submitting = state is AlbumCreateSubmitting;

    return Scaffold(
      appBar: AppBar(title: const Text('新しいアルバム')),
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
                      enabled: !submitting,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'アルバム名',
                        hintText: '夏の思い出 / 旅行 2026 など',
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
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: submitting ? null : _submit,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('作成'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (submitting)
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
