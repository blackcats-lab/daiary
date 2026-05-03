import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'd',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 72),
              ),
              const SizedBox(height: 8),
              Text(
                '写真に、言葉を添えて。',
                style: theme.textTheme.bodyMedium,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('はじめる'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
