import 'package:flutter/material.dart';

/// Onboarding 페이지의 Hero 이미지 섹션
///
/// 상단 배너 이미지와 그라데이션 효과를 포함합니다.
class OnboardingHero extends StatelessWidget {
  final double height;
  final Color surfaceColor;

  const OnboardingHero({
    super.key,
    required this.height,
    required this.surfaceColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const EdgeFadeHeroImage(
            assetPath: 'assets/images/MainBanner.jpg',
          ),
          const TopBottomGradient(),
          BottomSurfaceScrim(color: surfaceColor),
        ],
      ),
    );
  }
}

/// 상단과 하단에 그라데이션 효과를 추가하는 위젯
class TopBottomGradient extends StatelessWidget {
  const TopBottomGradient({super.key});

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

/// 하단 Surface 색상으로 페이드하는 그라데이션
class BottomSurfaceScrim extends StatelessWidget {
  const BottomSurfaceScrim({super.key, required this.color});

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

/// 가장자리가 페이드되는 Hero 이미지
class EdgeFadeHeroImage extends StatelessWidget {
  const EdgeFadeHeroImage({super.key, required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.72, 1.0],
        ).createShader(rect);
      },
      blendMode: BlendMode.dstIn,
      child: Image.asset(assetPath, fit: BoxFit.cover),
    );
  }
}
