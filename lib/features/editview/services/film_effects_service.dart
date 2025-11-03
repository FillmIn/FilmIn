import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../widgets/effect/effect_models.dart';

/// 필름 효과 서비스 (그레인, 더스트, 할레이션)
class FilmEffectsService {
  void _log(String message) {
    print('[FilmEffectsService] $message');
  }

  /// 그레인 효과 적용
  Future<img.Image> applyGrainEffect(
    img.Image image,
    String grainTexture,
    double intensity,
  ) async {
    try {
      final grainAsset = await rootBundle.load(GrainTextures.getAssetPath(grainTexture));
      final grainBytes = grainAsset.buffer.asUint8List();
      final decodedGrain = img.decodeImage(grainBytes);

      if (decodedGrain != null) {
        final resizedGrain = img.copyResize(
          decodedGrain,
          width: image.width,
          height: image.height,
        );

        image = _blendGrain(image, resizedGrain, intensity);
        _log('Grain effect applied: $grainTexture');
      }
    } catch (e) {
      _log('Error applying grain effect: $e');
    }
    return image;
  }

  /// 더스트 효과 적용
  Future<img.Image> applyDustEffect(
    img.Image image,
    String dustTexture,
    double intensity,
  ) async {
    try {
      final dustAsset = await rootBundle.load(DustTextures.getAssetPath(dustTexture));
      final dustBytes = dustAsset.buffer.asUint8List();
      final decodedDust = img.decodeImage(dustBytes);

      if (decodedDust != null) {
        final resizedDust = img.copyResize(
          decodedDust,
          width: image.width,
          height: image.height,
        );

        image = _blendDust(image, resizedDust, intensity);
        _log('Dust effect applied: $dustTexture');
      }
    } catch (e) {
      _log('Error applying dust effect: $e');
    }
    return image;
  }

  /// 할레이션 효과 적용 (가우시안 블러 - 흰색 부분만 번짐)
  img.Image applyHalationEffect(img.Image image, double intensity) {
    try {
      // 밝은 부분만 추출
      final mask = img.Image(width: image.width, height: image.height);

      // RGB 210 이상인 밝은 픽셀만 추출
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          if (r >= 210 && g >= 210 && b >= 210) {
            mask.setPixel(x, y, pixel);
          } else {
            mask.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
          }
        }
      }

      // 가우시안 블러 적용
      final blurred = img.gaussianBlur(mask, radius: (25 * intensity).toInt().clamp(5, 30));

      // 원본 이미지에 블렌드
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final basePixel = image.getPixel(x, y);
          final glowPixel = blurred.getPixel(x, y);

          if (glowPixel.a > 0) {
            final blendFactor = intensity * 0.7 * (glowPixel.a / 255.0);
            final r = (basePixel.r + glowPixel.r * blendFactor).toInt().clamp(0, 255);
            final g = (basePixel.g + glowPixel.g * blendFactor).toInt().clamp(0, 255);
            final b = (basePixel.b + glowPixel.b * blendFactor).toInt().clamp(0, 255);

            image.setPixel(x, y, img.ColorRgba8(r, g, b, basePixel.a.toInt()));
          }
        }
      }

      _log('Halation effect applied successfully');
    } catch (e) {
      _log('Error applying halation effect: $e');
    }
    return image;
  }

  /// 그레인 블렌드 (Soft Light 블렌드 모드)
  img.Image _blendGrain(img.Image base, img.Image grain, double intensity) {
    for (int y = 0; y < base.height; y++) {
      for (int x = 0; x < base.width; x++) {
        final basePixel = base.getPixel(x, y);
        final grainPixel = grain.getPixel(x, y);

        final blendedR = _softLightBlend(basePixel.r, grainPixel.r, intensity);
        final blendedG = _softLightBlend(basePixel.g, grainPixel.g, intensity);
        final blendedB = _softLightBlend(basePixel.b, grainPixel.b, intensity);

        base.setPixel(x, y, img.ColorRgba8(blendedR, blendedG, blendedB, basePixel.a.toInt()));
      }
    }
    return base;
  }

  /// 더스트 블렌드 (Multiply 블렌드 모드)
  img.Image _blendDust(img.Image base, img.Image dust, double intensity) {
    for (int y = 0; y < base.height; y++) {
      for (int x = 0; x < base.width; x++) {
        final basePixel = base.getPixel(x, y);
        final dustPixel = dust.getPixel(x, y);

        final blendedR = ((basePixel.r * dustPixel.r / 255) * intensity + basePixel.r * (1 - intensity)).toInt().clamp(0, 255);
        final blendedG = ((basePixel.g * dustPixel.g / 255) * intensity + basePixel.g * (1 - intensity)).toInt().clamp(0, 255);
        final blendedB = ((basePixel.b * dustPixel.b / 255) * intensity + basePixel.b * (1 - intensity)).toInt().clamp(0, 255);

        base.setPixel(x, y, img.ColorRgba8(blendedR, blendedG, blendedB, basePixel.a.toInt()));
      }
    }
    return base;
  }

  /// Soft Light 블렌드 함수
  int _softLightBlend(num base, num overlay, double intensity) {
    final b = base / 255.0;
    final o = overlay / 255.0;

    final result = o < 0.5
        ? 2 * b * o + b * b * (1 - 2 * o)
        : 2 * b * (1 - o) + (b * (1 - (1 - 2 * (o - 0.5)))).clamp(0.0, 1.0);

    final blended = b + (result - b) * intensity;
    return (blended * 255).clamp(0, 255).toInt();
  }
}
