import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('カメラ'),
      ),
      body: const Center(
        child: Text(
          'Phase 1 でカメラを実装予定',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
