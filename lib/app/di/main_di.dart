import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../debug/debug_settings.dart';

/// 전역 ProviderContainer
final globalProviderContainer = ProviderContainer();

/// 앱에서 공용으로 쓰는 provider 예시
final appTitleProvider = Provider<String>((ref) {
  return 'Filmin';
});

/// 앱 테마 모드 (system/light/dark)
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

/// 온보딩에서 선택/미리보기할 이미지 경로들
final pickedImagesProvider = StateProvider<List<String>>((ref) => <String>[]);

/// 추후 Firebase, APIClient, Local DB 등을 여기서 초기화할 수 있습니다.
Future<void> initDependencies() async {
  // Firebase initialize (requires google-services files on mobile or web options).
  try {
    // Initialize only if no app exists yet. This avoids duplicate init and errors.
    if (Firebase.apps.isEmpty) {
      // If google-services configs are present (Android/iOS), this succeeds without options.
      // For Web/Desktop, configure via FlutterFire (DefaultFirebaseOptions) separately.
      await Firebase.initializeApp();
    }
  } catch (e, st) {
    // Downgrade to warning to avoid noisy hard errors when configs are missing.
    wlog('Firebase init failed: $e', st);
  }
}

/// Firebase 초기화를 Provider로 노출하여, 의존 Provider가 안전하게 대기하도록 함.
final firebaseInitProvider = FutureProvider<bool>((ref) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    return true;
  } catch (e, st) {
    wlog('Firebase init (provider) failed: $e', st);
    return false; // gracefully degrade
  }
});
