import 'package:flutter/material.dart';

class AlbumListScreen extends StatelessWidget {
  const AlbumListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('アルバム')),
      body: const Center(child: Text('Phase 1 / Sprint 3 で実装予定')),
    );
  }
}
