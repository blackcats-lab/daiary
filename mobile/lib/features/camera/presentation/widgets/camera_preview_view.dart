import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewView extends StatelessWidget {
  const CameraPreviewView({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    final size = controller.value.previewSize;
    if (size == null) {
      return const ColoredBox(color: Colors.black);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return ClipRect(
          child: SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: size.height,
                height: size.width,
                child: CameraPreview(controller),
              ),
            ),
          ),
        );
      },
    );
  }
}
