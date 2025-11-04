import 'package:flutter/material.dart';

class OnboardingPreviewCarousel extends StatefulWidget {
  const OnboardingPreviewCarousel({
    super.key,
    required this.items,
    this.onTapItem,
  });

  final List<String> items;
  final void Function(int index, String src)? onTapItem;

  @override
  State<OnboardingPreviewCarousel> createState() =>
      _OnboardingPreviewCarouselState();
}

class _OnboardingPreviewCarouselState extends State<OnboardingPreviewCarousel> {
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
    return PageView.builder(
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
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onTapItem?.call(index, widget.items[index]),
                child: Transform.scale(
                  scale: value,
                  child: OnboardingPreviewCard(src: widget.items[index]),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class OnboardingPreviewCard extends StatelessWidget {
  const OnboardingPreviewCard({
    super.key,
    required this.src,
    this.overlayColor,
    this.isOverlay = false,
  });

  final String src;
  final Color? overlayColor;
  final bool isOverlay;

  @override
  Widget build(BuildContext context) {
    final isUrl = src.startsWith('http://') || src.startsWith('https://');
    final border = Border.all(
      color: Colors.white.withValues(alpha: 0.8),
      width: 4,
    );

    return Container(
      margin: isOverlay
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          : const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
      decoration: BoxDecoration(
        border: border,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            isUrl
                ? Image.network(src, fit: BoxFit.cover)
                : Image.asset(src, fit: BoxFit.cover),
            if (overlayColor != null) ColoredBox(color: overlayColor!),
          ],
        ),
      ),
    );
  }
}

class OnboardingOverlayBackdrop extends StatelessWidget {
  const OnboardingOverlayBackdrop({
    super.key,
    required this.src,
    this.opacity = 0.5,
    this.backgroundColor = Colors.black,
  });

  final String src; // kept for API compatibility
  final double opacity;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: backgroundColor.withValues(alpha: opacity));
  }
}

class OnboardingOverlayCarousel extends StatefulWidget {
  const OnboardingOverlayCarousel({
    super.key,
    required this.items,
    required this.initialIndex,
    this.onPageChanged,
  });

  final List<String> items;
  final int initialIndex;
  final ValueChanged<int>? onPageChanged;

  @override
  State<OnboardingOverlayCarousel> createState() =>
      _OnboardingOverlayCarouselState();
}

class _OnboardingOverlayCarouselState extends State<OnboardingOverlayCarousel> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 1.0,
      initialPage: widget.initialIndex,
    );
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
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              return OnboardingPreviewCard(
                src: widget.items[index],
                isOverlay: true,
              );
            },
          ),
        ),
        const SizedBox(height: 9),
        // 메인 제목 ------------
        Text(
          'Title',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 6),
        // 작가명 ------------
        Text(
          '@yoonmin_film',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 7),
        // 설명 ------------
        Text(
          '사진을 좌우로 넘기며 미리보세요. 아래 버튼으로 바로 시작할 수 있어요.',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 10),
        // 일자 ------------
        Text(
          'Date',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        // 시간 ------------
        Text(
          'Time',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 6),
        // 장소 ------------
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
