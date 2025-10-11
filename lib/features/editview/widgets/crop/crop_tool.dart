import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CropPreset {
  original,
  freeform,
  square,
  r4x5,
  r3x4,
  r9x16,
  r16x9,
}

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
                    preset: CropPreset.original,
                    label: '원본',
                    selected: selectedCrop == CropPreset.original,
                    onTap: () => onCropChanged(CropPreset.original),
                  ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.close, color: iconColor, size: 28),
                  onPressed: onCancel,
                ),
                Text(
                  '편집',
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check, color: iconColor, size: 28),
                  onPressed: onApply,
                ),
              ],
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
    final selectedColor =
        isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1);

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

  const CropOverlay({
    super.key,
    required this.preset,
    this.onCropChanged,
    this.onFreeformCropChanged,
    this.initialOffset = Offset.zero,
    this.initialScale = 1.0,
    this.initialFreeformRect,
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
          if (_freeformRect == Rect.zero) {
            final width = size.width * 0.8;
            final height = size.height * 0.6;
            _freeformRect = Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: width,
              height: height,
            );
          }
          return _buildFreeformCropOverlay(size);
        }

        return GestureDetector(
          onScaleStart: (details) {
            _lastFocalPoint = details.focalPoint;
            _lastScale = _scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              if (details.scale != 1.0) {
                _scale = (_lastScale! * details.scale).clamp(0.5, 2.0);
              }
              if (_lastFocalPoint != null) {
                final delta = details.focalPoint - _lastFocalPoint!;
                _cropOffset = _clampOffset(_cropOffset + delta, size, _scale);
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildFreeformCropOverlay(Size size) {
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
            _freeformRect =
                _resizeFreeformRect(_freeformRect, _resizeHandle!, delta);
          }

          _freeformRect = _clampRect(_freeformRect, size);
          widget.onFreeformCropChanged?.call(_freeformRect);
        });
      },
      onPanEnd: (_) {
        _resizeHandle = null;
        _lastDragPoint = null;
      },
      child: CustomPaint(
        size: size,
        painter: FreeformCropPainter(rect: _freeformRect),
      ),
    );
  }

  Offset _clampOffset(Offset offset, Size size, double scale) {
    final aspect = _aspectForPreset(widget.preset);
    if (aspect == null) return Offset.zero;

    double baseWidth = size.width * 0.9;
    double baseHeight = baseWidth / aspect;
    if (baseHeight > size.height * 0.9) {
      baseHeight = size.height * 0.9;
      baseWidth = baseHeight * aspect;
    }

    final cropWidth = baseWidth * scale;
    final cropHeight = baseHeight * scale;
    final halfWidth = cropWidth / 2;
    final halfHeight = cropHeight / 2;

    final maxDx = math.max(0.0, size.width / 2 - halfWidth);
    final maxDy = math.max(0.0, size.height / 2 - halfHeight);

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

  Rect _clampRect(Rect rect, Size bounds) {
    double left = rect.left.clamp(0.0, bounds.width);
    double top = rect.top.clamp(0.0, bounds.height);
    double right = rect.right.clamp(0.0, bounds.width);
    double bottom = rect.bottom.clamp(0.0, bounds.height);

    if (right - left < 80) {
      final centerX = (left + right) / 2;
      left = centerX - 40;
      right = centerX + 40;
    }
    if (bottom - top < 80) {
      final centerY = (top + bottom) / 2;
      top = centerY - 40;
      bottom = centerY + 40;
    }

    left = left.clamp(0.0, bounds.width);
    right = right.clamp(0.0, bounds.width);
    top = top.clamp(0.0, bounds.height);
    bottom = bottom.clamp(0.0, bounds.height);

    if (right <= left || bottom <= top) {
      return Rect.fromCenter(
        center: Offset(bounds.width / 2, bounds.height / 2),
        width: math.min(bounds.width, 120),
        height: math.min(bounds.height, 120),
      );
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }
}

class CropGridPainter extends CustomPainter {
  final CropPreset preset;
  final Offset offset;
  final double scale;

  CropGridPainter({
    required this.preset,
    required this.offset,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final aspect = _aspectForPreset(preset);
    if (aspect == null) return;

    double baseWidth = size.width * 0.9;
    double baseHeight = baseWidth / aspect;
    if (baseHeight > size.height * 0.9) {
      baseHeight = size.height * 0.9;
      baseWidth = baseHeight * aspect;
    }

    final cropWidth = baseWidth * scale;
    final cropHeight = baseHeight * scale;
    final halfWidth = cropWidth / 2;
    final halfHeight = cropHeight / 2;

    double centerX = size.width / 2 + offset.dx;
    double centerY = size.height / 2 + offset.dy;

    centerX = centerX.clamp(halfWidth, size.width - halfWidth);
    centerY = centerY.clamp(halfHeight, size.height - halfHeight);

    final rect = Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: cropWidth,
      height: cropHeight,
    );

    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
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
        oldDelegate.scale != scale;
  }
}

class FreeformCropPainter extends CustomPainter {
  final Rect rect;

  FreeformCropPainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);

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
    return oldDelegate.rect != rect;
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
