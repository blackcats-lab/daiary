import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_generate/presentation/screens/ai_generate_screen.dart';
import '../features/album/presentation/screens/album_list_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/photo/presentation/screens/home_screen.dart';
import '../features/photo/presentation/screens/photo_detail_screen.dart';

/// アプリ全体のルーティング定義。
/// 画面構成出典: docs/dAIary_screen_layouts.jsx
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/home', name: 'home', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/camera',
          name: 'camera',
          builder: (_, __) => const CameraScreen()),
      GoRoute(
        path: '/photo/:id',
        name: 'photo-detail',
        builder: (_, state) =>
            PhotoDetailScreen(photoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ai-generate',
        name: 'ai-generate',
        builder: (_, __) => const AiGenerateScreen(),
      ),
      GoRoute(
          path: '/albums',
          name: 'albums',
          builder: (_, __) => const AlbumListScreen()),
      GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (_, __) => const SettingsScreen()),
    ],
  );
});
