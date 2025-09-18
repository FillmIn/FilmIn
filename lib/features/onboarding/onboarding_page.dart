import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di/main_di.dart';
import 'data/storage_repository.dart';

class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

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
                            return _PreviewCarousel(
                              items: list,
                              onTap: () => _openPreviewOverlay(context, list),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, st) => _PreviewCarousel(
                            items: List.generate(
                              6,
                              (i) => 'assets/images/MainBanner.jpg',
                            ),
                            onTap: () {},
                          ),
                        ),
                      ),
                      // 앨범 이동 버튼----------------------------
                      const SizedBox(height: 24),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: ElevatedButton(
                            onPressed: () => context.push('/gallery'),
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

  void _openPreviewOverlay(BuildContext context, List<String> items) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 40,
          ),
          backgroundColor: Colors.black.withOpacity(0.85),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 16),
                child: _OverlayCarousel(items: items),
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
        );
      },
    );
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
            Colors.black.withOpacity(0.25),
            Colors.transparent,
            Colors.black.withOpacity(0.25),
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
                color.withOpacity(0.0),
                color.withOpacity(0.6),
                color,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: const SizedBox(
            height: 180,
            width: double.infinity,
          ),
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
        color.withOpacity(0),
        color.withOpacity(1),
        color.withOpacity(1),
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

class _PreviewCarousel extends StatefulWidget {
  final List<String> items;
  final VoidCallback? onTap;
  const _PreviewCarousel({required this.items, this.onTap});

  @override
  State<_PreviewCarousel> createState() => _PreviewCarouselState();
}

class _PreviewCarouselState extends State<_PreviewCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.items.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double value = 0;
              if (_controller.position.haveDimensions) {
                value = _controller.page! - index;
              } else {
                value = (_controller.initialPage - index).toDouble();
              }
              value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
              return Center(
                child: Transform.scale(
                  scale: value,
                  child: _PreviewCard(src: widget.items[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 내부 이미지----------------------------
class _PreviewCard extends StatelessWidget {
  final String src; // url 또는 asset 경로
  const _PreviewCard({required this.src});

  @override
  Widget build(BuildContext context) {
    final isUrl = src.startsWith('http://') || src.startsWith('https://');
    final border = Border.all(color: Colors.white.withOpacity(0.8), width: 4);
    // final radius = BorderRadius.circular(8);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        // borderRadius: radius,
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: isUrl
            ? Image.network(src, fit: BoxFit.cover)
            : Image.asset(src, fit: BoxFit.cover),
      ),
    );
  }
}

// 내부 Description----------------------------
class _OverlayCarousel extends StatefulWidget {
  final List<String> items;
  const _OverlayCarousel({required this.items});
  @override
  State<_OverlayCarousel> createState() => _OverlayCarouselState();
}

class _OverlayCarouselState extends State<_OverlayCarousel> {
  late final PageController _controller;
  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double value = 0;
                  if (_controller.position.haveDimensions) {
                    value = _controller.page! - index;
                  } else {
                    value = (_controller.initialPage - index).toDouble();
                  }
                  final translate = (value * -24);
                  final scale = (1 - value.abs() * 0.12).clamp(0.88, 1.0);
                  return Transform(
                    transform: Matrix4.identity()
                      ..translate(translate)
                      ..scale(scale),
                    child: _PreviewCard(src: widget.items[index]),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        // Main title
        Text(
          'Title',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        // 아이디 && 작가 이름
        Text(
          '@yoonmin_film',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 7),
        // 설명란(Desc)
        Text(
          '사진을 좌우로 넘기며 미리보세요. 아래 버튼으로 바로 시작할 수 있어요.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        // 날짜
        Text(
          'Date',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        Text(
          'Time',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        // 지역
        Text(
          'Location',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
      ],
    );
  }
}
