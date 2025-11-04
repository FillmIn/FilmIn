import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../widgets/brightness/brightness_tool.dart';
import '../widgets/effect/effect_tool.dart';
import '../widgets/crop/crop_tool.dart';
import '../debug/editview_logger.dart';
import 'lut_filter_service.dart';
import 'image_crop_service.dart';
import 'brightness_service.dart';
import 'film_effects_service.dart';

/// 이미지 인코딩 파라미터
class EncodeParams {
  final img.Image image;
  final bool isPng;
  final int quality;

  EncodeParams(this.image, this.isPng, this.quality);
}

/// 이미지 처리 오케스트레이터 서비스
///
/// 역할: 모든 이미지 처리 단계를 조율하는 중앙 서비스
/// - 자동 밝기 조정 계산
/// - 크롭만 적용한 임시 저장
/// - 전체 편집 파이프라인 실행
class ImageProcessingService {
  // 의존성 서비스들
  final ImageCropService _cropService = ImageCropService();
  final BrightnessService _brightnessService = BrightnessService();
  final FilmEffectsService _filmEffectsService = FilmEffectsService();

  // 로깅
  void _log(String message) => EditViewLogger.log(message);

  /// Isolate에서 이미지 인코딩 (백그라운드 처리)
  static List<int> encodeImageInIsolate(EncodeParams params) {
    if (params.isPng) {
      return img.encodePng(params.image, level: params.quality);
    } else {
      return img.encodeJpg(params.image, quality: params.quality);
    }
  }

  /// 이미지 디코딩 (포맷별 최적화)
  img.Image? _decodeImage(Uint8List bytes, String imagePath) {
    final ext = imagePath.toLowerCase().split('.').last;

    img.Image? image;
    if (ext == 'jpg' || ext == 'jpeg') {
      image = img.decodeJpg(bytes);
      _log('Decoded as JPEG');
    } else if (ext == 'png') {
      image = img.decodePng(bytes);
      _log('Decoded as PNG');
    } else {
      image = img.decodeImage(bytes);
      _log('Decoded with generic decoder');
    }

    return image;
  }

  /// 자동 밝기 조정 값 계산
  ///
  /// 이미지를 분석하여 최적의 밝기 조정 값을 자동으로 계산합니다.
  Future<BrightnessAdjustments> calculateAutoAdjustments(String imagePath) async {
    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Image file not found');
    }

    final bytes = await file.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // 이미지 분석 (샘플링으로 성능 최적화)
    int totalR = 0, totalG = 0, totalB = 0;
    int minLum = 255, maxLum = 0;
    int darkPixels = 0, brightPixels = 0;
    const sampleStep = 10;
    int sampledPixels = 0;

    for (var y = 0; y < image.height; y += sampleStep) {
      for (var x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();

        totalR += r;
        totalG += g;
        totalB += b;
        sampledPixels++;

        final lum = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
        if (lum < minLum) minLum = lum;
        if (lum > maxLum) maxLum = lum;
        if (lum < 85) darkPixels++;
        if (lum > 170) brightPixels++;
      }
    }

    final avgR = totalR / sampledPixels;
    final avgG = totalG / sampledPixels;
    final avgB = totalB / sampledPixels;
    final avgLum = (0.299 * avgR + 0.587 * avgG + 0.114 * avgB);
    final lumRange = maxLum - minLum;

    // 자동 조정 값 계산
    double exposure = -0.08;
    double contrast = 0.0;
    double highlights = 0.0;
    double shadows = 0.0;
    double saturation = 0.0;

    // 매우 어두운 이미지만 밝게 조정
    if (avgLum < 80) {
      exposure += ((80 - avgLum) / 255.0 * 0.5).clamp(0.0, 0.15);
    } else if (avgLum > 160) {
      exposure -= ((avgLum - 160) / 255.0 * 0.3).clamp(0.0, 0.2);
    }

    if (lumRange < 150) {
      contrast = ((150 - lumRange) / 300.0).clamp(0.0, 0.25);
    }

    if (brightPixels > sampledPixels * 0.15) {
      highlights = -((brightPixels / sampledPixels - 0.15) * 2).clamp(0.0, 0.2);
    }

    if (darkPixels > sampledPixels * 0.15) {
      shadows = ((darkPixels / sampledPixels - 0.15) * 1.5).clamp(0.0, 0.15);
    }

    final colorVariance = (avgR - avgG).abs() + (avgG - avgB).abs() + (avgR - avgB).abs();
    if (colorVariance < 30) {
      saturation = 0.15;
    }

    return BrightnessAdjustments(
      exposure: exposure,
      contrast: contrast,
      highlights: highlights,
      shadows: shadows,
      saturation: saturation,
      warmth: 0.08,
      sharpness: 0.1,
    );
  }

  /// 크롭만 적용하여 임시 파일로 저장
  ///
  /// 다른 편집은 적용하지 않고 크롭만 적용합니다.
  /// 빠른 미리보기 업데이트를 위해 사용됩니다.
  Future<String> saveCropOnly({
    required String imagePath,
    required CropPreset crop,
    required Offset cropOffset,
    required double cropScale,
    required Rect? freeformCropRect,
    required Size screenSize,
  }) async {
    _log('========== SAVE CROP ONLY ==========');

    final bytes = await File(imagePath).readAsBytes();
    var image = _decodeImage(bytes, imagePath);

    if (image == null) throw Exception('Unsupported image: $imagePath');

    _log('Image size: ${image.width}x${image.height}');

    // 크롭 적용
    image = _applyCrop(image, crop, cropOffset, cropScale, freeformCropRect, screenSize);

    // PNG로 임시 저장
    final encodeParams = EncodeParams(image, true, 6);
    final outBytes = await compute(encodeImageInIsolate, encodeParams);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${tempDir.path}/edited_$timestamp.png';

    await File(outPath).writeAsBytes(outBytes);
    _log('Temp file saved: $outPath (${outBytes.length} bytes)');

    return outPath;
  }

  /// 모든 편집을 적용하여 최종 이미지 생성
  ///
  /// 전체 편집 파이프라인:
  /// 1. 이미지 로드 및 디코딩
  /// 2. 회전/플립
  /// 3. 밝기 조정
  /// 4. LUT 필터
  /// 5. 필름 효과 (Grain, Dust, Halation)
  /// 6. 크롭
  /// 7. 인코딩 및 저장
  Future<List<int>> processFullEdit({
    required String imagePath,
    required int rotation,
    required bool flipH,
    required double brightness,
    required BrightnessAdjustments brightnessAdjustments,
    required String? filter,
    required double filterIntensity,
    required FilmEffects filmEffects,
    required CropPreset crop,
    required Offset cropOffset,
    required double cropScale,
    required Rect? freeformCropRect,
    required Size screenSize,
    required LutFilterService? lutService,
  }) async {
    _log('========== PROCESS FULL EDIT START ==========');

    // 1. 이미지 로드
    final bytes = await File(imagePath).readAsBytes();
    var image = _decodeImage(bytes, imagePath);

    if (image == null) throw Exception('Unsupported image: $imagePath');

    _log('Image size: ${image.width}x${image.height}');

    // 2. 회전 및 플립
    if (rotation % 360 != 0) {
      image = img.copyRotate(image, angle: rotation);
      _log('Applied rotation: $rotation°');
    }
    if (flipH) {
      image = img.flipHorizontal(image);
      _log('Applied horizontal flip');
    }

    // 3. 밝기 조정 (Isolate 사용)
    image = await _brightnessService.applyIsolate(
      image,
      brightness,
      brightnessAdjustments,
    );
    _log('Applied brightness adjustments');

    // 4. LUT 필터
    if (filter != null && lutService != null) {
      final lut = lutService.getLut(filter);
      if (lut != null) {
        image = await _brightnessService.applyLutIsolate(image, lut, filterIntensity);
        _log('Applied LUT filter: $filter (intensity: $filterIntensity)');
      }
    }

    // 5. 필름 효과
    if (filmEffects.grainTexture != null && filmEffects.grainIntensity > 0) {
      image = await _filmEffectsService.applyGrainEffect(
        image,
        filmEffects.grainTexture!,
        filmEffects.grainIntensity,
      );
      _log('Applied grain effect');
    }

    if (filmEffects.dustTexture != null && filmEffects.dustIntensity > 0) {
      image = await _filmEffectsService.applyDustEffect(
        image,
        filmEffects.dustTexture!,
        filmEffects.dustIntensity,
      );
      _log('Applied dust effect');
    }

    if (filmEffects.halationTexture != null && filmEffects.halationIntensity > 0) {
      image = _filmEffectsService.applyHalationEffect(image, filmEffects.halationIntensity);
      _log('Applied halation effect');
    }

    // 6. 크롭
    image = _applyCrop(image, crop, cropOffset, cropScale, freeformCropRect, screenSize);

    // 7. 인코딩
    final originalExt = imagePath.toLowerCase().split('.').last;
    final isPng = originalExt == 'png';
    final encodeParams = EncodeParams(image, isPng, isPng ? 6 : 95);
    final outBytes = await compute(encodeImageInIsolate, encodeParams);

    _log('Encoding completed: ${outBytes.length} bytes');
    _log('========== PROCESS FULL EDIT END ==========');

    return outBytes;
  }

  /// 크롭 적용 (내부 헬퍼 메서드)
  img.Image _applyCrop(
    img.Image image,
    CropPreset crop,
    Offset cropOffset,
    double cropScale,
    Rect? freeformCropRect,
    Size screenSize,
  ) {
    switch (crop) {
      case CropPreset.original:
        return image;

      case CropPreset.freeform:
        if (freeformCropRect != null && freeformCropRect != Rect.zero) {
          return _cropService.freeformCrop(image, freeformCropRect, screenSize);
        }
        return image;

      case CropPreset.square:
        return _cropService.cropToAspect(image, 1, 1, cropOffset, cropScale, screenSize);

      case CropPreset.r4x5:
        return _cropService.cropToAspect(image, 4, 5, cropOffset, cropScale, screenSize);

      case CropPreset.r3x4:
        return _cropService.cropToAspect(image, 3, 4, cropOffset, cropScale, screenSize);

      case CropPreset.r9x16:
        return _cropService.cropToAspect(image, 9, 16, cropOffset, cropScale, screenSize);

      case CropPreset.r16x9:
        return _cropService.cropToAspect(image, 16, 9, cropOffset, cropScale, screenSize);
    }
  }
}
