import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:filmin/services/filters/lut/lut_filter_service.dart';

import 'crop/crop_tool.dart';
import 'brightness/brightness_tool.dart';
import 'effect/effect_tool.dart';

class ImagePreviewWidget extends StatefulWidget {
  final String? imagePath;
  final int rotation;
  final bool flipH;
  final double brightness;
  final BrightnessAdjustments brightnessAdjustments;
  final FilmEffects filmEffects;
  final String? filter;
  final double filterIntensity;
  final CropPreset crop;
  final bool showOriginal;
  final bool isFiltersInitialized;
  final LutFilterService? lutService;

  const ImagePreviewWidget({
    super.key,
    required this.imagePath,
    required this.rotation,
    required this.flipH,
    required this.brightness,
    required this.brightnessAdjustments,
    required this.filmEffects,
    required this.filter,
    this.filterIntensity = 1.0,
    required this.crop,
    required this.showOriginal,
    required this.isFiltersInitialized,
    required this.lutService,
  });

  @override
  State<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends State<ImagePreviewWidget> {
  ColorFilter? _cachedCombinedFilter;
  ColorFilter? _cachedLutFilter;
  String? _lastFilterName;
  double _lastFilterIntensity = 1.0;
  BrightnessAdjustments _lastBrightnessAdjustments = const BrightnessAdjustments();
  double _lastBrightness = 0.0;

  @override
  Widget build(BuildContext context) {
    final path = widget.imagePath;
    if (path == null || path.isEmpty) {
      return const Text(
        'No image provided',
        textAlign: TextAlign.center,
      );
    }
    final isHttp = path.startsWith('http://') || path.startsWith('https://');

    // 미리보기는 위젯 트랜스폼/필터로 빠르게 처리
    final radians = widget.rotation * math.pi / 180.0;
    Widget preview;
    if (isHttp) {
      preview = CachedNetworkImage(imageUrl: path, fit: BoxFit.contain);
    } else {
      final file = File(path);
      if (!file.existsSync()) {
        return Text('File not found:\n$path', textAlign: TextAlign.center);
      }
      preview = Image.file(file, fit: BoxFit.contain);
    }

    Widget content = preview;

    // 원본과 비교 중이면 편집을 적용하지 않음
    if (!widget.showOriginal) {
      // ColorFilter 캐싱 로직 - 파라미터가 변경되었을 때만 재생성
      if (_cachedCombinedFilter == null ||
          _lastBrightness != widget.brightness ||
          _lastBrightnessAdjustments != widget.brightnessAdjustments) {
        _cachedCombinedFilter = _buildCombinedColorFilter(
          brightness: widget.brightness,
          brightnessAdjustments: widget.brightnessAdjustments,
          filter: widget.filter,
          filterIntensity: widget.filterIntensity,
          isFiltersInitialized: widget.isFiltersInitialized,
          lutService: widget.lutService,
        );
        _lastBrightness = widget.brightness;
        _lastBrightnessAdjustments = widget.brightnessAdjustments;
      }

      if (_cachedCombinedFilter != null) {
        content = ColorFiltered(colorFilter: _cachedCombinedFilter!, child: content);
      }

      // LUT 필터 캐싱 - 필터 이름이나 강도가 변경되었을 때만 재생성
      if (widget.filter != null && widget.isFiltersInitialized && widget.lutService != null) {
        if (_cachedLutFilter == null ||
            _lastFilterName != widget.filter ||
            _lastFilterIntensity != widget.filterIntensity) {
          _cachedLutFilter = widget.lutService!.createLutColorFilter(
            widget.filter!,
            intensity: widget.filterIntensity,
          );
          _lastFilterName = widget.filter;
          _lastFilterIntensity = widget.filterIntensity;
        }

        if (_cachedLutFilter != null) {
          content = ColorFiltered(colorFilter: _cachedLutFilter!, child: content);
        }
      }
      if (widget.flipH) {
        content = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..setEntry(0, 0, -1.0),
          child: content,
        );
      }
      content = Transform.rotate(angle: radians, child: content);

      // 그레인 효과 적용
      if (widget.filmEffects.grainTexture != null && widget.filmEffects.grainIntensity > 0) {
        content = Stack(
          fit: StackFit.expand,
          children: [
            content,
            Opacity(
              opacity: widget.filmEffects.grainIntensity,
              child: Image.asset(
                GrainTextures.getAssetPath(widget.filmEffects.grainTexture!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ],
        );
      }

      // 더스트 효과 적용
      if (widget.filmEffects.dustTexture != null && widget.filmEffects.dustIntensity > 0) {
        content = Stack(
          fit: StackFit.expand,
          children: [
            content,
            Opacity(
              opacity: widget.filmEffects.dustIntensity,
              child: Image.asset(
                DustTextures.getAssetPath(widget.filmEffects.dustTexture!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ],
        );
      }
    }

    // 자르기 비율 미리보기 (중앙 크롭 형태)
    final aspect = switch (widget.crop) {
      CropPreset.original => null,
      CropPreset.freeform => null, // 자유 형식은 비율 제한 없음
      CropPreset.square => 1.0,
      CropPreset.r4x5 => 4 / 5,
      CropPreset.r3x4 => 3 / 4,
      CropPreset.r9x16 => 9 / 16,
      CropPreset.r16x9 => 16 / 9,
    };

    if (aspect == null) return content;
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1000,
            height: 1000,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }

  ColorFilter? _buildCombinedColorFilter({
    required double brightness,
    required BrightnessAdjustments brightnessAdjustments,
    required String? filter,
    required double filterIntensity,
    required bool isFiltersInitialized,
    required LutFilterService? lutService,
  }) {
    // 기본 identity matrix로 시작
    List<double> matrix = [
      1, 0, 0, 0, 0,
      0, 1, 0, 0, 0,
      0, 0, 1, 0, 0,
      0, 0, 0, 1, 0,
    ];

    // 1. 기본 밝기 조정
    if (brightness != 0.0) {
      final b = (brightness * 255).clamp(-255.0, 255.0);
      matrix = _multiplyColorMatrices(matrix, [
        1, 0, 0, 0, b,
        0, 1, 0, 0, b,
        0, 0, 1, 0, b,
        0, 0, 0, 1, 0,
      ]);
    }

    // 2. BrightnessAdjustments의 각 항목 적용
    final adj = brightnessAdjustments;

    // Exposure
    if (adj.exposure != 0.0) {
      final exposureValue = (adj.exposure * 255).clamp(-255.0, 255.0);
      matrix = _multiplyColorMatrices(matrix, [
        1, 0, 0, 0, exposureValue,
        0, 1, 0, 0, exposureValue,
        0, 0, 1, 0, exposureValue,
        0, 0, 0, 1, 0,
      ]);
    }

    // Contrast
    if (adj.contrast != 0.0) {
      final contrastValue = 1.0 + adj.contrast;
      final intercept = 128 * (1 - contrastValue);
      matrix = _multiplyColorMatrices(matrix, [
        contrastValue, 0, 0, 0, intercept,
        0, contrastValue, 0, 0, intercept,
        0, 0, contrastValue, 0, intercept,
        0, 0, 0, 1, 0,
      ]);
    }

    // Saturation
    if (adj.saturation != 0.0) {
      final satValue = 1.0 + adj.saturation;
      final lumR = 0.3086;
      final lumG = 0.6094;
      final lumB = 0.0820;
      final sr = (1 - satValue) * lumR;
      final sg = (1 - satValue) * lumG;
      final sb = (1 - satValue) * lumB;
      matrix = _multiplyColorMatrices(matrix, [
        sr + satValue, sg, sb, 0, 0,
        sr, sg + satValue, sb, 0, 0,
        sr, sg, sb + satValue, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    }

    // Warmth
    if (adj.warmth != 0.0) {
      final warmthR = (adj.warmth * 30).clamp(-50.0, 50.0);
      final warmthB = (-adj.warmth * 30).clamp(-50.0, 50.0);
      matrix = _multiplyColorMatrices(matrix, [
        1, 0, 0, 0, warmthR,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, warmthB,
        0, 0, 0, 1, 0,
      ]);
    }

    // Highlights, Shadows, Whites, Blacks
    if (adj.highlights != 0.0) {
      final highlightAdjust = adj.highlights * 100;
      matrix = _multiplyColorMatrices(matrix, [
        1, 0, 0, 0, highlightAdjust * 0.5,
        0, 1, 0, 0, highlightAdjust * 0.5,
        0, 0, 1, 0, highlightAdjust * 0.5,
        0, 0, 0, 1, 0,
      ]);
    }

    if (adj.shadows != 0.0) {
      final shadowAdjust = adj.shadows * 100;
      matrix = _multiplyColorMatrices(matrix, [
        1, 0, 0, 0, shadowAdjust * 0.3,
        0, 1, 0, 0, shadowAdjust * 0.3,
        0, 0, 1, 0, shadowAdjust * 0.3,
        0, 0, 0, 1, 0,
      ]);
    }

    if (adj.whites != 0.0) {
      final whitesAdjust = adj.whites * 80;
      matrix = _multiplyColorMatrices(matrix, [
        1, 0, 0, 0, whitesAdjust * 0.6,
        0, 1, 0, 0, whitesAdjust * 0.6,
        0, 0, 1, 0, whitesAdjust * 0.6,
        0, 0, 0, 1, 0,
      ]);
    }

    if (adj.blacks != 0.0) {
      final blacksAdjust = adj.blacks * 80;
      matrix = _multiplyColorMatrices(matrix, [
        1, 0, 0, 0, blacksAdjust * 0.2,
        0, 1, 0, 0, blacksAdjust * 0.2,
        0, 0, 1, 0, blacksAdjust * 0.2,
        0, 0, 0, 1, 0,
      ]);
    }

    // 3. LUT 필터 적용 (별도로 처리 - 매트릭스 곱으로 통합 불가)
    // 일단 통합된 brightness adjustment matrix만 반환
    return ColorFilter.matrix(matrix);
  }

  // 두 개의 5x4 컬러 매트릭스를 곱하는 헬퍼 함수
  List<double> _multiplyColorMatrices(List<double> a, List<double> b) {
    List<double> result = List.filled(20, 0.0);

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        double sum = 0.0;
        if (col < 4) {
          // 매트릭스 곱셈
          for (int k = 0; k < 4; k++) {
            sum += a[row * 5 + k] * b[k * 5 + col];
          }
        } else {
          // offset 컬럼 (변환 벡터)
          for (int k = 0; k < 4; k++) {
            sum += a[row * 5 + k] * b[k * 5 + 4];
          }
          sum += a[row * 5 + 4];
        }
        result[row * 5 + col] = sum;
      }
    }

    return result;
  }

}
