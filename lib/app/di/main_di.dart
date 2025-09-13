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
    // If google-services configs are present (Android/iOS), this succeeds without options.
    // For Web/Desktop, configure via FlutterFire (DefaultFirebaseOptions) separately.
    await Firebase.initializeApp();
  } catch (e, st) {
    elog('Firebase init failed: $e', st);
  }
}
