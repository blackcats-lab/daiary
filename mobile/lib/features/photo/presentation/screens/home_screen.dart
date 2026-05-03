import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('dAIary')),
      body: const Center(child: Text('Phase 1 で写真一覧を実装予定')),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/camera');
            case 2:
              context.go('/albums');
            case 3:
              context.go('/settings');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), label: '写真'),
          NavigationDestination(icon: Icon(Icons.camera_alt_outlined), label: 'カメラ'),
          NavigationDestination(icon: Icon(Icons.collections_outlined), label: 'アルバム'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '設定'),
        ],
      ),
    );
  }
}
