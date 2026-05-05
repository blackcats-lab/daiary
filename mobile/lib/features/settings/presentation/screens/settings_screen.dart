import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_notifier.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    final email = user?.email;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          if (email != null)
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('ログイン中のアカウント'),
              subtitle: Text(email),
            ),
          const ListTile(title: Text('プラン'), subtitle: Text('未実装')),
          const ListTile(title: Text('テーマ'), subtitle: Text('未実装')),
          const ListTile(title: Text('通知'), subtitle: Text('未実装')),
          const ListTile(title: Text('ストレージ'), subtitle: Text('未実装')),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('キャンセル')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('ログアウト')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(authProvider.notifier).signOut();
    // 遷移は router の redirect が処理する
  }
}
