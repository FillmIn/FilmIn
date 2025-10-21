import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../widgets/brightness/brightness_tool.dart';
import '../widgets/effect/effect_tool.dart';
import '../widgets/crop/crop_tool.dart';
import '../debug/editview_logger.dart';
import '../viewer_page_brightness_functions.dart' as brightness_funcs;
import 'package:filmin/services/filters/lut/lut_filter_service.dart';
import 'image_crop_service.dart';

/// 이미지 인코딩 파라미터
class EncodeParams {
  final img.Image image;
  final bool isPng;
  final int quality; // JPG quality or PNG compression level

  EncodeParams(this.image, this.isPng, this.quality);
}

/// 이미지 처리 서비스
class ImageProcessingService {
  final ImageCropService _cropService = ImageCropService();

  void _log(String message) => EditViewLogger.log(message);
  void _logError(String message, [Object? error, StackTrace? stackTrace]) =>
      EditViewLogger.error(message, error, stackTrace);

  /// Isolate에서 이미지 인코딩
  static List<int> encodeImageInIsolate(EncodeParams params) {
    if (params.isPng) {
      return img.encodePng(params.image, level: params.quality);
    } else {
      return img.encodeJpg(params.image, quality: params.quality);
    }
  }

  /// 두 이미지를 블렌드하여 합성 (opacity 기반)
  img.Image blendImages(img.Image base, img.Image overlay, double intensity) {
    final result = base.clone();

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final basePixel = result.getPixel(x, y);
        final overlayPixel = overlay.getPixel(x, y);

        // 오버레이 픽셀을 intensity에 따라 블렌드
        final blendedR = (basePixel.r + (overlayPixel.r - basePixel.r) * intensity)
            .clamp(0, 255)
            .toInt();
        final blendedG = (basePixel.g + (overlayPixel.g - basePixel.g) * intensity)
            .clamp(0, 255)
            .toInt();
        final blendedB = (basePixel.b + (overlayPixel.b - basePixel.b) * intensity)
            .clamp(0, 255)
            .toInt();

        result.setPixel(
          x,
          y,
          img.ColorRgba8(blendedR, blendedG, blendedB, basePixel.a.toInt()),
        );
      }
    }

    return result;
  }

  /// 자동 밝기 조정 계산
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

    // 이미지 분석 (샘플링)
    int totalR = 0, totalG = 0, totalB = 0;
    int minLum = 255, maxLum = 0;
    int darkPixels = 0, brightPixels = 0;
    final sampleStep = 10;
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
    double exposure = 0.0;
    double contrast = 0.0;
    double highlights = 0.0;
    double shadows = 0.0;
    double saturation = 0.0;

    if (avgLum < 100) {
      exposure = ((100 - avgLum) / 255.0).clamp(0.0, 0.3);
    } else if (avgLum > 155) {
      exposure = -((avgLum - 155) / 255.0).clamp(0.0, 0.3);
    }

    if (lumRange < 150) {
      contrast = ((150 - lumRange) / 300.0).clamp(0.0, 0.3);
    }

    if (brightPixels > sampledPixels * 0.15) {
      highlights = -((brightPixels / sampledPixels - 0.15) * 2).clamp(0.0, 0.2);
    }

    if (darkPixels > sampledPixels * 0.15) {
      shadows = ((darkPixels / sampledPixels - 0.15) * 2).clamp(0.0, 0.2);
    }

    final colorVariance =
        (avgR - avgG).abs() + (avgG - avgB).abs() + (avgR - avgB).abs();
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
  Future<String> saveCropOnly({
    required String imagePath,
    required CropPreset crop,
    required Offset cropOffset,
    required double cropScale,
    required Rect? freeformCropRect,
    required Size screenSize,
  }) async {
    _log('========== SAVE TEMP EDITS (CROP ONLY) START ==========');

    final bytes = await File(imagePath).readAsBytes();

    // 포맷별 디코더 사용
    img.Image? image;
    final ext = imagePath.toLowerCase().split('.').last;
    if (ext == 'jpg' || ext == 'jpeg') {
      image = img.decodeJpg(bytes);
      _log('Decoded as JPEG with format-specific decoder');
    } else if (ext == 'png') {
      image = img.decodePng(bytes);
      _log('Decoded as PNG with format-specific decoder');
    } else {
      image = img.decodeImage(bytes);
      _log('Decoded with generic decoder');
    }

    if (image == null) throw Exception('Unsupported image: $imagePath');

    _log('Original image format: ${image.numChannels} channels');
    _log('Image size: ${image.width}x${image.height}');
    _log('⚠️ CROP ONLY MODE - Skipping brightness/filter adjustments');
    _log('Current crop preset: $crop');
    _log('Crop offset: $cropOffset, scale: $cropScale');

    // 크롭만 적용
    switch (crop) {
      case CropPreset.original:
        _log('No crop applied (original preset)');
        break;
      case CropPreset.freeform:
        if (freeformCropRect != null && freeformCropRect != Rect.zero) {
          _log('Applying freeform crop...');
          _log('Freeform rect: $freeformCropRect');
          image = _cropService.freeformCrop(image, freeformCropRect, screenSize);
        } else {
          _log('⚠️ Freeform crop skipped: rect is null or zero');
        }
        break;
      case CropPreset.square:
        _log('Applying square crop...');
        image = _cropService.cropToAspect(
          image,
          1,
          1,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r4x5:
        _log('Applying 4:5 crop...');
        image = _cropService.cropToAspect(
          image,
          4,
          5,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r3x4:
        _log('Applying 3:4 crop...');
        image = _cropService.cropToAspect(
          image,
          3,
          4,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r9x16:
        _log('Applying 9:16 crop...');
        image = _cropService.cropToAspect(
          image,
          9,
          16,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r16x9:
        _log('Applying 16:9 crop...');
        image = _cropService.cropToAspect(
          image,
          16,
          9,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
    }

    // 임시 파일은 무손실 PNG로 저장
    _log('Starting image encoding to PNG (lossless)...');
    final encodeParams = EncodeParams(image, true, 6);
    final outBytes = await compute(encodeImageInIsolate, encodeParams);
    _log('Encoding completed');

    // 임시 디렉토리에 PNG로 저장
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outPath = '${tempDir.path}/edited_$timestamp.png';

    await File(outPath).writeAsBytes(outBytes);
    _log('Temp file saved: $outPath');
    _log('File size: ${outBytes.length} bytes');
    _log('========== SAVE TEMP EDITS END ==========');

    return outPath;
  }

  /// 모든 편집 적용하여 최종 이미지 생성
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

    final bytes = await File(imagePath).readAsBytes();

    // 포맷별 디코더 사용
    img.Image? image;
    final ext = imagePath.toLowerCase().split('.').last;
    if (ext == 'jpg' || ext == 'jpeg') {
      image = img.decodeJpg(bytes);
      _log('Decoded as JPEG with format-specific decoder');
    } else if (ext == 'png') {
      image = img.decodePng(bytes);
      _log('Decoded as PNG with format-specific decoder');
    } else {
      image = img.decodeImage(bytes);
      _log('Decoded with generic decoder');
    }

    if (image == null) throw Exception('Unsupported image: $imagePath');

    _log('Original image format: ${image.numChannels} channels');
    _log('Image size: ${image.width}x${image.height}');

    // 회전 및 플립
    if (rotation % 360 != 0) {
      image = img.copyRotate(image, angle: rotation);
    }
    if (flipH) {
      image = img.flipHorizontal(image);
    }
    if (brightness != 0.0) {
      image = img.adjustColor(image, brightness: brightness);
    }

    // 고급 밝기 조정
    image = await _applyBrightnessAdjustments(image, brightnessAdjustments);

    // LUT 필터 적용
    if (filter != null && lutService != null) {
      _log('Applying LUT filter: $filter (intensity: $filterIntensity)');
      final lut = lutService.getLut(filter);
      if (lut != null) {
        final lutParams = brightness_funcs.LutParams(image, lut, filterIntensity);
        image = await compute(brightness_funcs.applyLutInIsolate, lutParams);
        _log('LUT filter applied successfully with intensity $filterIntensity');
      } else {
        _log('LUT not found for filter: $filter');
      }
    }

    // 그레인 효과 적용
    if (filmEffects.grainTexture != null && filmEffects.grainIntensity > 0) {
      _log('Applying grain effect: ${filmEffects.grainTexture} (intensity: ${filmEffects.grainIntensity})');
      image = await _applyGrainEffect(
        image,
        filmEffects.grainTexture!,
        filmEffects.grainIntensity,
      );
    }

    // 더스트 효과 적용
    if (filmEffects.dustTexture != null && filmEffects.dustIntensity > 0) {
      _log('Applying dust effect: ${filmEffects.dustTexture} (intensity: ${filmEffects.dustIntensity})');
      image = await _applyDustEffect(
        image,
        filmEffects.dustTexture!,
        filmEffects.dustIntensity,
      );
    }

    // 크롭 적용
    image = _applyCrop(
      image,
      crop,
      cropOffset,
      cropScale,
      freeformCropRect,
      screenSize,
    );

    // 원본 파일 확장자 확인
    final originalExt = imagePath.toLowerCase().split('.').last;
    final isPng = originalExt == 'png';

    // 인코딩
    _log('Starting image encoding in background...');
    _log('Output format: ${isPng ? 'PNG' : 'JPEG'}');
    final encodeParams = EncodeParams(
      image,
      isPng,
      isPng ? 6 : 95,
    );
    final outBytes = await compute(encodeImageInIsolate, encodeParams);
    _log('Encoding completed');
    _log('File size: ${outBytes.length} bytes');
    _log('========== PROCESS FULL EDIT END ==========');

    return outBytes;
  }

  /// 밝기 조정 적용
  Future<img.Image> _applyBrightnessAdjustments(
    img.Image image,
    BrightnessAdjustments adj,
  ) async {
    if (adj.exposure != 0.0) {
      final adjust = (adj.exposure * 100).round();
      final params = brightness_funcs.ExposureParams(image, adjust);
      image = await compute(brightness_funcs.applyExposureInIsolate, params);
    }
    if (adj.contrast != 0.0) {
      final contrastValue = 1.0 + adj.contrast;
      image = img.adjustColor(image, contrast: contrastValue);
    }
    if (adj.saturation != 0.0) {
      final saturationValue = 1.0 + adj.saturation;
      image = img.adjustColor(image, saturation: saturationValue);
    }
    if (adj.highlights != 0.0 || adj.shadows != 0.0) {
      final params = brightness_funcs.HighlightsShadowsParams(
        image,
        adj.highlights,
        adj.shadows,
      );
      image = await compute(
        brightness_funcs.applyHighlightsShadowsInIsolate,
        params,
      );
    }
    if (adj.whites != 0.0 || adj.blacks != 0.0) {
      final params = brightness_funcs.WhitesBlacksParams(
        image,
        adj.whites,
        adj.blacks,
      );
      image = await compute(
        brightness_funcs.applyWhitesBlacksInIsolate,
        params,
      );
    }
    if (adj.warmth != 0.0) {
      final params = brightness_funcs.WarmthParams(image, adj.warmth);
      image = await compute(brightness_funcs.applyWarmthInIsolate, params);
    }
    if (adj.sharpness != 0.0 && adj.sharpness > 0) {
      final params = brightness_funcs.SharpenParams(image, adj.sharpness);
      image = await compute(brightness_funcs.applySharpenInIsolate, params);
    }
    if (adj.noiseReduction > 0) {
      final radius = (adj.noiseReduction * 3).toInt().clamp(1, 5);
      image = img.gaussianBlur(image, radius: radius);
    }
    return image;
  }

  /// 그레인 효과 적용
  Future<img.Image> _applyGrainEffect(
    img.Image image,
    String grainTexture,
    double intensity,
  ) async {
    try {
      final grainAsset =
          await rootBundle.load(GrainTextures.getAssetPath(grainTexture));
      final grainBytes = grainAsset.buffer.asUint8List();
      var grainImage = img.decodeImage(grainBytes);

      if (grainImage != null) {
        final resizedGrain =
            img.copyResize(grainImage, width: image.width, height: image.height);
        image = blendImages(image, resizedGrain, intensity);
        _log('Grain effect applied successfully');
      }
    } catch (e) {
      _log('Error applying grain effect: $e');
    }
    return image;
  }

  /// 더스트 효과 적용
  Future<img.Image> _applyDustEffect(
    img.Image image,
    String dustTexture,
    double intensity,
  ) async {
    try {
      final dustAsset =
          await rootBundle.load(DustTextures.getAssetPath(dustTexture));
      final dustBytes = dustAsset.buffer.asUint8List();
      final decodedDust = img.decodeImage(dustBytes);

      if (decodedDust != null) {
        final dustImage =
            img.copyResize(decodedDust, width: image.width, height: image.height);
        image = blendImages(image, dustImage, intensity);
        _log('Dust effect applied successfully');
      }
    } catch (e) {
      _log('Error applying dust effect: $e');
    }
    return image;
  }

  /// 크롭 적용
  img.Image _applyCrop(
    img.Image image,
    CropPreset crop,
    Offset cropOffset,
    double cropScale,
    Rect? freeformCropRect,
    Size screenSize,
  ) {
    _log('Current crop preset: $crop');
    _log('Crop offset: $cropOffset, scale: $cropScale');

    switch (crop) {
      case CropPreset.original:
        _log('No crop applied (original preset)');
        break;
      case CropPreset.freeform:
        if (freeformCropRect != null && freeformCropRect != Rect.zero) {
          _log('Applying freeform crop...');
          _log('Freeform rect: $freeformCropRect');
          image = _cropService.freeformCrop(image, freeformCropRect, screenSize);
        } else {
          _log('⚠️ Freeform crop skipped: rect is null or zero');
        }
        break;
      case CropPreset.square:
        _log('Applying square crop...');
        image = _cropService.cropToAspect(
          image,
          1,
          1,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r4x5:
        _log('Applying 4:5 crop...');
        image = _cropService.cropToAspect(
          image,
          4,
          5,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r3x4:
        _log('Applying 3:4 crop...');
        image = _cropService.cropToAspect(
          image,
          3,
          4,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r9x16:
        _log('Applying 9:16 crop...');
        image = _cropService.cropToAspect(
          image,
          9,
          16,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
      case CropPreset.r16x9:
        _log('Applying 16:9 crop...');
        image = _cropService.cropToAspect(
          image,
          16,
          9,
          cropOffset,
          cropScale,
          screenSize,
        );
        break;
    }

    return image;
  }
}
