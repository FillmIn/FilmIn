import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:filmin/services/filters/lut/lut_filter_service.dart';
import 'package:filmin/services/filters/xmp/shader_xmp_filter_service.dart';

import 'crop/crop_tool.dart';

class ImagePreviewWidget extends StatelessWidget {
  final String? imagePath;
  final int rotation;
  final bool flipH;
  final double brightness;
  final double blurSigma;
  final String? filter;
  final CropPreset crop;
  final bool showOriginal;
  final bool isFiltersInitialized;
  final ShaderXmpFilterService? shaderService;
  final LutFilterService? lutService;

  const ImagePreviewWidget({
    super.key,
    required this.imagePath,
    required this.rotation,
    required this.flipH,
    required this.brightness,
    required this.blurSigma,
    required this.filter,
    required this.crop,
    required this.showOriginal,
    required this.isFiltersInitialized,
    required this.shaderService,
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

      // 통합 필터 시스템 (XMP + LUT)
      ColorFilter? presetFilter;
      if (filter != null && isFiltersInitialized) {
        debugPrint('ImagePreview: Applying combined filter: $filter');

        // XMP 필터 시도
        if (shaderService != null) {
          presetFilter = shaderService!.createEnhancedColorFilter(filter!);
          if (presetFilter != null) {
            debugPrint('ImagePreview: XMP shader filter applied: $filter');
          }
        }

        // XMP 필터가 없으면 LUT 필터 시도
        if (presetFilter == null && lutService != null) {
          presetFilter = lutService!.createLutColorFilter(filter!);
          if (presetFilter != null) {
            debugPrint('ImagePreview: 3D LUT filter applied: $filter');
          }
        }

        if (presetFilter == null) {
          debugPrint('ImagePreview: No matching filter found for: $filter');
        }
      }

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
}
