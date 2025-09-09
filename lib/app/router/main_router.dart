import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/gallery/gallery_page.dart';
import '../../features/viewer/viewer_page.dart';
import '../debug/debug_settings.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    observers: [
      LoggingNavigatorObserver(),
    ],
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryPage(),
      ),
      GoRoute(
        path: '/viewer',
        name: 'viewer',
        builder: (context, state) {
          final asset = state.extra; // 선택된 사진 전달
          return ViewerPage(asset: asset);
        },
      ),
    ],
  );
}
