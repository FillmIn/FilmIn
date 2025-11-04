import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../widgets/brightness/brightness_tool.dart';
import 'lut_filter_service.dart';

/// 밝기 조정 통합 서비스
///
/// 동기 방식(빠른 미리보기)과 비동기 방식(고품질 처리)을 모두 지원합니다.
class BrightnessService {
  /// 동기 방식 밝기 조정 (메인 스레드에서 실행, 빠른 미리보기용)
  img.Image applyQuick(
    img.Image image,
    double brightness,
    BrightnessAdjustments adjustments,
  ) {
    // 기본 밝기 조정
    if (brightness != 0.0) {
      final brightVal = (brightness * 50).toInt();
      image = img.adjustColor(image, brightness: brightVal);
    }

    // Exposure
    if (adjustments.exposure != 0.0) {
      final expVal = (adjustments.exposure * 40).toInt();
      image = img.adjustColor(image, brightness: expVal);
    }

    // Contrast
    if (adjustments.contrast != 0.0) {
      final contrastVal = (adjustments.contrast * 50 + 100).toInt();
      image = img.adjustColor(image, contrast: contrastVal);
    }

    // Saturation
    if (adjustments.saturation != 0.0) {
      final satVal = (adjustments.saturation * 0.5 + 1.0);
      image = img.adjustColor(image, saturation: satVal);
    }

    // Warmth (색온도)
    if (adjustments.warmth != 0.0) {
      image = _applyWarmth(image, adjustments.warmth);
    }

    // Highlights
    if (adjustments.highlights != 0.0) {
      image = _applyHighlights(image, adjustments.highlights);
    }

    // Shadows
    if (adjustments.shadows != 0.0) {
      image = _applyShadows(image, adjustments.shadows);
    }

    // Whites
    if (adjustments.whites != 0.0) {
      image = _applyWhites(image, adjustments.whites);
    }

    // Blacks
    if (adjustments.blacks != 0.0) {
      image = _applyBlacks(image, adjustments.blacks);
    }

    // Sharpness
    if (adjustments.sharpness != 0.0) {
      image = _applySharpen(image, adjustments.sharpness);
    }

    return image;
  }

  /// 비동기 방식 밝기 조정 (Isolate에서 실행, 고품질 처리용)
  Future<img.Image> applyIsolate(
    img.Image image,
    double brightness,
    BrightnessAdjustments adjustments,
  ) async {
    final params = _BrightnessParams(image, brightness, adjustments);
    return await compute(_applyInIsolate, params);
  }

  /// LUT 필터 적용 (Isolate에서 실행)
  Future<img.Image> applyLutIsolate(
    img.Image image,
    Lut3D lut,
    double intensity,
  ) async {
    final params = _LutParams(image, lut, intensity);
    return await compute(_applyLutInIsolate, params);
  }

  // ========== 내부 헬퍼 메서드들 (동기 방식) ==========

  img.Image _applyWarmth(img.Image image, double warmth) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = (pixel.r + warmth * 20).clamp(0, 255).toInt();
        final b = (pixel.b - warmth * 20).clamp(0, 255).toInt();
        image.setPixel(x, y, img.ColorRgba8(r, pixel.g.toInt(), b, pixel.a.toInt()));
      }
    }
    return image;
  }

  img.Image _applyHighlights(img.Image image, double highlights) {
    final highlightAdj = highlights * 30;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

        if (luminance > 180) {
          final factor = (luminance - 180) / 75;
          final r = (pixel.r + highlightAdj * factor).clamp(0, 255).toInt();
          final g = (pixel.g + highlightAdj * factor).clamp(0, 255).toInt();
          final b = (pixel.b + highlightAdj * factor).clamp(0, 255).toInt();
          image.setPixel(x, y, img.ColorRgba8(r, g, b, pixel.a.toInt()));
        }
      }
    }
    return image;
  }

  img.Image _applyShadows(img.Image image, double shadows) {
    final shadowAdj = shadows * 30;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

        if (luminance < 75) {
          final factor = (75 - luminance) / 75;
          final r = (pixel.r + shadowAdj * factor).clamp(0, 255).toInt();
          final g = (pixel.g + shadowAdj * factor).clamp(0, 255).toInt();
          final b = (pixel.b + shadowAdj * factor).clamp(0, 255).toInt();
          image.setPixel(x, y, img.ColorRgba8(r, g, b, pixel.a.toInt()));
        }
      }
    }
    return image;
  }

  img.Image _applyWhites(img.Image image, double whites) {
    final whitesAdj = whites * 25;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

        if (luminance > 200) {
          final r = (pixel.r + whitesAdj).clamp(0, 255).toInt();
          final g = (pixel.g + whitesAdj).clamp(0, 255).toInt();
          final b = (pixel.b + whitesAdj).clamp(0, 255).toInt();
          image.setPixel(x, y, img.ColorRgba8(r, g, b, pixel.a.toInt()));
        }
      }
    }
    return image;
  }

  img.Image _applyBlacks(img.Image image, double blacks) {
    final blacksAdj = blacks * 25;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final luminance = 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;

        if (luminance < 55) {
          final r = (pixel.r + blacksAdj).clamp(0, 255).toInt();
          final g = (pixel.g + blacksAdj).clamp(0, 255).toInt();
          final b = (pixel.b + blacksAdj).clamp(0, 255).toInt();
          image.setPixel(x, y, img.ColorRgba8(r, g, b, pixel.a.toInt()));
        }
      }
    }
    return image;
  }

  img.Image _applySharpen(img.Image image, double amount) {
    final strength = amount * 2;
    final result = img.Image.from(image);

    final kernel = [
      [0, -strength, 0],
      [-strength, 1 + 4 * strength, -strength],
      [0, -strength, 0],
    ];

    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        var r = 0.0, g = 0.0, b = 0.0;

        for (var ky = 0; ky < 3; ky++) {
          for (var kx = 0; kx < 3; kx++) {
            final px = image.getPixel(x + kx - 1, y + ky - 1);
            final weight = kernel[ky][kx];
            r += px.r * weight;
            g += px.g * weight;
            b += px.b * weight;
          }
        }

        final pixel = image.getPixel(x, y);
        result.setPixelRgba(
          x,
          y,
          r.clamp(0, 255).toInt(),
          g.clamp(0, 255).toInt(),
          b.clamp(0, 255).toInt(),
          pixel.a.toInt(),
        );
      }
    }

    return result;
  }

  // ========== Isolate에서 실행될 정적 메서드들 ==========

  static img.Image _applyInIsolate(_BrightnessParams params) {
    var image = img.Image.from(params.image);
    final brightness = params.brightness;
    final adj = params.adjustments;

    // 기본 밝기
    if (brightness != 0.0) {
      final brightVal = (brightness * 50).toInt();
      image = img.adjustColor(image, brightness: brightVal);
    }

    // Exposure
    if (adj.exposure != 0.0) {
      final adjust = (adj.exposure * 40).toInt();
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = (pixel.r.toInt() + adjust).clamp(0, 255).toInt();
          final g = (pixel.g.toInt() + adjust).clamp(0, 255).toInt();
          final b = (pixel.b.toInt() + adjust).clamp(0, 255).toInt();
          image.setPixelRgba(x, y, r, g, b, pixel.a.toInt());
        }
      }
    }

    // Contrast
    if (adj.contrast != 0.0) {
      final contrastVal = (adj.contrast * 50 + 100).toInt();
      image = img.adjustColor(image, contrast: contrastVal);
    }

    // Highlights & Shadows
    if (adj.highlights != 0.0 || adj.shadows != 0.0) {
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
          final highlightWeight = luminance / 255.0;
          final shadowWeight = 1.0 - highlightWeight;

          final highlightAdj = adj.highlights * 255 * highlightWeight;
          final shadowAdj = adj.shadows * 255 * shadowWeight;

          final newR = (r + highlightAdj + shadowAdj).clamp(0, 255).toInt();
          final newG = (g + highlightAdj + shadowAdj).clamp(0, 255).toInt();
          final newB = (b + highlightAdj + shadowAdj).clamp(0, 255).toInt();

          image.setPixelRgba(x, y, newR, newG, newB, pixel.a.toInt());
        }
      }
    }

    // Whites & Blacks
    if (adj.whites != 0.0 || adj.blacks != 0.0) {
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
          final whiteWeight = (luminance > 200) ? (luminance - 200) / 55.0 : 0.0;
          final blackWeight = (luminance < 55) ? (55 - luminance) / 55.0 : 0.0;

          final whiteAdj = adj.whites * 255 * whiteWeight;
          final blackAdj = adj.blacks * 255 * blackWeight;

          final newR = (r + whiteAdj + blackAdj).clamp(0, 255).toInt();
          final newG = (g + whiteAdj + blackAdj).clamp(0, 255).toInt();
          final newB = (b + whiteAdj + blackAdj).clamp(0, 255).toInt();

          image.setPixelRgba(x, y, newR, newG, newB, pixel.a.toInt());
        }
      }
    }

    // Saturation
    if (adj.saturation != 0.0) {
      final satVal = (adj.saturation * 0.5 + 1.0);
      image = img.adjustColor(image, saturation: satVal);
    }

    // Warmth
    if (adj.warmth != 0.0) {
      final rAdj = (adj.warmth * 30).toInt();
      final bAdj = (-adj.warmth * 30).toInt();

      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = (pixel.r.toInt() + rAdj).clamp(0, 255).toInt();
          final b = (pixel.b.toInt() + bAdj).clamp(0, 255).toInt();
          image.setPixelRgba(x, y, r, pixel.g.toInt(), b, pixel.a.toInt());
        }
      }
    }

    // Sharpness
    if (adj.sharpness != 0.0) {
      final strength = adj.sharpness * 2;
      final result = img.Image.from(image);

      final kernel = [
        [0, -strength, 0],
        [-strength, 1 + 4 * strength, -strength],
        [0, -strength, 0],
      ];

      for (var y = 1; y < image.height - 1; y++) {
        for (var x = 1; x < image.width - 1; x++) {
          var r = 0.0, g = 0.0, b = 0.0;

          for (var ky = 0; ky < 3; ky++) {
            for (var kx = 0; kx < 3; kx++) {
              final px = image.getPixel(x + kx - 1, y + ky - 1);
              final weight = kernel[ky][kx];
              r += px.r * weight;
              g += px.g * weight;
              b += px.b * weight;
            }
          }

          final pixel = image.getPixel(x, y);
          result.setPixelRgba(
            x,
            y,
            r.clamp(0, 255).toInt(),
            g.clamp(0, 255).toInt(),
            b.clamp(0, 255).toInt(),
            pixel.a.toInt(),
          );
        }
      }

      image = result;
    }

    return image;
  }

  static img.Image _applyLutInIsolate(_LutParams params) {
    final result = img.Image.from(params.image);
    final lut = params.lut;
    final intensity = params.intensity;

    for (var y = 0; y < result.height; y++) {
      for (var x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);

        // Normalize RGB values to [0,1] range
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        // Direct 3D LUT lookup with trilinear interpolation
        final outputColor = _interpolateLut3D(lut, r, g, b);

        // Blend original and filtered colors based on intensity
        final finalR = r * (1.0 - intensity) + outputColor[0] * intensity;
        final finalG = g * (1.0 - intensity) + outputColor[1] * intensity;
        final finalB = b * (1.0 - intensity) + outputColor[2] * intensity;

        result.setPixelRgba(
          x,
          y,
          (finalR * 255).clamp(0, 255).toInt(),
          (finalG * 255).clamp(0, 255).toInt(),
          (finalB * 255).clamp(0, 255).toInt(),
          pixel.a.toInt(),
        );
      }
    }

    return result;
  }

  static List<double> _interpolateLut3D(Lut3D lut, double r, double g, double b) {
    final size = lut.size;

    // Convert [0,1] range to LUT indices
    final rIndex = (r * (size - 1)).clamp(0.0, (size - 1).toDouble());
    final gIndex = (g * (size - 1)).clamp(0.0, (size - 1).toDouble());
    final bIndex = (b * (size - 1)).clamp(0.0, (size - 1).toDouble());

    // Find surrounding 8 points for trilinear interpolation
    final r0 = rIndex.floor();
    final r1 = (r0 + 1).clamp(0, size - 1);
    final g0 = gIndex.floor();
    final g1 = (g0 + 1).clamp(0, size - 1);
    final b0 = bIndex.floor();
    final b1 = (b0 + 1).clamp(0, size - 1);

    // Calculate weights
    final rWeight = rIndex - r0;
    final gWeight = gIndex - g0;
    final bWeight = bIndex - b0;

    // Get values at 8 surrounding points
    final c000 = _getLutValue3D(lut, r0, g0, b0);
    final c001 = _getLutValue3D(lut, r0, g0, b1);
    final c010 = _getLutValue3D(lut, r0, g1, b0);
    final c011 = _getLutValue3D(lut, r0, g1, b1);
    final c100 = _getLutValue3D(lut, r1, g0, b0);
    final c101 = _getLutValue3D(lut, r1, g0, b1);
    final c110 = _getLutValue3D(lut, r1, g1, b0);
    final c111 = _getLutValue3D(lut, r1, g1, b1);

    // Trilinear interpolation
    final c00 = _lerp3D(c000, c001, bWeight);
    final c01 = _lerp3D(c010, c011, bWeight);
    final c10 = _lerp3D(c100, c101, bWeight);
    final c11 = _lerp3D(c110, c111, bWeight);

    final c0 = _lerp3D(c00, c01, gWeight);
    final c1 = _lerp3D(c10, c11, gWeight);

    return _lerp3D(c0, c1, rWeight);
  }

  static List<double> _getLutValue3D(Lut3D lut, int r, int g, int b) {
    final index = r + g * lut.size + b * lut.size * lut.size;
    if (index >= 0 && index < lut.entries.length) {
      final entry = lut.entries[index];
      return [entry.r, entry.g, entry.b];
    }
    return [0.0, 0.0, 0.0];
  }

  static List<double> _lerp3D(List<double> a, List<double> b, double t) {
    return [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
      a[2] + (b[2] - a[2]) * t,
    ];
  }
}

// ========== Isolate 파라미터 클래스들 ==========

class _BrightnessParams {
  final img.Image image;
  final double brightness;
  final BrightnessAdjustments adjustments;

  _BrightnessParams(this.image, this.brightness, this.adjustments);
}

class _LutParams {
  final img.Image image;
  final Lut3D lut;
  final double intensity;

  _LutParams(this.image, this.lut, this.intensity);
}
