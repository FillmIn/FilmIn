import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:filmin/services/filters/lut/lut_filter_service.dart';

import 'crop/crop_tool.dart';
import 'brightness/brightness_tool.dart';

class ImagePreviewWidget extends StatelessWidget {
  final String? imagePath;
  final int rotation;
  final bool flipH;
  final double brightness;
  final BrightnessAdjustments brightnessAdjustments;
  final double blurSigma;
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
    required this.blurSigma,
    required this.filter,
    this.filterIntensity = 1.0,
    required this.crop,
    required this.showOriginal,
    required this.isFiltersInitialized,
    required this.lutService,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath;
    if (path == null || path.isEmpty) {
      return const Text(
        'No image provided',
        textAlign: TextAlign.center,
      );
    }
    final isHttp = path.startsWith('http://') || path.startsWith('https://');

    // 미리보기는 위젯 트랜스폼/필터로 빠르게 처리
    final radians = rotation * math.pi / 180.0;
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
    if (!showOriginal) {
      // 밝기 미리보기용 컬러 필터 매트릭스 구성
      final b = (brightness * 255).clamp(-255.0, 255.0).toDouble();
      final brightnessFilter = ColorFilter.matrix(<double>[
        1, 0, 0, 0, b,
        0, 1, 0, 0, b,
        0, 0, 1, 0, b,
        0, 0, 0, 1, 0,
      ]);

      // LUT 필터 시스템 (강도 적용)
      ColorFilter? presetFilter;
      if (filter != null && isFiltersInitialized && lutService != null) {
        debugPrint('ImagePreview: Applying LUT filter: $filter (intensity: $filterIntensity)');
        presetFilter = lutService!.createLutColorFilter(filter!, intensity: filterIntensity);
        if (presetFilter != null) {
          debugPrint('ImagePreview: 3D LUT filter applied: $filter');
        } else {
          debugPrint('ImagePreview: No matching LUT filter found for: $filter');
        }
      }

      // BrightnessAdjustments 적용
      content = _applyBrightnessAdjustments(content, brightnessAdjustments);

      content = ColorFiltered(colorFilter: brightnessFilter, child: content);
      if (presetFilter != null) {
        content = ColorFiltered(colorFilter: presetFilter, child: content);
      }
      if (flipH) {
        content = Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..setEntry(0, 0, -1.0),
          child: content,
        );
      }
      content = Transform.rotate(angle: radians, child: content);

      // 효과(블러) 적용 미리보기
      if (blurSigma > 0) {
        content = ImageFiltered(
          imageFilter: ui.ImageFilter.blur(
            sigmaX: blurSigma,
            sigmaY: blurSigma,
          ),
          child: content,
        );
      }
    }

    // 자르기 비율 미리보기 (중앙 크롭 형태)
    final aspect = switch (crop) {
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

  Widget _applyBrightnessAdjustments(Widget content, BrightnessAdjustments adj) {
    Widget result = content;

    // 1. Exposure (노출) - 전체 밝기 조정
    if (adj.exposure != 0.0) {
      final exposureValue = (adj.exposure * 255).clamp(-255.0, 255.0);
      final exposureFilter = ColorFilter.matrix(<double>[
        1, 0, 0, 0, exposureValue,
        0, 1, 0, 0, exposureValue,
        0, 0, 1, 0, exposureValue,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: exposureFilter, child: result);
    }

    // 2. Contrast (대비) - 명암 차이 조정
    if (adj.contrast != 0.0) {
      final contrastValue = 1.0 + adj.contrast;
      final intercept = 128 * (1 - contrastValue);
      final contrastFilter = ColorFilter.matrix(<double>[
        contrastValue, 0, 0, 0, intercept,
        0, contrastValue, 0, 0, intercept,
        0, 0, contrastValue, 0, intercept,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: contrastFilter, child: result);
    }

    // 3. Saturation (채도) - 색 선명도 조정
    if (adj.saturation != 0.0) {
      final satValue = 1.0 + adj.saturation;
      final lumR = 0.3086;
      final lumG = 0.6094;
      final lumB = 0.0820;
      final sr = (1 - satValue) * lumR;
      final sg = (1 - satValue) * lumG;
      final sb = (1 - satValue) * lumB;
      final saturationFilter = ColorFilter.matrix(<double>[
        sr + satValue, sg, sb, 0, 0,
        sr, sg + satValue, sb, 0, 0,
        sr, sg, sb + satValue, 0, 0,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: saturationFilter, child: result);
    }

    // 4. Warmth (따듯함) - 색온도 조정 (빨강↑ 파랑↓)
    if (adj.warmth != 0.0) {
      final warmthR = (adj.warmth * 30).clamp(-50.0, 50.0);
      final warmthB = (-adj.warmth * 30).clamp(-50.0, 50.0);
      final warmthFilter = ColorFilter.matrix(<double>[
        1, 0, 0, 0, warmthR,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, warmthB,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: warmthFilter, child: result);
    }

    // 5. Highlights (밝은영역) - 밝은 부분 조정 (근사치)
    if (adj.highlights != 0.0) {
      final highlightAdjust = adj.highlights * 100;
      final highlightsFilter = ColorFilter.matrix(<double>[
        1, 0, 0, 0, highlightAdjust * 0.5,
        0, 1, 0, 0, highlightAdjust * 0.5,
        0, 0, 1, 0, highlightAdjust * 0.5,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: highlightsFilter, child: result);
    }

    // 6. Shadows (어두운영역) - 어두운 부분 조정 (근사치)
    if (adj.shadows != 0.0) {
      final shadowAdjust = adj.shadows * 100;
      final shadowsFilter = ColorFilter.matrix(<double>[
        1, 0, 0, 0, shadowAdjust * 0.3,
        0, 1, 0, 0, shadowAdjust * 0.3,
        0, 0, 1, 0, shadowAdjust * 0.3,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: shadowsFilter, child: result);
    }

    // 7. Whites (흰색계열) - 매우 밝은 영역 조정 (근사치)
    if (adj.whites != 0.0) {
      final whitesAdjust = adj.whites * 80;
      final whitesFilter = ColorFilter.matrix(<double>[
        1, 0, 0, 0, whitesAdjust * 0.6,
        0, 1, 0, 0, whitesAdjust * 0.6,
        0, 0, 1, 0, whitesAdjust * 0.6,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: whitesFilter, child: result);
    }

    // 8. Blacks (검정계열) - 매우 어두운 영역 조정 (근사치)
    if (adj.blacks != 0.0) {
      final blacksAdjust = adj.blacks * 80;
      final blacksFilter = ColorFilter.matrix(<double>[
        1, 0, 0, 0, blacksAdjust * 0.2,
        0, 1, 0, 0, blacksAdjust * 0.2,
        0, 0, 1, 0, blacksAdjust * 0.2,
        0, 0, 0, 1, 0,
      ]);
      result = ColorFiltered(colorFilter: blacksFilter, child: result);
    }

    // 참고: sharpness와 noiseReduction은 ColorFilter로 구현하기 어려워서
    // 미리보기에서는 적용하지 않고, 저장 시에만 적용됩니다.

    return result;
  }
}
