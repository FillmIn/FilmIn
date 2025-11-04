import 'package:flutter/material.dart';

/// Onboarding 페이지의 소개 텍스트 섹션
///
/// 필터 이름, 키워드, 설명이 페이드 효과와 함께 표시됩니다.
class FadedIntroText extends StatelessWidget {
  const FadedIntroText({
    super.key,
    required this.theme,
    required this.color,
  });

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
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#키워드 #키워드 #키워드',
            style: theme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '필터의 설명이 표시될 영역입니다. '
            '필터 제목 아래에 추가 정보나 설명 문구가 들어갈 수 있습니다.',
            style: theme.bodyMedium?.copyWith(color: color, height: 1.4),
          ),
        ],
      ),
    );
  }
}
