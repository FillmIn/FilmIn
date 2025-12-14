# FilmIn (필름인)

> 아날로그 필름의 감성을 디지털 사진에 담다

<div align="center">
  <img src="assets/icon/filmInLogo.jpeg" alt="FilmIn Logo" width="120" style="border-radius: 20px">
</div>

<br>

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](#-버전-히스토리)
[![Flutter](https://img.shields.io/badge/Flutter-3.9.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FilmIn**은 아날로그 필름 카메라의 감성을 모바일 환경에서 재현하는 이미지 편집 애플리케이션입니다. 실제 필름의 그레인, 먼지 효과와 전문가급 LUT 기반 색보정 기능을 통해 디지털 사진을 빈티지 필름 사진으로 변환합니다.

<br>

## 🎬 데모

<div align="center">
  <img src="assets/gif/demo.gif" alt="FilmIn Demo" width="280">
</div>

<br>

---

## ✨ 구현된 기능

### 🎞️ 필름 효과 시스템

#### Grain (그레인)

실제 필름 입자감을 재현한 그레인 효과

- **Fuji Reala** - 섬세하고 부드러운 그레인
- **Fuji Pro 400H** - 중간 톤의 자연스러운 입자
- **Fuji Superia** - 선명한 입자감

#### Dust (더스트)

빈티지 필름의 먼지와 스크래치 효과

- **Vintage Dust 1-3** - 다양한 먼지/스크래치 패턴
- 자연스러운 오버레이 블렌딩

<br>

### 🎨 LUT 필터 시스템

- **3D LUT(Look-Up Table)** 기반 전문가급 색보정
- **33개 이상의 커스텀 필터** 프리셋
- CUBE 포맷 지원
- 실시간 프리뷰 및 강도 조절 (0-100%)

<br>

### 🔆 밝기 & 색상 조정

10종의 전문가급 조정 도구:

| 기능 | 설명 |
|------|------|
| **Exposure** | 전체 노출 조절 |
| **Contrast** | 명암 대비 |
| **Highlights** | 밝은 영역 복구 |
| **Shadows** | 어두운 영역 보정 |
| **Whites** | 화이트 포인트 |
| **Blacks** | 블랙 포인트 |
| **Saturation** | 채도 조절 |
| **Warmth** | 색온도 (Warm ↔ Cool) |
| **Sharpness** | 선명도 |
| **Noise Reduction** | 노이즈 감소 |

<br>

### ✂️ 크롭 기능

다양한 비율 프리셋 지원:

- **Original** - 원본 비율
- **1:1** - 정사각형
- **4:5** - Instagram 세로
- **3:4** - 클래식 사진
- **9:16** - 세로 동영상
- **16:9** - 가로 동영상
- **Freeform** - 자유 형식

<br>

### 💾 저장 & 내보내기

- 고품질 이미지 저장 (JPEG/PNG)
- 갤러리 자동 저장
- 편집 전/후 실시간 비교 기능

<br>

---

## 🏗️ 기술 스택

### Core Framework

| 기술 | 버전 | 용도 |
|------|------|------|
| Flutter | 3.9.0 | 크로스플랫폼 UI |
| Dart | 3.9.0 | 프로그래밍 언어 |

### 상태 관리 & 라우팅

| 패키지 | 버전 | 용도 |
|--------|------|------|
| flutter_riverpod | 2.6.1 | 반응형 상태 관리 |
| go_router | 16.2.1 | 선언적 라우팅 |

### 이미지 처리

| 패키지 | 버전 | 용도 |
|--------|------|------|
| image | 4.2.0 | 픽셀 단위 이미지 처리 |
| image_picker | 1.1.2 | 갤러리/카메라 접근 |
| cached_network_image | 3.3.1 | 이미지 캐싱 |
| image_gallery_saver | 2.0.3 | 갤러리 저장 |

### 백엔드 & 저장소

| 패키지 | 버전 | 용도 |
|--------|------|------|
| firebase_core | 2.30.1 | Firebase 통합 |
| firebase_storage | 11.6.9 | 클라우드 이미지 저장소 |
| shared_preferences | 2.2.2 | 로컬 설정 저장 |

### UI/UX

| 패키지 | 버전 | 용도 |
|--------|------|------|
| flutter_svg | 2.0.10 | SVG 아이콘 지원 |
| permission_handler | 11.3.1 | 권한 관리 |

<br>

---

## 📁 프로젝트 구조

```
lib/
├── main.dart                   # 앱 진입점
├── firebase_options.dart       # Firebase 설정
├── app/
│   └── di/                     # 의존성 주입
│
└── features/
    ├── splash/                 # 스플래시 화면
    ├── onboarding/             # 온보딩 & 이미지 그리드
    │   ├── models/             # 데이터 모델
    │   ├── network/            # 네트워크 레이어
    │   ├── services/           # 비즈니스 로직
    │   └── widgets/            # UI 컴포넌트
    │
    ├── gallery/                # 갤러리 선택
    │
    ├── editview/               # 🎯 핵심 편집 기능
    │   ├── services/
    │   │   ├── brightness_service.dart      # 밝기/색상 처리
    │   │   ├── film_effects_service.dart    # 필름 효과 엔진
    │   │   ├── lut_filter_service.dart      # LUT 필터 엔진
    │   │   ├── image_crop_service.dart      # 크롭 처리
    │   │   ├── image_processing_service.dart # 통합 이미지 처리
    │   │   ├── image_save_service.dart      # 저장 서비스
    │   │   └── texture_cache.dart           # 텍스처 캐싱
    │   │
    │   ├── widgets/
    │   │   ├── brightness/     # 밝기 조정 UI
    │   │   ├── filter/         # 필터 선택 UI
    │   │   ├── effect/         # 효과 선택 UI
    │   │   └── crop/           # 크롭 UI
    │   │
    │   ├── state/              # 에디터 상태 관리
    │   ├── ui/                 # 레이아웃 컴포넌트
    │   └── viewer_page.dart    # 메인 에디터 화면
    │
    └── export/                 # 이미지 내보내기

assets/
├── filters/
│   ├── lut/                    # LUT 파일 (.CUBE)
│   └── new_filters_33/         # 33개 커스텀 필터
│
├── effects/
│   ├── grain/                  # 그레인 텍스처
│   └── dust/                   # 더스트 텍스처
│
├── svg/
│   ├── light/                  # 라이트 모드 아이콘
│   └── dark/                   # 다크 모드 아이콘
│
├── icon/                       # 앱 로고 & 아이콘
├── images/                     # 배너 이미지
└── gif/                        # 데모 GIF
```

<br>

---

## 📱 지원 플랫폼

| 플랫폼 | 상태 | 최소 버전 |
|--------|------|---------|
| iOS | ✅ 지원 | iOS 12.0+ |
| Android | ✅ 지원 | API 21+ (Android 5.0) |
| Web | 🔄 개발 예정 | - |

<br>

---

## 📝 버전 히스토리

### v1.0.0 (2024.10.28) - 데모 앱 출시

**핵심 기능**

- ✅ Grain 효과 (Fuji Reala, Pro 400H, Superia)
- ✅ Dust 효과 (Vintage 1-3)
- ✅ LUT 기반 필터 시스템 (33개 필터)
- ✅ 10종 밝기/색상 조정 도구
- ✅ 다양한 크롭 비율 지원
- ✅ 실시간 Before/After 비교

**기술 하이라이트**

- Isolate 기반 비동기 이미지 처리 최적화
- 픽셀 단위 커스텀 블렌드 모드 구현
- 텍스처 캐싱을 통한 메모리 최적화
- Firebase Storage 연동

<br>

### 향후 로드맵

- [ ] 추가 필름 효과 (Halation 등)
- [ ] 배치 편집 기능
- [ ] AI 기반 자동 보정
- [ ] 웹 버전 지원

<br>

---

## 📄 라이선스

MIT License - [LICENSE](LICENSE) 파일 참조

<br>

---

<p align="center">
  <strong>Made with ❤️ by FilmIn Team</strong>
  <br>
  <em>아날로그 필름의 감성을 디지털로</em>
</p>
