import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// 추후 Firebase, APIClient, Local DB 등을 여기서 초기화할 수 있습니다.
Future<void> initDependencies() async {
  // TODO: Firebase.initializeApp() 등 초기 세팅 추가
}
