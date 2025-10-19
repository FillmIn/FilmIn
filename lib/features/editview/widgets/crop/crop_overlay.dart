import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'crop_models.dart';
import 'crop_painters.dart';

/// 자르기 오버레이 위젯
class CropOverlay extends StatefulWidget {
  final CropPreset preset;
  final Function(Offset offset, double scale)? onCropChanged;
  final Function(Rect rect)? onFreeformCropChanged;
  final Offset initialOffset;
  final double initialScale;
  final Rect? initialFreeformRect;
  final String? imagePath;
  final double? imageAspectRatio;

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

    if (widget.preset == CropPreset.freeform &&
        widget.imageAspectRatio != null &&
        oldWidget.imageAspectRatio == null &&
        _freeformRect != Rect.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {});
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

        final imageArea = CropCalculator.calculateImageArea(size, widget.imageAspectRatio);

        return GestureDetector(
          onScaleStart: (details) {
            _lastFocalPoint = details.focalPoint;
            _lastScale = _scale;
          },
          onScaleUpdate: (details) {
            setState(() {
              if (details.scale != 1.0) {
                final aspect = CropPresetProvider.getAspectRatio(widget.preset);
                if (aspect != null) {
                  double baseWidth = imageArea.width * 0.9;
                  double baseHeight = baseWidth / aspect;
                  if (baseHeight > imageArea.height * 0.9) {
                    baseHeight = imageArea.height * 0.9;
                    baseWidth = baseHeight * aspect;
                  }
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
    final imageArea = CropCalculator.calculateImageArea(size, widget.imageAspectRatio);

    if (_freeformRect == Rect.zero ||
        _freeformRect.left < imageArea.left - 10 ||
        _freeformRect.right > imageArea.right + 10) {
      final width = imageArea.width * 0.8;
      final height = imageArea.height * 0.6;
      _freeformRect = Rect.fromCenter(
        center: imageArea.center,
        width: width,
        height: height,
      );
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
          imageArea: imageArea,
        ),
      ),
    );
  }

  Rect _clampRectToImage(Rect rect, Rect imageArea) {
    final minSize = math.min(imageArea.width, imageArea.height) * 0.1;

    double left = rect.left.clamp(imageArea.left, imageArea.right - minSize);
    double top = rect.top.clamp(imageArea.top, imageArea.bottom - minSize);
    double right = rect.right.clamp(imageArea.left + minSize, imageArea.right);
    double bottom = rect.bottom.clamp(
      imageArea.top + minSize,
      imageArea.bottom,
    );

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
    final aspect = CropPresetProvider.getAspectRatio(widget.preset);
    if (aspect == null) return Offset.zero;

    double baseWidth = imageArea.width * 0.9;
    double baseHeight = baseWidth / aspect;
    if (baseHeight > imageArea.height * 0.9) {
      baseHeight = imageArea.height * 0.9;
      baseWidth = baseHeight * aspect;
    }

    double cropWidth = baseWidth * scale;
    double cropHeight = baseHeight * scale;

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
