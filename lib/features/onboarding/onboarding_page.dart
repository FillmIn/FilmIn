import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/di/main_di.dart';
import 'data/storage_repository.dart';
import 'widgets/img_card.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});
  // 색상 모드 -------------
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark
        ? 'assets/icon/logoWhite.png'
        : 'assets/icon/logoBlack.png';

    final asyncUrls = ref.watch(storageImageUrlsProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset(logoAsset, height: 100, fit: BoxFit.contain),
        actions: [
          IconButton(
            tooltip: 'Theme',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
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
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = MediaQuery.of(context).size;
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero image
                SizedBox(
                  height: size.height * 0.58,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const _EdgeFadeHeroImage(
                        assetPath: 'assets/images/MainBanner.jpg',
                      ),
                      const _TopBottomGradient(),
                      _BottomSurfaceScrim(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ],
                  ),
                ),

                // 본문 카드 영역
                Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FadedIntroText(
                        theme: Theme.of(context).textTheme,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 24),

                      // 미리보기 스택/캐러셀
                      SizedBox(
                        height: 200,
                        child: asyncUrls.when(
                          data: (urls) {
                            final list = urls.isNotEmpty
                                ? urls.take(10).toList()
                                : List.generate(
                                    6,
                                    (i) => 'assets/images/MainBanner.jpg',
                                  );
                            return OnboardingPreviewCarousel(
                              items: list,
                              onTapItem: (index, src) =>
                                  _openPreviewOverlay(context, list, index),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) => OnboardingPreviewCarousel(
                            items: List.generate(
                              6,
                              (i) => 'assets/images/MainBanner.jpg',
                            ),
                            onTapItem: (_, __) {},
                          ),
                        ),
                      ),
                      // 앨범 이동 버튼----------------------------
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: ElevatedButton(
                            onPressed: () => _pickImageFromGallery(context, ref),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(52),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                            child: const Text('Grab your Photo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openPreviewOverlay(
    BuildContext context,
    List<String> items,
    int initialIndex,
  ) {
    if (items.isEmpty) return;
    final safeIndex = initialIndex.clamp(0, items.length - 1);
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        int activeIndex = safeIndex;
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 40,
              ),
              backgroundColor: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: OnboardingOverlayBackdrop(src: items[activeIndex]),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.65),
                              Colors.black.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 16),
                      child: OnboardingOverlayCarousel(
                        items: items,
                        initialIndex: safeIndex,
                        onPageChanged: (value) {
                          setState(() => activeIndex = value);
                        },
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context, WidgetRef ref) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
    );
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

class _TopBottomGradient extends StatelessWidget {
  const _TopBottomGradient();
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.25),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.25),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _BottomSurfaceScrim extends StatelessWidget {
  const _BottomSurfaceScrim({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.0),
                color.withValues(alpha: 0.6),
                color,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: const SizedBox(height: 180, width: double.infinity),
        ),
      ),
    );
  }
}

class _EdgeFadeHeroImage extends StatelessWidget {
  const _EdgeFadeHeroImage({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Colors.white, Colors.white, Colors.transparent],
          stops: const [0.0, 0.72, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }
}

class _FadedIntroText extends StatelessWidget {
  const _FadedIntroText({required this.theme, required this.color});

  final TextTheme theme;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        color.withValues(alpha: 0),
        color.withValues(alpha: 1),
        color.withValues(alpha: 1),
        color,
      ],
      stops: const [0.0, 0.35, 0.7, 1.0],
    );

    return ShaderMask(
      shaderCallback: (rect) {
        final extended = Rect.fromLTWH(
          rect.left,
          rect.top - 48,
          rect.width,
          rect.height + 48,
        );
        return gradient.createShader(extended);
      },
      blendMode: BlendMode.srcIn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter name',
            style: theme.displaySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '#비네팅  #색보정  #필름질감',
            style: theme.labelLarge?.copyWith(color: color),
          ),
          const SizedBox(height: 16),
          Text(
            '사진의 감도를 살려주는 필터입니다. 따뜻함과 차가움을 자연스럽게 조절하고 필름 그레인을 더해 감성적인 분위기를 연출합니다.',
            style: theme.bodyMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
