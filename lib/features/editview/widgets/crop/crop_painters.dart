import 'package:flutter/material.dart';
import 'crop_models.dart';

/// 자르기 그리드 페인터
class CropGridPainter extends CustomPainter {
  final CropPreset preset;
  final Offset offset;
  final double scale;
  final Rect imageArea;

  CropGridPainter({
    required this.preset,
    required this.offset,
    required this.scale,
    required this.imageArea,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final aspect = CropPresetProvider.getAspectRatio(preset);
    if (aspect == null) return;

    // 이미지 영역 내에서 크롭 박스 크기 계산
    double baseWidth = imageArea.width * 0.9;
    double baseHeight = baseWidth / aspect;
    if (baseHeight > imageArea.height * 0.9) {
      baseHeight = imageArea.height * 0.9;
      baseWidth = baseHeight * aspect;
    }

    // scale 적용 후 크롭 박스가 이미지 영역을 벗어나지 않도록 추가 검증
    double cropWidth = baseWidth * scale;
    double cropHeight = baseHeight * scale;

    // 크롭 박스가 이미지 영역보다 크면 scale을 조정
    if (cropWidth > imageArea.width) {
      cropWidth = imageArea.width;
      cropHeight = cropWidth / aspect;
    }
    if (cropHeight > imageArea.height) {
      cropHeight = imageArea.height;
      cropWidth = cropHeight * aspect;
    }

    final halfWidth = cropWidth / 2;
    final halfHeight = cropHeight / 2;

    // 이미지 중심을 기준으로 크롭 박스 위치 계산
    final imageCenterX = imageArea.left + imageArea.width / 2;
    final imageCenterY = imageArea.top + imageArea.height / 2;

    double centerX = imageCenterX + offset.dx;
    double centerY = imageCenterY + offset.dy;

    // 크롭 박스가 이미지 영역을 벗어나지 않도록 제한
    centerX = centerX.clamp(imageArea.left + halfWidth, imageArea.right - halfWidth);
    centerY = centerY.clamp(imageArea.top + halfHeight, imageArea.bottom - halfHeight);

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: cropWidth,
      height: cropHeight,
    );

    // 크롭 영역 외부를 어둡게
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 2; i++) {
      final dx = rect.left + rect.width * i / 3;
      canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), gridPaint);

      final dy = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CropGridPainter oldDelegate) {
    return oldDelegate.preset != preset ||
        oldDelegate.offset != offset ||
        oldDelegate.scale != scale ||
        oldDelegate.imageArea != imageArea;
  }
}

/// 자유형식 자르기 페인터
class FreeformCropPainter extends CustomPainter {
  final Rect rect;
  final Rect imageArea;

  FreeformCropPainter({required this.rect, required this.imageArea});

  @override
  void paint(Canvas canvas, Size size) {
    // 크롭 영역 외부를 어둡게 (0.6 alpha)
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    // 흰색 테두리
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

    // 3x3 격자선
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 2; i++) {
      final dx = rect.left + rect.width * i / 3;
      canvas.drawLine(Offset(dx, rect.top), Offset(dx, rect.bottom), gridPaint);

      final dy = rect.top + rect.height * i / 3;
      canvas.drawLine(Offset(rect.left, dy), Offset(rect.right, dy), gridPaint);
    }

    // 코너 핸들
    final handlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const handleRadius = 8.0;

    for (final handle in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      canvas.drawCircle(handle, handleRadius, handlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FreeformCropPainter oldDelegate) {
    return oldDelegate.rect != rect || oldDelegate.imageArea != imageArea;
  }
}
