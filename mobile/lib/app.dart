import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/router.dart';
import 'config/theme.dart';

class DaiaryApp extends ConsumerWidget {
  const DaiaryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'dAIary',
      theme: DaiaryTheme.light(),
      darkTheme: DaiaryTheme.dark(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
