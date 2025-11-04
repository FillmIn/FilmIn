import 'package:flutter/material.dart';
import '../widgets/brightness/brightness_tool.dart';
import '../widgets/effect/effect_tool.dart';
import '../widgets/crop/crop_tool.dart';
import '../widgets/editor_toolbar.dart';
import '../services/lut_filter_service.dart';
import '../services/image_processing_service.dart';
import '../services/image_save_service.dart';

/// ViewerPage의 상태를 관리하는 클래스
///
/// 역할: 편집기의 모든 상태 변수와 서비스 인스턴스를 보관합니다.
class ViewerState {
  // 서비스
  final ImageProcessingService processingService = ImageProcessingService();
  final ImageSaveService saveService = ImageSaveService();

  // 이미지 기본 상태
  String? imagePath;
  final int rotation = 0;
  final bool flipH = false;
  double brightness = 0.0;
  BrightnessAdjustments brightnessAdjustments = const BrightnessAdjustments();

  // 편집 도구 상태
  EditorTool selectedTool = EditorTool.none;
  FilmEffects filmEffects = const FilmEffects();
  String? filter;
  double filterIntensity = 1.0;
  CropPreset crop = CropPreset.original;
  bool showOriginal = false;

  // 크롭 조정 정보
  Offset cropOffset = Offset.zero;
  double cropScale = 1.0;
  Size screenSize = Size.zero;
  Rect? freeformCropRect;
  double? imageAspectRatio;

  // 편집 히스토리
  final List<String> imageHistory = [];
  int currentHistoryIndex = -1;

  // LUT 필터 서비스
  LutFilterService? lutService;
  bool isFiltersInitialized = false;
  bool isSaving = false;

  ViewerState({required String? initialImagePath}) {
    imagePath = initialImagePath;
    if (imagePath != null) {
      imageHistory.add(imagePath!);
      currentHistoryIndex = 0;
    }
  }

  /// 상태 초기화 (뒤로가기 등에서 사용)
  void reset() {
    selectedTool = EditorTool.none;
    filter = null;
    crop = CropPreset.original;
    cropOffset = Offset.zero;
    cropScale = 1.0;
    freeformCropRect = null;
  }

  /// 히스토리에 새 이미지 추가
  void addToHistory(String path) {
    // 현재 인덱스 이후의 히스토리 제거
    if (currentHistoryIndex < imageHistory.length - 1) {
      imageHistory.removeRange(currentHistoryIndex + 1, imageHistory.length);
    }
    imageHistory.add(path);
    currentHistoryIndex++;
    imagePath = path;
  }

  /// 실행 취소
  bool canUndo() => currentHistoryIndex > 0;

  void undo() {
    if (canUndo()) {
      currentHistoryIndex--;
      imagePath = imageHistory[currentHistoryIndex];
    }
  }

  /// 현재 편집 상태를 디버그 문자열로 변환
  String toDebugString() {
    return '''
ViewerState:
  - Image: $imagePath
  - Tool: $selectedTool
  - Filter: $filter (intensity: $filterIntensity)
  - Crop: $crop (offset: $cropOffset, scale: $cropScale)
  - History: ${currentHistoryIndex + 1}/${imageHistory.length}
  - Saving: $isSaving
    ''';
  }
}
