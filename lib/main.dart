import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router/main_router.dart';
import 'app/theme/main_theme.dart';
import 'app/di/main_di.dart';
import 'app/debug/debug_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  await runWithDebugGuard(() async {
    runApp(ProviderScope(
      observers: [AppProviderObserver()],
      child: const FilminApp(),
    ));
  });
}

class FilminApp extends ConsumerWidget {
  const FilminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: ref.watch(appTitleProvider),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: AppRouter.router,
    );
  }
}
