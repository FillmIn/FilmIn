# 📚 Examples - 테스트 및 예제 페이지

이 디렉토리는 개발 중 서비스와 기능을 테스트하기 위한 예제 페이지를 포함합니다.

## 📂 파일 구조

### 1. `service_test_page.dart` - 서비스 통합 테스트 페이지
모든 이미지 처리 서비스를 통합 테스트할 수 있는 페이지입니다.

**테스트하는 서비스:**
- ✅ `BrightnessAdjustmentService` - 밝기 조정 (Exposure, Contrast, Saturation, Warmth, Highlights, Shadows, Whites, Blacks)
- ✅ `FilmEffectsService` - 필름 효과 (Grain, Dust, Halation)
- ✅ `LutFilterService` - LUT 필터

**실행 방법:**
```dart
// lib/examples/service_test_page.dart의 main() 함수 실행
flutter run lib/examples/service_test_page.dart
```

**기능:**
- 각 서비스를 개별적으로 테스트
- 전체 서비스 통합 테스트
- 실시간 로그 출력
- 테스트 결과 확인

---

### 2. `filter_example_page.dart` - LUT 필터 미리보기 페이지
LUT 필터를 실시간으로 미리보고 테스트할 수 있는 페이지입니다.

**기능:**
- LUT 필터 실시간 미리보기
- 필터 강도 조절 (0% ~ 100%)
- 필터 정보 표시 (LUT 크기, 엔트리 수)
- FilterToolPanel UI 테스트

**실행 방법:**
```dart
flutter run lib/examples/filter_example_page.dart
```

---

## 🎯 테스트 코드를 사용해야 하는 이유

### 1. **버그 조기 발견** 🐛
서비스를 수정할 때마다 전체 앱을 실행하지 않고, 해당 서비스만 빠르게 테스트할 수 있습니다.

**예시:**
```dart
// BrightnessAdjustmentService를 수정한 후
// service_test_page.dart에서 "밝기 조정" 버튼만 클릭하여
// 5초 안에 테스트 완료 ✅
```

---

### 2. **개발 속도 향상** ⚡
실제 앱에서 테스트하려면:
1. 앱 실행 (30초)
2. 갤러리에서 이미지 선택 (10초)
3. 편집 화면 진입 (5초)
4. 원하는 기능 테스트 (10초)
**= 총 55초**

테스트 페이지를 사용하면:
1. 테스트 페이지 실행 (5초)
2. 버튼 클릭 (1초)
**= 총 6초** ⚡⚡⚡

---

### 3. **서비스 독립성 확인** 🔍
각 서비스가 독립적으로 동작하는지 확인할 수 있습니다.

**예시:**
```dart
// ❌ 잘못된 구조: 서비스가 서로 의존
class BrightnessService {
  FilmEffectsService filmService; // 의존성!
}

// ✅ 올바른 구조: 서비스가 독립적
class BrightnessService {
  // 다른 서비스에 의존하지 않음
}
```

테스트 페이지에서 각 서비스를 개별적으로 실행해보면, 의존성 문제를 즉시 발견할 수 있습니다.

---

### 4. **리팩토링 안정성** 🛡️
코드를 리팩토링할 때 기존 기능이 깨지지 않았는지 확인할 수 있습니다.

**시나리오:**
```dart
// 기존 코드
class BrightnessAdjustmentService {
  void applyBrightness(Image img, double value) {
    // ... 100줄의 코드
  }
}

// 리팩토링 후
class BrightnessAdjustmentService {
  void applyBrightness(Image img, double value) {
    // ... 50줄로 줄임
  }
}
```

테스트 페이지에서 "밝기 조정" 테스트를 실행하여, 리팩토링 후에도 동일하게 동작하는지 확인 ✅

---

### 5. **새로운 기능 추가 시 검증** ✨
새로운 효과나 필터를 추가할 때, 기존 기능에 영향을 주지 않는지 확인할 수 있습니다.

**예시:**
```dart
// 새로운 효과 추가: Vignette (비네트)
class FilmEffectsService {
  Image applyVignette(Image img, double intensity) {
    // 새로운 효과 구현
  }
}
```

테스트 페이지에서:
1. 기존 Grain, Dust, Halation 테스트 → 정상 작동 확인 ✅
2. 새로운 Vignette 테스트 추가 → 새 기능 검증 ✅

---

### 6. **디버깅 효율성** 🔧
문제가 발생했을 때, 어느 서비스에서 문제가 생겼는지 빠르게 찾을 수 있습니다.

**로그 예시:**
```
📝 밝기 조정 서비스 테스트
─────────────────────────
✅ Exposure 조정: 0.5
✅ Contrast 조정: 0.3
❌ Saturation 조정 실패: RangeError
```

즉시 "Saturation 조정" 부분에 문제가 있다는 것을 알 수 있습니다!

---

### 7. **팀 협업 시 커뮤니케이션** 👥
다른 개발자에게 "이 서비스 어떻게 사용하나요?"라고 물어볼 필요 없이, 예제 코드를 보면 됩니다.

**예시:**
```dart
// filter_example_page.dart를 보고
// "아, LutFilterService는 이렇게 사용하는구나!"
final colorFilter = _lutService!.createLutColorFilter(
  filterName,
  intensity: 0.8,
);
```

---

### 8. **성능 측정** ⏱️
각 서비스의 성능을 측정하고 비교할 수 있습니다.

**예시:**
```dart
final stopwatch = Stopwatch()..start();
await _filmEffectsService.applyGrainEffect(...);
stopwatch.stop();
print('Grain 효과 처리 시간: ${stopwatch.elapsedMilliseconds}ms');
```

---

### 9. **회귀 테스트** 🔄
업데이트 후 이전 버전과 동일하게 동작하는지 확인할 수 있습니다.

**시나리오:**
- v1.0: Halation 효과 강도 0.7로 테스트 → 결과 이미지 저장
- v1.1: 코드 최적화
- 테스트: 동일한 입력으로 테스트 → 결과 이미지 비교 ✅

---

### 10. **문서화 역할** 📖
테스트 코드 자체가 "이 서비스를 어떻게 사용하는지"를 보여주는 살아있는 문서가 됩니다.

**예시:**
```dart
// service_test_page.dart를 보면
// BrightnessAdjustmentService 사용법을 바로 알 수 있음
final result = _brightnessService.applyBrightnessAdjustments(
  image,
  0.2,  // 기본 밝기
  BrightnessAdjustments(
    exposure: 0.5,
    contrast: 0.3,
    // ...
  ),
);
```

---

## 🚀 사용 시나리오

### 시나리오 1: 새로운 필터 추가
```bash
1. assets/filters/에 새로운 LUT 파일 추가
2. lut_filter_service.dart에 필터 로드 코드 추가
3. flutter run lib/examples/filter_example_page.dart 실행
4. 새 필터 선택하여 미리보기 확인 ✅
```

### 시나리오 2: 밝기 조정 알고리즘 개선
```bash
1. brightness_adjustment_service.dart 수정
2. flutter run lib/examples/service_test_page.dart 실행
3. "밝기 조정" 버튼 클릭
4. 로그에서 결과 확인 ✅
```

### 시나리오 3: 버그 리포트 재현
```bash
1. 사용자: "Halation 효과가 너무 강해요"
2. service_test_page.dart에서 Halation 테스트 실행
3. 강도 조절하여 최적값 찾기
4. 코드 수정 후 재테스트 ✅
```

---

## 💡 베스트 프랙티스

### 1. 테스트는 자주 실행하기
```dart
// 서비스 수정 후 즉시 테스트
void fix_brightness_bug() {
  // 코드 수정
  // 👇 바로 테스트!
  // flutter run lib/examples/service_test_page.dart
}
```

### 2. 새로운 기능 추가 시 테스트 코드도 함께 작성
```dart
// FilmEffectsService에 Vignette 추가
class FilmEffectsService {
  Image applyVignette(...) { ... }
}

// 👇 service_test_page.dart에도 테스트 추가
Future<void> _testVignetteEffect() async {
  // ...
}
```

### 3. 실패 로그는 자세하게 작성
```dart
try {
  final result = await service.process();
} catch (e, stackTrace) {
  _testLog += '❌ 테스트 실패\n';
  _testLog += '   에러: $e\n';
  _testLog += '   스택: $stackTrace\n'; // 디버깅에 유용!
}
```

---

## 🎓 결론

테스트 코드는 개발 시간을 단축하고, 버그를 줄이며, 코드 품질을 향상시킵니다.

**투자 대비 효과:**
- 테스트 코드 작성 시간: 1시간
- 절약되는 디버깅 시간: 10시간+
- **ROI: 1000%** 🚀

**지금 바로 사용해보세요!**
```bash
flutter run lib/examples/service_test_page.dart
```
