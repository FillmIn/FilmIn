import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/di/main_di.dart';
import 'widgets/onboarding_hero.dart';
import 'widgets/onboarding_intro_text.dart';
import 'widgets/firebase_image_grid_section.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/icon/logoWhite.png'
        : 'assets/icon/logoBlack.png';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, ref, logoAsset, isDark),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.of(context).size;
          return Stack(
            children: [
              // 스크롤 가능한 콘텐츠
              _buildScrollableContent(context, size),

              // 하단 그라데이션 오버레이
              _buildBottomGradient(context),

              // 하단 고정 버튼
              _buildFixedButton(context, ref, isDark),
            ],
          );
        },
      ),
    );
  }

  /// AppBar 빌드
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    String logoAsset,
    bool isDark,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Image.asset(logoAsset, height: 100, fit: BoxFit.contain),
      actions: [
        IconButton(
          tooltip: 'Theme',
          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => _toggleTheme(ref, isDark),
        ),
      ],
    );
  }

  /// 테마 토글
  void _toggleTheme(WidgetRef ref, bool isDark) {
    final mode = ref.read(themeModeProvider);
    ThemeMode next;
    if (mode == ThemeMode.system) {
      next = isDark ? ThemeMode.light : ThemeMode.dark;
    } else if (mode == ThemeMode.dark) {
      next = ThemeMode.light;
    } else {
      next = ThemeMode.dark;
    }
    ref.read(themeModeProvider.notifier).state = next;
  }

  /// 스크롤 가능한 메인 콘텐츠
  Widget _buildScrollableContent(BuildContext context, Size size) {
    final surfaceColor = Theme.of(context).colorScheme.surface;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero image
          OnboardingHero(
            height: size.height * 0.58,
            surfaceColor: surfaceColor,
          ),

          // 본문 카드 영역
          Container(
            color: surfaceColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 13, 20, 0),
                  child: FadedIntroText(
                    theme: Theme.of(context).textTheme,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                // Firebase Storage 이미지 그리드
                const FirebaseImageGridSection(),

                // 하단 여백을 추가하여 버튼과 겹치지 않도록 함
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 하단 그라데이션 오버레이
  Widget _buildBottomGradient(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                Theme.of(context).colorScheme.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  /// 하단 고정 버튼
  Widget _buildFixedButton(BuildContext context, WidgetRef ref, bool isDark) {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.7,
          child: ElevatedButton(
            onPressed: () => _pickImageFromGallery(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.2),
              foregroundColor: isDark ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(52),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.3),
            ),
            child: const Text('Grab your Photo'),
          ),
        ),
      ),
    );
  }

  /// 갤러리에서 이미지 선택
  Future<void> _pickImageFromGallery(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && context.mounted) {
      // 리스트에 추가해두면 온보딩 그리드 등에서도 보일 수 있음
      final list = [...ref.read(pickedImagesProvider)];
      list.insert(0, image.path);
      ref.read(pickedImagesProvider.notifier).state = list;
      if (context.mounted) {
        context.push('/editview', extra: image.path);
      }
    }
  }
}
