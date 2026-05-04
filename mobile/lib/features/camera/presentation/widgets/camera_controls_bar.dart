import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraControlsBar extends StatelessWidget {
  const CameraControlsBar({
    super.key,
    required this.flash,
    required this.onShutter,
    required this.onSwitchLens,
    required this.onCycleFlash,
    required this.onPickFromGallery,
    required this.busy,
  });

  final FlashMode flash;
  final VoidCallback onShutter;
  final VoidCallback onSwitchLens;
  final VoidCallback onCycleFlash;
  final VoidCallback onPickFromGallery;
  final bool busy;

  IconData get _flashIcon => switch (flash) {
        FlashMode.off => Icons.flash_off,
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        FlashMode.torch => Icons.flashlight_on,
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        color: Colors.black.withValues(alpha: 0.6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              iconSize: 32,
              color: Colors.white,
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: busy ? null : onPickFromGallery,
              tooltip: 'ギャラリーから選択',
            ),
            GestureDetector(
              onTap: busy ? null : onShutter,
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: busy ? Colors.white54 : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                IconButton(
                  iconSize: 28,
                  color: Colors.white,
                  icon: Icon(_flashIcon),
                  onPressed: busy ? null : onCycleFlash,
                  tooltip: 'フラッシュ切替',
                ),
                IconButton(
                  iconSize: 28,
                  color: Colors.white,
                  icon: const Icon(Icons.cameraswitch_outlined),
                  onPressed: busy ? null : onSwitchLens,
                  tooltip: '前後切替',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
