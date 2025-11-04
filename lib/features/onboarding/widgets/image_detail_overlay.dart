import 'package:flutter/material.dart';
import '../models/firebase_image.dart';

/// Firebase 이미지를 상세히 보여주는 오버레이 다이얼로그
///
/// PageView를 사용하여 이미지를 좌우로 스와이프하며 볼 수 있고,
/// 이미지의 메타데이터(제목, 작성자, 설명, 날짜 등)를 표시합니다.
class ImageDetailOverlay extends StatefulWidget {
  final List<FirebaseImage> images;
  final int initialIndex;

  const ImageDetailOverlay({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<ImageDetailOverlay> createState() => _ImageDetailOverlayState();

  /// 이미지 상세 오버레이를 표시하는 헬퍼 메서드
  static void show(
    BuildContext context,
    List<FirebaseImage> images,
    int initialIndex,
  ) {
    if (images.isEmpty) return;
    final safeIndex = initialIndex.clamp(0, images.length - 1);

    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => ImageDetailOverlay(
        images: images,
        initialIndex: safeIndex,
      ),
    );
  }
}

class _ImageDetailOverlayState extends State<ImageDetailOverlay> {
  late int _activeIndex;

  @override
  void initState() {
    super.initState();
    _activeIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.images[_activeIndex];

    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.black.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 메인 이미지 PageView
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              height: 400,
              child: PageView.builder(
                itemCount: widget.images.length,
                controller: PageController(
                  initialPage: widget.initialIndex,
                  viewportFraction: 0.85,
                ),
                onPageChanged: (index) {
                  setState(() => _activeIndex = index);
                },
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: Image.network(
                        widget.images[index].downloadUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),

            // 하단 정보 영역
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // 제목
                    Text(
                      currentImage.metadata?['title'] ?? 'Title',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 작성자
                    Text(
                      '@${currentImage.metadata?['author'] ?? 'yoonmin'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 설명
                    Text(
                      currentImage.metadata?['description'] ??
                          '사진에 대한 설명이 여기에 표시됩니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 메타데이터 정보
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _MetadataItem(
                          label: 'Date',
                          value:
                              currentImage.metadata?['date'] ?? '2024. 06. 07',
                        ),
                        _MetadataItem(
                          label: 'Time',
                          value: currentImage.metadata?['time'] ?? '19:30',
                        ),
                        _MetadataItem(
                          label: 'Location',
                          value: currentImage.metadata?['location'] ?? 'Seoul',
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 닫기 버튼
            Positioned(
              top: 60,
              right: 20,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 메타데이터 항목 (라벨 + 값)
class _MetadataItem extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
