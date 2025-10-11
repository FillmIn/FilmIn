import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CropPreset { original, freeform, square, r4x5, r3x4, r9x16, r16x9 }

class CropToolPanel extends StatelessWidget {
  final CropPreset selectedCrop;
  final ValueChanged<CropPreset> onCropChanged;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const CropToolPanel({
    super.key,
    required this.selectedCrop,
    required this.onCropChanged,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
                  _RatioButton(
                    preset: CropPreset.freeform,
                    label: '자유 형식',
                    selected: selectedCrop == CropPreset.freeform,
                    onTap: () => onCropChanged(CropPreset.freeform),
                  ),
                  const SizedBox(width: 10),
                  _RatioButton(
                    preset: CropPreset.square,
                    label: '1 : 1',
                    selected: selectedCrop == CropPreset.square,
                    onTap: () => onCropChanged(CropPreset.square),
                  ),
                  const SizedBox(width: 10),
                  _RatioButton(
                    preset: CropPreset.r4x5,
                    label: '4 : 5',
                    selected: selectedCrop == CropPreset.r4x5,
                    onTap: () => onCropChanged(CropPreset.r4x5),
                  ),
                  const SizedBox(width: 10),
                  _RatioButton(
                    preset: CropPreset.r3x4,
                    label: '3 : 4',
                    selected: selectedCrop == CropPreset.r3x4,
                    onTap: () => onCropChanged(CropPreset.r3x4),
                  ),
                  const SizedBox(width: 10),
                  _RatioButton(
                    preset: CropPreset.r9x16,
                    label: '9 : 16',
                    selected: selectedCrop == CropPreset.r9x16,
                    onTap: () => onCropChanged(CropPreset.r9x16),
                  ),
                  const SizedBox(width: 10),
                  _RatioButton(
                    preset: CropPreset.r16x9,
                    label: '16 : 9',
                    selected: selectedCrop == CropPreset.r16x9,
                    onTap: () => onCropChanged(CropPreset.r16x9),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // 취소 버튼 (왼쪽)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: iconColor,
                      size: 22,
                      weight: 300,
                    ),
                    onPressed: onCancel,
                  ),
                  const Spacer(),
                  // 편집 텍스트 (중앙)
                  Text(
                    '편집',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Spacer(),
                  // 완료 버튼 (오른쪽)
                  IconButton(
                    icon: Icon(
                      Icons.check,
                      color: iconColor,
                      size: 22,
                      weight: 300,
                    ),
                    onPressed: onApply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioButton extends StatelessWidget {
  final CropPreset preset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RatioButton({
    required this.preset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final selectedColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);

    double iconWidth = 40;
    double iconHeight = 40;

    switch (preset) {
      case CropPreset.original:
      case CropPreset.freeform:
        iconWidth = 40;
        iconHeight = 40;
        break;
      case CropPreset.square:
        iconWidth = 40;
        iconHeight = 40;
        break;
      case CropPreset.r4x5:
        iconWidth = 32;
        iconHeight = 40;
        break;
      case CropPreset.r3x4:
        iconWidth = 30;
        iconHeight = 40;
        break;
      case CropPreset.r9x16:
        iconWidth = 22;
        iconHeight = 40;
        break;
      case CropPreset.r16x9:
        iconWidth = 40;
        iconHeight = 22;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: switch (preset) {
                CropPreset.original => Icon(
                  Icons.crop_original,
                  color: iconColor,
                  size: 32,
                ),
                CropPreset.freeform => Icon(
                  Icons.crop_free,
                  color: iconColor,
                  size: 32,
                ),
                _ => Container(
                  width: iconWidth,
                  height: iconHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: iconColor, width: 2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class CropOverlay extends StatefulWidget {
  final CropPreset preset;
  final Function(Offset offset, double scale)? onCropChanged;
  final Function(Rect rect)? onFreeformCropChanged;
  final Offset initialOffset;
  final double initialScale;
  final Rect? initialFreeformRect;
  final String? imagePath;
  final double? imageAspectRatio; // 이미지 비율 추가

  const CropOverlay({
    super.key,
    required this.preset,
    this.onCropChanged,
    this.onFreeformCropChanged,
    this.initialOffset = Offset.zero,
    this.initialScale = 1.0,
    this.initialFreeformRect,
    this.imagePath,
    this.imageAspectRatio,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  late Offset _cropOffset;
  late double _scale;
  Offset? _lastFocalPoint;
  double? _lastScale;

  late Rect _freeformRect;
  String? _resizeHandle;
  Offset? _lastDragPoint;

  @override
  void initState() {
    super.initState();
    _cropOffset = widget.initialOffset;
    _scale = widget.initialScale;
    _freeformRect = widget.initialFreeformRect ?? Rect.zero;
  }

  @override
  void didUpdateWidget(CropOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset) {
      _lastFocalPoint = null;
      _lastScale = null;
      if (widget.preset == CropPreset.freeform) {
        _freeformRect = widget.initialFreeformRect ?? Rect.zero;
      }
    }

    if (widget.preset != CropPreset.freeform &&
        (oldWidget.initialOffset != widget.initialOffset ||
            oldWidget.initialScale != widget.initialScale)) {
      _cropOffset = widget.initialOffset;
      _scale = widget.initialScale;
    }

    if (widget.preset == CropPreset.freeform &&
        widget.initialFreeformRect != null &&
        widget.initialFreeformRect != oldWidget.initialFreeformRect) {
      _freeformRect = widget.initialFreeformRect!;
    }

    // 이미지 비율이 로드되었을 때 기존 rect를 이미지 영역 내로 제한
    if (widget.preset == CropPreset.freeform &&
        widget.imageAspectRatio != null &&
        oldWidget.imageAspectRatio == null &&
        _freeformRect != Rect.zero) {
      // 비율이 처음 로드되었을 때만 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            // LayoutBuilder의 크기를 알 수 없으므로, 다음 빌드에서 처리하도록 함
            // _buildFreeformCropOverlay에서 자동으로 클램프됨
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.preset == CropPreset.original) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;

        if (widget.preset == CropPreset.freeform) {
          return _buildFreeformCropOverlay(size);
        }

        // 이미지 영역 계산
        final imageArea = _calculateImageArea(size);

        return GestureDetector(
          onScaleStart: (details) {
            _lastFocalPoint = details.focalPoint;
            _lastScale = _scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              if (details.scale != 1.0) {
                // 최소 크기를 이미지 영역의 20%로, 최대 크기를 이미지 영역 전체까지 허용
                final aspect = _aspectForPreset(widget.preset);
                if (aspect != null) {
                  double baseWidth = imageArea.width * 0.9;
                  double baseHeight = baseWidth / aspect;
                  if (baseHeight > imageArea.height * 0.9) {
                    baseHeight = imageArea.height * 0.9;
                    baseWidth = baseHeight * aspect;
                  }
                  // 최소: baseSize의 0.3배, 최대: 이미지 영역에 맞게 자동 조정
                  final minScale = 0.3;
                  final maxScale = math.min(
                    imageArea.width / baseWidth,
                    imageArea.height / baseHeight,
                  );
                  _scale = (_lastScale! * details.scale).clamp(minScale, maxScale);
                }
              }
              if (_lastFocalPoint != null) {
                final delta = details.focalPoint - _lastFocalPoint!;
                _cropOffset = _clampOffset(_cropOffset + delta, size, _scale, imageArea);
                _lastFocalPoint = details.focalPoint;
              }
              widget.onCropChanged?.call(_cropOffset, _scale);
            });
          },
          onScaleEnd: (_) => _lastFocalPoint = null,
          child: CustomPaint(
            size: size,
            painter: CropGridPainter(
              preset: widget.preset,
              offset: _cropOffset,
              scale: _scale,
              imageArea: imageArea,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFreeformCropOverlay(Size size) {
    // 이미지 영역 계산
    final imageArea = _calculateImageArea(size);

    // freeformRect가 초기화되지 않았거나 이미지 영역 밖에 있으면 초기화
    if (_freeformRect == Rect.zero ||
        _freeformRect.left < imageArea.left - 10 ||
        _freeformRect.right > imageArea.right + 10) {
      // 이미지 영역 내에서 초기 크롭 박스 생성
      final width = imageArea.width * 0.8;
      final height = imageArea.height * 0.6;
      _freeformRect = Rect.fromCenter(
        center: imageArea.center,
        width: width,
        height: height,
      );
      // 이미지 영역 내로 제한
      _freeformRect = _clampRectToImage(_freeformRect, imageArea);
    }

    return GestureDetector(
      onPanStart: (details) {
        _lastDragPoint = details.localPosition;
        _resizeHandle = _getResizeHandle(details.localPosition);
      },
      onPanUpdate: (details) {
        setState(() {
          final delta = details.localPosition - _lastDragPoint!;
          _lastDragPoint = details.localPosition;

          if (_resizeHandle == 'move') {
            _freeformRect = _freeformRect.shift(delta);
          } else if (_resizeHandle != null) {
            _freeformRect = _resizeFreeformRect(
              _freeformRect,
              _resizeHandle!,
              delta,
            );
          }

          // 이미지 영역으로 제한
          _freeformRect = _clampRectToImage(_freeformRect, imageArea);
          widget.onFreeformCropChanged?.call(_freeformRect);
        });
      },
      onPanEnd: (_) {
        _resizeHandle = null;
        _lastDragPoint = null;
      },
      child: CustomPaint(
        size: size,
        painter: FreeformCropPainter(
          rect: _freeformRect,
          imageArea: imageArea, // 이미지 영역 전달
        ),
      ),
    );
  }

  // 이미지가 실제로 표시되는 영역 계산 (BoxFit.contain 로직)
  Rect _calculateImageArea(Size screenSize) {
    // 전달받은 이미지 비율 사용, 없으면 화면 전체 사용
    final imageAspect = widget.imageAspectRatio;

    if (imageAspect == null) {
      // 비율을 모르면 화면 전체 사용
      return Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    }

    final screenAspect = screenSize.width / screenSize.height;

    if (imageAspect > screenAspect) {
      // 이미지가 화면보다 가로로 더 넓음 - 화면 너비에 맞춤
      final imageWidth = screenSize.width;
      final imageHeight = screenSize.width / imageAspect;
      final top = (screenSize.height - imageHeight) / 2;
      return Rect.fromLTWH(0, top, imageWidth, imageHeight);
    } else {
      // 이미지가 화면보다 세로로 더 김 - 화면 높이에 맞춰짐
      final imageHeight = screenSize.height;
      final imageWidth = screenSize.height * imageAspect;
      final left = (screenSize.width - imageWidth) / 2;
      return Rect.fromLTWH(left, 0, imageWidth, imageHeight);
    }
  }

  // 이미지 영역 내로 크롭 박스를 제한
  Rect _clampRectToImage(Rect rect, Rect imageArea) {
    // 최소 크기를 이미지 크기의 10%로 설정 (더 유연하게)
    final minSize = math.min(imageArea.width, imageArea.height) * 0.1;

    // 크롭 박스가 이미지 영역을 벗어나지 않도록 제한
    double left = rect.left.clamp(imageArea.left, imageArea.right - minSize);
    double top = rect.top.clamp(imageArea.top, imageArea.bottom - minSize);
    double right = rect.right.clamp(imageArea.left + minSize, imageArea.right);
    double bottom = rect.bottom.clamp(
      imageArea.top + minSize,
      imageArea.bottom,
    );

    // 최소 크기 보장
    if (right - left < minSize) {
      final centerX = (left + right) / 2;
      left = (centerX - minSize / 2).clamp(
        imageArea.left,
        imageArea.right - minSize,
      );
      right = left + minSize;
    }
    if (bottom - top < minSize) {
      final centerY = (top + bottom) / 2;
      top = (centerY - minSize / 2).clamp(
        imageArea.top,
        imageArea.bottom - minSize,
      );
      bottom = top + minSize;
    }

    return Rect.fromLTRB(left, top, right, bottom);
  }

  Offset _clampOffset(Offset offset, Size size, double scale, Rect imageArea) {
    final aspect = _aspectForPreset(widget.preset);
    if (aspect == null) return Offset.zero;

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

    // 크롭 박스가 이미지 영역보다 크면 크기 조정
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

    // 크롭 박스가 이미지 영역을 벗어나지 않도록 offset 제한
    final maxDx = math.max(0.0, imageArea.width / 2 - halfWidth);
    final maxDy = math.max(0.0, imageArea.height / 2 - halfHeight);

    final dx = offset.dx.clamp(-maxDx, maxDx);
    final dy = offset.dy.clamp(-maxDy, maxDy);
    return Offset(dx, dy);
  }

  String? _getResizeHandle(Offset point) {
    const handleSize = 24.0;

    if ((point - _freeformRect.topLeft).distance < handleSize) return 'tl';
    if ((point - _freeformRect.topRight).distance < handleSize) return 'tr';
    if ((point - _freeformRect.bottomLeft).distance < handleSize) return 'bl';
    if ((point - _freeformRect.bottomRight).distance < handleSize) return 'br';
    if (_freeformRect.contains(point)) return 'move';
    return null;
  }

  Rect _resizeFreeformRect(Rect rect, String handle, Offset delta) {
    const minSize = 80.0;

    switch (handle) {
      case 'tl':
        final newLeft = math.min(rect.left + delta.dx, rect.right - minSize);
        final newTop = math.min(rect.top + delta.dy, rect.bottom - minSize);
        return Rect.fromLTRB(newLeft, newTop, rect.right, rect.bottom);
      case 'tr':
        final newRight = math.max(rect.right + delta.dx, rect.left + minSize);
        final newTop = math.min(rect.top + delta.dy, rect.bottom - minSize);
        return Rect.fromLTRB(rect.left, newTop, newRight, rect.bottom);
      case 'bl':
        final newLeft = math.min(rect.left + delta.dx, rect.right - minSize);
        final newBottom = math.max(rect.bottom + delta.dy, rect.top + minSize);
        return Rect.fromLTRB(newLeft, rect.top, rect.right, newBottom);
      case 'br':
        final newRight = math.max(rect.right + delta.dx, rect.left + minSize);
        final newBottom = math.max(rect.bottom + delta.dy, rect.top + minSize);
        return Rect.fromLTRB(rect.left, rect.top, newRight, newBottom);
      default:
        return rect;
    }
  }
}

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
    final aspect = _aspectForPreset(preset);
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

double? _aspectForPreset(CropPreset preset) {
  return switch (preset) {
    CropPreset.original => null,
    CropPreset.freeform => null,
    CropPreset.square => 1 / 1,
    CropPreset.r4x5 => 4 / 5,
    CropPreset.r3x4 => 3 / 4,
    CropPreset.r9x16 => 9 / 16,
    CropPreset.r16x9 => 16 / 9,
  };
}
