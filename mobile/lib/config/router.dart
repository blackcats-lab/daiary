import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/ai_generate/presentation/screens/ai_generate_screen.dart';
import '../features/album/presentation/screens/album_create_screen.dart';
import '../features/album/presentation/screens/album_list_screen.dart';
import '../features/auth/presentation/providers/auth_notifier.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/camera/domain/entities/captured_image.dart';
import '../features/camera/presentation/screens/camera_screen.dart';
import '../features/camera/presentation/screens/capture_preview_screen.dart';
import '../features/photo/domain/entities/uploaded_photo.dart';
import '../features/photo/presentation/screens/home_screen.dart';
import '../features/photo/presentation/screens/photo_detail_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';

/// 認証不要なパス（ログイン前でもアクセス可）
const _publicPaths = {'/login', '/signup', '/splash'};

/// アプリ全体のルーティング定義。
/// 画面構成出典: docs/dAIary_screen_layouts.jsx
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final loc = state.matchedLocation;

      final isLoggedIn = user != null;
      final isPublic = _publicPaths.contains(loc);

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && (isPublic || loc == '/splash')) return '/home';
      // /splash は _publicPaths に含まれるが、未ログインなら /login に進める
      if (!isLoggedIn && loc == '/splash') return '/login';
      return null;
    },
    routes: [
      GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (_, __) => const SignupScreen()),
      GoRoute(
          path: '/home', name: 'home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/camera',
        name: 'camera',
        builder: (_, __) => const CameraScreen(),
        routes: [
          GoRoute(
            path: 'preview',
            name: 'camera-preview',
            builder: (_, state) => CapturePreviewScreen(
              image: state.extra! as CapturedImage,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/photo/:id',
        name: 'photo-detail',
        builder: (_, state) =>
            PhotoDetailScreen(photoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ai-generate',
        name: 'ai-generate',
        builder: (_, state) {
          final args = state.extra! as ({
            UploadedPhoto photo,
            File processedFile,
          });
          return AiGenerateScreen(
            photo: args.photo,
            processedFile: args.processedFile,
          );
        },
      ),
      GoRoute(
        path: '/albums',
        name: 'albums',
        builder: (_, __) => const AlbumListScreen(),
        routes: [
          GoRoute(
            path: 'new',
            name: 'album-new',
            builder: (_, __) => const AlbumCreateScreen(),
          ),
        ],
      ),
      GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (_, __) => const SettingsScreen()),
    ],
  );
});

/// authProvider の変化を GoRouter に通知する Listenable アダプタ。
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(this._ref) {
    _sub = _ref.listen(authProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}
