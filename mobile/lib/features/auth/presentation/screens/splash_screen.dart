import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme.dart';
import '../widgets/daiary_logo.dart';

/// 起動直後にセッション復元を待つ画面。
/// auth 状態が確定したら router の redirect が /home or /login に遷移させる。
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [DaiaryColors.cream, Color(0xFFEBE3D8)],
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DaiaryLogo(),
                SizedBox(height: 48),
                CircularProgressIndicator(
                  strokeWidth: 2,
                  color: DaiaryColors.brandGold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
