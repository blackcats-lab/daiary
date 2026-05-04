import 'package:flutter/material.dart';

class PhotoDetailScreen extends StatelessWidget {
  const PhotoDetailScreen({required this.photoId, super.key});

  final String photoId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('写真 $photoId')),
      body: const Center(child: Text('Phase 1 で写真詳細を実装予定')),
    );
  }
}
