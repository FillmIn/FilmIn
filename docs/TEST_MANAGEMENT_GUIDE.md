# 📋 테스트 코드 관리 가이드

Flutter 프로젝트에서 테스트 코드를 효과적으로 관리하는 방법을 설명합니다.

---

## 📂 테스트 코드 디렉토리 구조

Flutter 프로젝트는 **3가지 유형의 테스트**를 지원합니다:

```
filmin/
├── test/                          # 단위 테스트 (Unit Tests)
│   ├── services/
│   │   ├── brightness_adjustment_service_test.dart
│   │   ├── film_effects_service_test.dart
│   │   └── lut_filter_service_test.dart
│   └── widget_test.dart
│
├── integration_test/               # 통합 테스트 (Integration Tests)
│   ├── app_test.dart
│   └── edit_flow_test.dart
│
└── lib/examples/                   # 개발자 테스트 페이지
    ├── service_test_page.dart      # 수동 테스트용 UI
    └── filter_example_page.dart
```

---

## 🎯 3가지 테스트 유형

### 1. **단위 테스트 (Unit Tests)** - `test/`
**목적:** 개별 함수, 클래스, 메서드를 독립적으로 테스트

**특징:**
- ✅ 빠른 실행 속도 (밀리초 단위)
- ✅ UI 없이 로직만 테스트
- ✅ CI/CD에 적합
- ✅ Mock 객체 사용 가능

**실행 방법:**
```bash
# 모든 단위 테스트 실행
flutter test

# 특정 파일만 실행
flutter test test/services/brightness_adjustment_service_test.dart

# 커버리지 확인
flutter test --coverage
```

**예시:**
```dart
// test/services/brightness_adjustment_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:filmin/features/editview/services/brightness_adjustment_service.dart';
import 'package:filmin/features/editview/widgets/brightness/brightness_tool.dart';

void main() {
  group('BrightnessAdjustmentService', () {
    late BrightnessAdjustmentService service;
    late img.Image testImage;

    setUp(() {
      service = BrightnessAdjustmentService();
      // 100x100 회색 테스트 이미지 생성
      testImage = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          testImage.setPixel(x, y, img.ColorRgba8(128, 128, 128, 255));
        }
      }
    });

    test('밝기 조정이 올바르게 적용되는지 확인', () {
      final adjustments = const BrightnessAdjustments(
        exposure: 0.5,
        contrast: 0.3,
      );

      final result = service.applyBrightnessAdjustments(
        testImage,
        0.2,
        adjustments,
      );

      expect(result.width, 100);
      expect(result.height, 100);
      // 픽셀 값이 변경되었는지 확인
      final centerPixel = result.getPixel(50, 50);
      expect(centerPixel.r, isNot(128)); // 원본과 달라야 함
    });

    test('극단적인 값에서도 안전하게 동작하는지 확인', () {
      final adjustments = const BrightnessAdjustments(
        exposure: 1.0,  // 최대값
        contrast: 1.0,
        saturation: 1.0,
      );

      expect(
        () => service.applyBrightnessAdjustments(testImage, 1.0, adjustments),
        returnsNormally,
      );
    });
  });
}
```

---

### 2. **통합 테스트 (Integration Tests)** - `integration_test/`
**목적:** 앱의 전체 흐름을 실제 기기에서 테스트

**특징:**
- ✅ 실제 기기/에뮬레이터에서 실행
- ✅ 사용자 시나리오 테스트
- ✅ 여러 화면 간 이동 검증
- ❌ 느린 실행 속도 (분 단위)

**실행 방법:**
```bash
# 통합 테스트 실행
flutter test integration_test/app_test.dart

# 특정 기기에서 실행
flutter test integration_test/app_test.dart -d "iPhone 16 Pro"
```

**예시:**
```dart
// integration_test/edit_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:filmin/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('편집 흐름 통합 테스트', () {
    testWidgets('이미지 선택 → 필터 적용 → 저장', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 1. 갤러리에서 이미지 선택
      final galleryButton = find.byIcon(Icons.photo_library);
      expect(galleryButton, findsOneWidget);
      await tester.tap(galleryButton);
      await tester.pumpAndSettle();

      // 2. 첫 번째 이미지 선택
      final firstImage = find.byType(Image).first;
      await tester.tap(firstImage);
      await tester.pumpAndSettle();

      // 3. 필터 도구 열기
      final filterButton = find.text('필터');
      await tester.tap(filterButton);
      await tester.pumpAndSettle(Duration(seconds: 1));

      // 4. 필터 적용
      final filter = find.text('FUJI_C200_Test');
      if (filter.evaluate().isNotEmpty) {
        await tester.tap(filter);
        await tester.pumpAndSettle();
      }

      // 5. 저장 버튼 클릭
      final saveButton = find.byIcon(Icons.check);
      await tester.tap(saveButton);
      await tester.pumpAndSettle(Duration(seconds: 3));

      // 6. 저장 완료 확인
      expect(find.text('저장 완료'), findsOneWidget);
    });
  });
}
```

---

### 3. **개발자 테스트 페이지** - `lib/examples/`
**목적:** 개발 중 수동으로 기능을 테스트하고 디버깅

**특징:**
- ✅ 실시간 UI 피드백
- ✅ 개발 중 빠른 검증
- ✅ 버튼 클릭으로 테스트 실행
- ❌ 자동화 불가 (수동 테스트)

**실행 방법:**
```bash
flutter run lib/examples/service_test_page.dart
```

**언제 사용하나요?**
- 🔧 개발 중 새로운 기능 추가
- 🐛 버그 재현 및 디버깅
- 🎨 UI 효과 실시간 확인
- 📊 성능 측정

---

## 🎯 테스트 유형 선택 가이드

| 상황 | 사용할 테스트 | 이유 |
|------|---------------|------|
| 새로운 서비스 메서드 추가 | **단위 테스트** | 빠르고, 독립적으로 검증 |
| 이미지 처리 알고리즘 개선 | **개발자 페이지** + **단위 테스트** | 시각적 확인 후 자동화 |
| 전체 편집 흐름 검증 | **통합 테스트** | 실제 사용자 시나리오 |
| 버그 재현 | **개발자 페이지** | 빠른 재현과 디버깅 |
| CI/CD 파이프라인 | **단위 테스트** | 빠른 피드백 |
| 배포 전 최종 검증 | **통합 테스트** | 전체 기능 확인 |

---

## 📝 테스트 코드 작성 규칙

### 1. **파일 명명 규칙**
```
원본 파일: brightness_adjustment_service.dart
테스트 파일: brightness_adjustment_service_test.dart
              ↑ 항상 _test.dart로 끝나야 함
```

### 2. **테스트 구조**
```dart
void main() {
  group('서비스 이름', () {
    late ServiceClass service;

    setUp(() {
      // 각 테스트 전에 실행
      service = ServiceClass();
    });

    tearDown(() {
      // 각 테스트 후에 실행 (정리 작업)
    });

    test('기능 설명', () {
      // 준비 (Arrange)
      final input = ...;

      // 실행 (Act)
      final result = service.method(input);

      // 검증 (Assert)
      expect(result, expectedValue);
    });
  });
}
```

### 3. **테스트 이름 규칙**
```dart
// ✅ 좋은 예
test('밝기 조정이 올바르게 적용되는지 확인', () { ... });
test('null 입력에 대해 예외를 던지는지 확인', () { ... });
test('빈 이미지를 처리할 수 있는지 확인', () { ... });

// ❌ 나쁜 예
test('test1', () { ... });
test('works', () { ... });
test('brightness', () { ... });
```

### 4. **AAA 패턴 사용**
```dart
test('예제 테스트', () {
  // Arrange (준비): 테스트 데이터 준비
  final service = BrightnessAdjustmentService();
  final image = createTestImage();

  // Act (실행): 테스트 대상 실행
  final result = service.applyBrightness(image, 0.5);

  // Assert (검증): 결과 확인
  expect(result.width, 100);
  expect(result.height, 100);
});
```

---

## 🔄 테스트 실행 워크플로우

### 개발 중 (Development)
```bash
1. 코드 작성
2. flutter run lib/examples/service_test_page.dart  # 수동 확인
3. flutter test test/services/my_service_test.dart  # 자동 테스트
4. 코드 수정
5. 반복
```

### 커밋 전 (Before Commit)
```bash
# 모든 단위 테스트 실행
flutter test

# 실패한 테스트가 있으면 수정
# 모두 통과하면 커밋
git commit -m "feat: 새로운 기능 추가"
```

### PR 전 (Before Pull Request)
```bash
# 1. 단위 테스트
flutter test --coverage

# 2. 통합 테스트
flutter test integration_test/

# 3. 모두 통과하면 PR 생성
```

---

## 📊 테스트 커버리지 관리

### 커버리지 측정
```bash
# 커버리지 리포트 생성
flutter test --coverage

# HTML 리포트 생성 (genhtml 필요)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### 목표 커버리지
```
서비스 계층:      80% 이상  (중요한 비즈니스 로직)
위젯 계층:        60% 이상  (UI 로직)
유틸리티 함수:    90% 이상  (순수 함수)
```

---

## 🛠️ 실전 예제: 새로운 서비스 추가 시

### 시나리오: Vignette 효과 서비스 추가

#### 1단계: 서비스 구현
```dart
// lib/features/editview/services/vignette_service.dart
class VignetteService {
  img.Image applyVignette(img.Image image, double intensity) {
    // 비네트 효과 구현
    return image;
  }
}
```

#### 2단계: 개발자 테스트 페이지에 추가
```dart
// lib/examples/service_test_page.dart에 추가
Future<void> _testVignetteService() async {
  final service = VignetteService();
  final testImage = createTestImage();

  final result = service.applyVignette(testImage, 0.7);

  setState(() {
    _testLog += '✅ Vignette 적용 성공\n';
  });
}
```

**실행:**
```bash
flutter run lib/examples/service_test_page.dart
# "Vignette 테스트" 버튼 클릭하여 확인
```

#### 3단계: 단위 테스트 작성
```dart
// test/services/vignette_service_test.dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VignetteService', () {
    late VignetteService service;

    setUp(() {
      service = VignetteService();
    });

    test('비네트 효과가 올바르게 적용되는지 확인', () {
      final testImage = createTestImage(100, 100);

      final result = service.applyVignette(testImage, 0.5);

      expect(result.width, 100);
      expect(result.height, 100);

      // 중앙은 밝고, 가장자리는 어두워야 함
      final centerPixel = result.getPixel(50, 50);
      final edgePixel = result.getPixel(0, 0);

      expect(centerPixel.r, greaterThan(edgePixel.r));
    });

    test('강도가 0일 때 원본 이미지를 반환하는지 확인', () {
      final testImage = createTestImage(100, 100);
      final original = testImage.clone();

      final result = service.applyVignette(testImage, 0.0);

      expect(areImagesEqual(result, original), isTrue);
    });
  });
}
```

**실행:**
```bash
flutter test test/services/vignette_service_test.dart
```

#### 4단계: 통합 테스트 추가
```dart
// integration_test/vignette_flow_test.dart
testWidgets('비네트 효과 적용 흐름 테스트', (tester) async {
  app.main();
  await tester.pumpAndSettle();

  // 이미지 선택 → 효과 도구 → 비네트 선택 → 적용
  // ...
});
```

---

## ⚙️ CI/CD 통합

### GitHub Actions 예시
```yaml
# .github/workflows/test.yml
name: Flutter Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: flutter pub get

      - name: Run unit tests
        run: flutter test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: coverage/lcov.info
```

---

## 📋 체크리스트

### 새로운 기능 추가 시
- [ ] 개발자 테스트 페이지에서 수동 테스트
- [ ] 단위 테스트 작성
- [ ] 모든 테스트 통과 확인 (`flutter test`)
- [ ] 커버리지 80% 이상 확인
- [ ] 통합 테스트 추가 (필요한 경우)

### 버그 수정 시
- [ ] 버그를 재현하는 테스트 작성
- [ ] 테스트가 실패하는지 확인
- [ ] 버그 수정
- [ ] 테스트가 통과하는지 확인

### 리팩토링 시
- [ ] 기존 테스트 모두 통과 확인
- [ ] 리팩토링 실행
- [ ] 테스트 다시 실행하여 통과 확인
- [ ] 커버리지 유지/향상 확인

---

## 🎓 베스트 프랙티스

### 1. **테스트는 독립적이어야 함**
```dart
// ❌ 나쁜 예: 전역 변수 사용
var globalService = BrightnessService();

test('테스트1', () {
  globalService.setState(...);
});

test('테스트2', () {
  // 테스트1의 영향을 받음!
});

// ✅ 좋은 예: 각 테스트마다 새로운 인스턴스
setUp(() {
  service = BrightnessService();
});
```

### 2. **테스트는 빨라야 함**
```dart
// ❌ 나쁜 예: 실제 파일 I/O
test('이미지 로드 테스트', () async {
  final image = await loadFromFile('assets/test.jpg');
});

// ✅ 좋은 예: 메모리에서 생성
test('이미지 로드 테스트', () {
  final image = createTestImage(100, 100);
});
```

### 3. **테스트는 명확해야 함**
```dart
// ❌ 나쁜 예
test('works', () {
  expect(result, isNotNull);
});

// ✅ 좋은 예
test('밝기 조정 후 픽셀 값이 변경되어야 함', () {
  final before = image.getPixel(50, 50).r;
  service.applyBrightness(image, 0.5);
  final after = image.getPixel(50, 50).r;

  expect(after, isNot(before));
});
```

---

## 🔗 추가 자료

- [Flutter Testing 공식 문서](https://docs.flutter.dev/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

---

## 📞 도움이 필요하면?

```bash
# 테스트 관련 명령어 도움말
flutter test --help

# 예제 페이지 실행
flutter run lib/examples/service_test_page.dart
```

**Happy Testing! 🎉**
