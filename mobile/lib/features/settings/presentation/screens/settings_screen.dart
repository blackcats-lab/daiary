import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: const [
          ListTile(title: Text('プラン'), subtitle: Text('未実装')),
          ListTile(title: Text('テーマ'), subtitle: Text('未実装')),
          ListTile(title: Text('通知'), subtitle: Text('未実装')),
          ListTile(title: Text('ストレージ'), subtitle: Text('未実装')),
        ],
      ),
    );
  }
}
