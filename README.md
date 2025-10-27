# FilmIn (필름인)

> 아날로그 필름의 감성을 디지털 사진에 담다

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](README.md#-버전-히스토리)
[![Flutter](https://img.shields.io/badge/Flutter-3.9.0-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.0-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**FilmIn**은 아날로그 필름 카메라의 감성을 모바일 환경에서 재현하는 이미지 편집 애플리케이션입니다. 실제 필름의 그레인, 먼지, 할레이션 효과와 전문가급 색보정 기능을 통해 당신의 디지털 사진을 빈티지 필름 사진으로 변환합니다.

<br>

## 📅 개발 현황

### 현재 버전: `v1.0.0` (2024.10.28)
> 데모 앱 제작 완료 - 핵심 필름 편집 기능 구현

<br>

## 🎬 데모영상

<div align="center">
  <img src="assets/gif/demo.gif" alt="FilmIn Demo" width="300">
</div>

<br>

## ✨ 주요 기능

### 🎞️ 필름 효과

#### 1. Grain (그레인)
실제 필름의 입자감을 재현한 그레인 효과
- **Fuji Reala**: 섬세하고 부드러운 그레인
- **Fuji Pro 400H**: 중간 톤의 자연스러운 입자
- **Fuji Superia**: 선명한 입자감

#### 2. Dust (더스트)
빈티지 필름의 먼지와 스크래치 효과
- **Vintage Dust 1-3**: 다양한 먼지/스크래치 패턴
- 자연스러운 오버레이 블렌딩

#### 3. Halation (할레이션)
영화 필름의 특징적인 붉은 빛 번짐 효과
- **하이브리드 알고리즘**: 밝은 영역 자동 감지 + 텍스처 오버레이
- **Cinematic**: 영화적 붉은 할레이션
- **Vintage**: 클래식 필름 느낌
- **Warm**: 따뜻한 주황색 톤
- Screen 블렌드 모드로 자연스러운 빛 번짐 구현

### 🎨 전문가급 색보정

#### LUT 기반 필터 시스템
- 3D LUT(Look-Up Table) 기반 색보정
- CUBE 포맷 지원
- 실시간 프리뷰
- 강도 조절 가능 (0-100%)

#### 고급 밝기 조정
- **Exposure**: 전체 노출 조절
- **Contrast**: 명암 대비
- **Highlights**: 밝은 영역 복구
- **Shadows**: 어두운 영역 보정
- **Whites & Blacks**: 화이트/블랙 포인트 조정
- **Saturation**: 채도 조절
- **Warmth**: 색온도 조정 (Warm ↔ Cool)
- **Sharpness**: 선명도
- **Noise Reduction**: 노이즈 감소

### ✂️ 크롭 & 변형

다양한 비율의 크롭 프리셋 지원:
- **Original**: 원본 비율
- **Square (1:1)**: 정사각형
- **4:5**: Instagram 세로
- **3:4**: 클래식 사진
- **9:16**: 세로 동영상
- **16:9**: 가로 동영상
- **Freeform**: 자유 형식

### 💾 저장 & 공유

- 고품질 이미지 저장 (JPEG/PNG)
- 갤러리 자동 저장
- 무손실 편집 워크플로우
- 편집 전/후 비교 기능

<br>



## 🎨 사용 예시

### 기본 워크플로우
1. **메인 이미지 그리드** : 필터 적용된 이미지 미리보기
1. **이미지 선택**: 온보딩 화면에서 Firebase Storage 이미지 또는 갤러리에서 선택
2. **필터 적용**: 하단 툴바에서 "필터" 선택 → LUT 필터 적용
3. **밝기 조정**: "밝기" 탭에서 세부 조정
4. **효과 추가**: "효과" 탭에서 Grain, Dust, Halation 적용
5. **크롭**: 필요시 원하는 비율로 크롭
6. **저장**: 우측 상단 체크 버튼으로 저장


## 📱 지원 플랫폼

- ✅ iOS 12.0+
- ✅ Android 5.0+ (API 21+)
- 🔄 웹 (개발 중)

<br>

## 🏗️ 기술 스택

### Framework & Language
- **Flutter 3.9.0**: 크로스플랫폼 UI 프레임워크
- **Dart 3.9.0**: 프로그래밍 언어

### 상태 관리
- **flutter_riverpod 2.6.1**: 반응형 상태 관리

### 이미지 처리
- **image 4.2.0**: 픽셀 단위 이미지 처리
- **image_picker 1.1.2**: 갤러리/카메라 접근
- **cached_network_image 3.3.1**: 이미지 캐싱

### UI/UX
- **go_router 16.2.1**: 선언적 라우팅
- **flutter_svg 2.0.10**: SVG 지원
- 다크/라이트 테마 지원

### 백엔드 & 저장소
- **Firebase Core 2.30.1**: Firebase 통합
- **Firebase Storage 11.6.9**: 클라우드 이미지 저장소
- **image_gallery_saver 2.0.3**: 로컬 갤러리 저장

### 기타
- **permission_handler 11.3.1**: 권한 관리
- **path_provider 2.1.4**: 파일 시스템 접근

<br>

## 📁 프로젝트 구조

```
lib/
├── app/
│   └── di/                  # 의존성 주입
├── features/
│   ├── splash/             # 스플래시 화면
│   ├── onboarding/         # 온보딩 & Firebase 이미지 그리드
│   ├── gallery/            # 갤러리 선택
│   ├── editview/           # 이미지 편집 (핵심 기능)
│   │   ├── services/       # 이미지 처리 서비스
│   │   ├── widgets/
│   │   │   ├── brightness/ # 밝기 조정 UI
│   │   │   ├── filter/     # 필터 UI
│   │   │   ├── effect/     # 효과 UI (Grain, Dust, Halation)
│   │   │   └── crop/       # 크롭 UI
│   │   └── viewer_page.dart
│   └── export/             # 이미지 저장
└── services/
    └── filters/
        └── lut/            # LUT 필터 엔진

assets/
├── filters/
│   └── lut/                # LUT 파일 (.CUBE)
├── effects/
│   ├── grain/              # 그레인 텍스처
│   ├── dust/               # 더스트 텍스처
│   └── halation/           # 할레이션 텍스처
└── icon/                   # 앱 아이콘 & 로고
```
<br>

## 📝 버전 히스토리

### v1.0.0 (2024.10.28) - 데모 앱 출시
**주요 기능**
- ✅ 필름 효과 시스템 구현
  - Grain 효과 (Fuji Reala, Pro 400H, Superia)
  - Dust 효과 (Vintage 1-3)
  - Halation 효과 (Cinematic, Vintage, Warm) - 하이브리드 알고리즘
- ✅ LUT 기반 필터 시스템
- ✅ 고급 밝기 조정 (10종)
- ✅ 다양한 크롭 비율 지원
- ✅ Firebase Storage 통합
- ✅ 다크/라이트 테마
- ✅ 실시간 프리뷰 및 Before/After 비교

**기술 구현**
- Flutter 3.9.0 기반 크로스플랫폼 개발
- Riverpod 상태 관리
- Isolate 기반 이미지 처리 최적화
- 픽셀 단위 커스텀 블렌드 모드 구현

---

### 향후 업데이트 예정
- [ ] v1.1.0 - 추가 필터 및 효과
- [ ] v1.2.0 - 배치 편집 기능
- [ ] v2.0.0 - AI 기반 자동 보정

<br>

<!--
버전 업데이트 템플릿

### vX.X.X (YYYY.MM.DD) - 업데이트 제목
**새로운 기능**
- ✅ 기능 설명

**개선 사항**
- 🔧 개선 내용

**버그 수정**
- 🐛 수정 내용

**기술 변경사항**
- 📦 기술 스택 업데이트
-->

<br>

## 📄 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

<br>

## 👥 기여

기여는 언제나 환영합니다! 다음 단계를 따라주세요:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<br>

## 📞 연락처

프로젝트 링크: [https://github.com/your-username/FilmIn_](https://github.com/your-username/FilmIn_)

<br>

## 🙏 감사의 글

- **밍구필름**: Colorgrader
- **Adobe**: LUT 포맷 표준
- **Flutter Community**: 오픈소스 패키지 제공

<br>

---

<p align="center">Made with ❤️ by FilmIn Team</p>
<p align="center">아날로그 필름의 감성을 디지털로</p>
