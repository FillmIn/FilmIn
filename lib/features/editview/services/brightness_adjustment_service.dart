import 'package:image/image.dart' as img;
import '../widgets/brightness/brightness_tool.dart';

/// 밝기 조정 서비스
class BrightnessAdjustmentService {
  /// 밝기 조정 적용
  img.Image applyBrightnessAdjustments(
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
      final warmth = adjustments.warmth;
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final r = (pixel.r + warmth * 20).clamp(0, 255).toInt();
          final b = (pixel.b - warmth * 20).clamp(0, 255).toInt();
          image.setPixel(x, y, img.ColorRgba8(r, pixel.g.toInt(), b, pixel.a.toInt()));
        }
      }
    }

    // Highlights
    if (adjustments.highlights != 0.0) {
      final highlightAdj = adjustments.highlights * 30;
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
    }

    // Shadows
    if (adjustments.shadows != 0.0) {
      final shadowAdj = adjustments.shadows * 30;
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
    }

    // Whites
    if (adjustments.whites != 0.0) {
      final whitesAdj = adjustments.whites * 25;
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
    }

    // Blacks
    if (adjustments.blacks != 0.0) {
      final blacksAdj = adjustments.blacks * 25;
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
    }

    return image;
  }
}
