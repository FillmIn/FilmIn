import 'package:image/image.dart' as img;

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
