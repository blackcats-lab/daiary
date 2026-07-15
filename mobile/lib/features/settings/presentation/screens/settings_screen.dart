import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            leading: const Icon(Icons.delete_outline),
            title: const Text('ゴミ箱'),
            subtitle: const Text('削除した写真（30 日後に自動削除）'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/trash'),
          ),
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
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authProvider.notifier).signOut();
      // 遷移は router の redirect が処理する
    } catch (_) {
      // オフライン等で signOut が失敗すると未処理例外になり、
      // ユーザーには何も起きていないように見えるためフィードバックを出す
      messenger.showSnackBar(
        const SnackBar(content: Text('ログアウトに失敗しました。通信環境を確認してください')),
      );
    }
  }
}
