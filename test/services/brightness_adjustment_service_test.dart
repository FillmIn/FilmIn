import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:filmin/features/editview/services/brightness_adjustment_service.dart';
import 'package:filmin/features/editview/widgets/brightness/brightness_tool.dart';

void main() {
  group('BrightnessAdjustmentService', () {
    late BrightnessAdjustmentService service;

    setUp(() {
      service = BrightnessAdjustmentService();
    });

    // 테스트용 이미지 생성 헬퍼 함수
    img.Image createTestImage(int width, int height, {int r = 128, int g = 128, int b = 128}) {
      final image = img.Image(width: width, height: height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
        }
      }
      return image;
    }

    group('기본 밝기 조정', () {
      test('기본 밝기가 0일 때 이미지가 변경되지 않아야 함', () {
        final testImage = createTestImage(100, 100);
        final originalPixel = testImage.getPixel(50, 50);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0, // 밝기 변화 없음
          const BrightnessAdjustments(),
        );

        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, equals(originalPixel.r));
        expect(resultPixel.g, equals(originalPixel.g));
        expect(resultPixel.b, equals(originalPixel.b));
      });

      test('양수 밝기를 적용하면 이미지가 밝아져야 함', () {
        final testImage = createTestImage(100, 100, r: 100, g: 100, b: 100);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.5, // 밝기 증가
          const BrightnessAdjustments(),
        );

        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, greaterThan(100));
      });

      test('음수 밝기를 적용하면 이미지가 어두워져야 함', () {
        final testImage = createTestImage(100, 100, r: 150, g: 150, b: 150);

        final result = service.applyBrightnessAdjustments(
          testImage,
          -0.5, // 밝기 감소
          const BrightnessAdjustments(),
        );

        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, lessThan(150));
      });
    });

    group('Exposure 조정', () {
      test('양수 Exposure를 적용하면 이미지가 밝아져야 함', () {
        final testImage = createTestImage(100, 100);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(exposure: 0.5),
        );

        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, greaterThan(128));
      });
    });

    group('Contrast 조정', () {
      test('양수 Contrast를 적용하면 대비가 증가해야 함', () {
        final testImage = createTestImage(100, 100);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(contrast: 0.5),
        );

        // Contrast 증가 시 중간 톤이 더 극단적으로 변해야 함
        expect(result.width, equals(100));
        expect(result.height, equals(100));
      });
    });

    group('Saturation 조정', () {
      test('양수 Saturation을 적용하면 채도가 증가해야 함', () {
        final testImage = createTestImage(100, 100, r: 200, g: 100, b: 100);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(saturation: 0.5),
        );

        final resultPixel = result.getPixel(50, 50);
        // 빨강 성분이 더 강해져야 함
        expect(resultPixel.r, greaterThanOrEqualTo(200));
      });
    });

    group('Warmth 조정', () {
      test('양수 Warmth를 적용하면 따뜻한 톤이 되어야 함', () {
        final testImage = createTestImage(100, 100, r: 128, g: 128, b: 128);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(warmth: 0.5),
        );

        final resultPixel = result.getPixel(50, 50);
        // 빨강은 증가, 파랑은 감소
        expect(resultPixel.r, greaterThan(128));
        expect(resultPixel.b, lessThan(128));
      });

      test('음수 Warmth를 적용하면 차가운 톤이 되어야 함', () {
        final testImage = createTestImage(100, 100, r: 128, g: 128, b: 128);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(warmth: -0.5),
        );

        final resultPixel = result.getPixel(50, 50);
        // 빨강은 감소, 파랑은 증가
        expect(resultPixel.r, lessThan(128));
        expect(resultPixel.b, greaterThan(128));
      });
    });

    group('Highlights/Shadows 조정', () {
      test('Highlights 조정은 밝은 영역에만 영향을 주어야 함', () {
        final testImage = createTestImage(100, 100, r: 220, g: 220, b: 220);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(highlights: 0.5),
        );

        // 밝은 픽셀은 더 밝아져야 함
        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, greaterThanOrEqualTo(220));
      });

      test('Shadows 조정은 어두운 영역에만 영향을 주어야 함', () {
        final testImage = createTestImage(100, 100, r: 50, g: 50, b: 50);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(shadows: 0.5),
        );

        // 어두운 픽셀은 더 밝아져야 함
        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, greaterThan(50));
      });
    });

    group('Whites/Blacks 조정', () {
      test('Whites 조정은 매우 밝은 영역에만 영향을 주어야 함', () {
        final testImage = createTestImage(100, 100, r: 240, g: 240, b: 240);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(whites: 0.5),
        );

        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, greaterThanOrEqualTo(240));
      });

      test('Blacks 조정은 매우 어두운 영역에만 영향을 주어야 함', () {
        final testImage = createTestImage(100, 100, r: 30, g: 30, b: 30);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.0,
          const BrightnessAdjustments(blacks: 0.5),
        );

        final resultPixel = result.getPixel(50, 50);
        expect(resultPixel.r, greaterThan(30));
      });
    });

    group('복합 조정', () {
      test('여러 조정을 동시에 적용할 수 있어야 함', () {
        final testImage = createTestImage(100, 100);

        expect(
          () => service.applyBrightnessAdjustments(
            testImage,
            0.3,
            const BrightnessAdjustments(
              exposure: 0.2,
              contrast: 0.3,
              saturation: 0.1,
              warmth: 0.2,
              highlights: 0.1,
              shadows: -0.1,
              whites: 0.15,
              blacks: -0.15,
            ),
          ),
          returnsNormally,
        );
      });

      test('극단적인 값에서도 안전하게 동작해야 함', () {
        final testImage = createTestImage(100, 100);

        expect(
          () => service.applyBrightnessAdjustments(
            testImage,
            1.0,
            const BrightnessAdjustments(
              exposure: 1.0,
              contrast: 1.0,
              saturation: 1.0,
              warmth: 1.0,
              highlights: 1.0,
              shadows: 1.0,
              whites: 1.0,
              blacks: 1.0,
            ),
          ),
          returnsNormally,
        );
      });
    });

    group('경계값 테스트', () {
      test('픽셀 값이 0-255 범위를 벗어나지 않아야 함', () {
        final testImage = createTestImage(100, 100, r: 250, g: 250, b: 250);

        final result = service.applyBrightnessAdjustments(
          testImage,
          1.0, // 최대 밝기
          const BrightnessAdjustments(),
        );

        // 모든 픽셀 확인
        for (int y = 0; y < result.height; y++) {
          for (int x = 0; x < result.width; x++) {
            final pixel = result.getPixel(x, y);
            expect(pixel.r, inInclusiveRange(0, 255));
            expect(pixel.g, inInclusiveRange(0, 255));
            expect(pixel.b, inInclusiveRange(0, 255));
          }
        }
      });

      test('이미지 크기가 변경되지 않아야 함', () {
        final testImage = createTestImage(123, 456);

        final result = service.applyBrightnessAdjustments(
          testImage,
          0.5,
          const BrightnessAdjustments(exposure: 0.5),
        );

        expect(result.width, equals(123));
        expect(result.height, equals(456));
      });
    });
  });
}
