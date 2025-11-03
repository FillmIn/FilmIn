import 'package:image/image.dart' as img;
import 'services/lut_filter_service.dart';

// ========== Isolate 파라미터 클래스들 ==========

class ExposureParams {
  final img.Image image;
  final int adjust;

  ExposureParams(this.image, this.adjust);
}

class HighlightsShadowsParams {
  final img.Image image;
  final double highlights;
  final double shadows;

  HighlightsShadowsParams(this.image, this.highlights, this.shadows);
}

class WhitesBlacksParams {
  final img.Image image;
  final double whites;
  final double blacks;

  WhitesBlacksParams(this.image, this.whites, this.blacks);
}

class WarmthParams {
  final img.Image image;
  final double warmth;

  WarmthParams(this.image, this.warmth);
}

class SharpenParams {
  final img.Image image;
  final double amount;

  SharpenParams(this.image, this.amount);
}

class LutParams {
  final img.Image image;
  final Lut3D lut;
  final double intensity;

  LutParams(this.image, this.lut, [this.intensity = 1.0]);
}

// ========== Isolate에서 실행할 함수들 ==========

img.Image applyExposureInIsolate(ExposureParams params) {
  final result = img.Image.from(params.image);
  final adjust = params.adjust;

  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final pixel = result.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      final newR = (r + adjust).clamp(0, 255).toInt();
      final newG = (g + adjust).clamp(0, 255).toInt();
      final newB = (b + adjust).clamp(0, 255).toInt();

      result.setPixelRgba(x, y, newR, newG, newB, pixel.a.toInt());
    }
  }

  return result;
}

img.Image applyHighlightsShadowsInIsolate(HighlightsShadowsParams params) {
  final result = img.Image.from(params.image);

  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final pixel = result.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
      final highlightWeight = luminance / 255.0;
      final shadowWeight = 1.0 - highlightWeight;

      final highlightAdj = params.highlights * 255 * highlightWeight;
      final shadowAdj = params.shadows * 255 * shadowWeight;

      final newR = (r + highlightAdj + shadowAdj).clamp(0, 255).toInt();
      final newG = (g + highlightAdj + shadowAdj).clamp(0, 255).toInt();
      final newB = (b + highlightAdj + shadowAdj).clamp(0, 255).toInt();

      result.setPixelRgba(x, y, newR, newG, newB, pixel.a.toInt());
    }
  }

  return result;
}

img.Image applyWhitesBlacksInIsolate(WhitesBlacksParams params) {
  final result = img.Image.from(params.image);

  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final pixel = result.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
      final whiteWeight = (luminance > 200) ? (luminance - 200) / 55.0 : 0.0;
      final blackWeight = (luminance < 55) ? (55 - luminance) / 55.0 : 0.0;

      final whiteAdj = params.whites * 255 * whiteWeight;
      final blackAdj = params.blacks * 255 * blackWeight;

      final newR = (r + whiteAdj + blackAdj).clamp(0, 255).toInt();
      final newG = (g + whiteAdj + blackAdj).clamp(0, 255).toInt();
      final newB = (b + whiteAdj + blackAdj).clamp(0, 255).toInt();

      result.setPixelRgba(x, y, newR, newG, newB, pixel.a.toInt());
    }
  }

  return result;
}

img.Image applyWarmthInIsolate(WarmthParams params) {
  final result = img.Image.from(params.image);
  final rAdj = (params.warmth * 30).toInt();
  final bAdj = (-params.warmth * 30).toInt();

  for (var y = 0; y < result.height; y++) {
    for (var x = 0; x < result.width; x++) {
      final pixel = result.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      final newR = (r + rAdj).clamp(0, 255).toInt();
      final newB = (b + bAdj).clamp(0, 255).toInt();

      result.setPixelRgba(x, y, newR, g, newB, pixel.a.toInt());
    }
  }

  return result;
}

img.Image applySharpenInIsolate(SharpenParams params) {
  final src = params.image;
  final strength = params.amount * 2;
  final result = img.Image.from(src);

  final kernel = [
    [0, -strength, 0],
    [-strength, 1 + 4 * strength, -strength],
    [0, -strength, 0],
  ];

  for (var y = 1; y < src.height - 1; y++) {
    for (var x = 1; x < src.width - 1; x++) {
      var r = 0.0, g = 0.0, b = 0.0;

      for (var ky = 0; ky < 3; ky++) {
        for (var kx = 0; kx < 3; kx++) {
          final px = src.getPixel(x + kx - 1, y + ky - 1);
          final weight = kernel[ky][kx];
          r += px.r * weight;
          g += px.g * weight;
          b += px.b * weight;
        }
      }

      final pixel = src.getPixel(x, y);
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

img.Image applyLutInIsolate(LutParams params) {
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
      // intensity = 0.0: original color, intensity = 1.0: full filter
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

List<double> _interpolateLut3D(Lut3D lut, double r, double g, double b) {
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

List<double> _getLutValue3D(Lut3D lut, int r, int g, int b) {
  final index = r + g * lut.size + b * lut.size * lut.size;
  if (index >= 0 && index < lut.entries.length) {
    final entry = lut.entries[index];
    return [entry.r, entry.g, entry.b];
  }
  return [0.0, 0.0, 0.0];
}

List<double> _lerp3D(List<double> a, List<double> b, double t) {
  return [
    a[0] + (b[0] - a[0]) * t,
    a[1] + (b[1] - a[1]) * t,
    a[2] + (b[2] - a[2]) * t,
  ];
}
