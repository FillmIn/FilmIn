import 'package:flutter/material.dart';
import '../widgets/editor_app_bar.dart';
import '../widgets/image_preview_widget.dart';
import '../widgets/editor_toolbar.dart';
import '../widgets/brightness/brightness_tool.dart';
import '../widgets/effect/effect_tool.dart';
import '../widgets/filter/filter_tool.dart';
import '../widgets/crop/crop_tool.dart';
import '../widgets/processing_overlay.dart';
import '../services/lut_filter_service.dart';

/// ViewerPage의 UI를 빌드하는 유틸리티 클래스
///
/// 역할: 복잡한 UI 빌딩 로직을 별도 메서드로 분리하여 가독성 향상
class ViewerUIBuilder {
  /// 에디터 앱바 빌드
  static PreferredSizeWidget buildAppBar({
    required VoidCallback onCompareStart,
    required VoidCallback onCompareEnd,
    required VoidCallback onSave,
    required VoidCallback onUndo,
    required VoidCallback onBack,
    required bool canUndo,
  }) {
    return EditorAppBar(
      onCompareStart: onCompareStart,
      onCompareEnd: onCompareEnd,
      onSave: onSave,
      onUndo: onUndo,
      onBack: onBack,
      canUndo: canUndo,
    );
  }

  /// 이미지 프리뷰 영역 빌드
  static Widget buildImagePreview({
    required String? imagePath,
    required int rotation,
    required bool flipH,
    required double brightness,
    required BrightnessAdjustments brightnessAdjustments,
    required FilmEffects filmEffects,
    required String? filter,
    required double filterIntensity,
    required CropPreset crop,
    required bool showOriginal,
    required bool isFiltersInitialized,
    required LutFilterService? lutService,
    required EditorTool selectedTool,
  }) {
    return ImagePreviewWidget(
      imagePath: imagePath,
      rotation: rotation,
      flipH: flipH,
      brightness: brightness,
      brightnessAdjustments: brightnessAdjustments,
      filmEffects: filmEffects,
      filter: filter,
      filterIntensity: filterIntensity,
      crop: selectedTool == EditorTool.crop ? CropPreset.original : crop,
      showOriginal: showOriginal,
      isFiltersInitialized: isFiltersInitialized,
      lutService: lutService,
    );
  }

  /// 크롭 오버레이 빌드
  static Widget? buildCropOverlay({
    required EditorTool selectedTool,
    required CropPreset crop,
    required Offset cropOffset,
    required double cropScale,
    required Rect? freeformCropRect,
    required String? imagePath,
    required double? imageAspectRatio,
    required Function(Offset, double) onCropChanged,
    required Function(Rect) onFreeformCropChanged,
  }) {
    if (selectedTool == EditorTool.crop && crop != CropPreset.original) {
      return CropOverlay(
        preset: crop,
        initialOffset: cropOffset,
        initialScale: cropScale,
        initialFreeformRect: freeformCropRect,
        imagePath: imagePath,
        imageAspectRatio: imageAspectRatio,
        onCropChanged: onCropChanged,
        onFreeformCropChanged: onFreeformCropChanged,
      );
    }
    return null;
  }

  /// 필터 이름 태그 빌드
  static Widget? buildFilterTag({
    required String? filter,
    required bool isDark,
  }) {
    if (filter != null) {
      return Positioned(
        top: 20,
        right: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            '필터: $filter',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return null;
  }

  /// 에디터 툴바 빌드
  static Widget buildToolbar({
    required EditorTool selectedTool,
    required ValueChanged<EditorTool> onToolSelected,
  }) {
    return EditorToolbar(
      selectedTool: selectedTool,
      onToolSelected: onToolSelected,
    );
  }

  /// 로딩 오버레이 빌드
  static Widget? buildLoadingOverlay({
    required bool isSaving,
  }) {
    if (isSaving) {
      return const AnimatedProcessingOverlay(
        messageSteps: [
          '이미지 처리 중...',
          '필터 적용 중...',
          '품질 최적화 중...',
          '거의 완료되었습니다...',
        ],
      );
    }
    return null;
  }

  /// 도구 패널 빌드 (Brightness, Effect, Filter, Crop)
  static Widget buildToolPanel({
    required EditorTool selectedTool,
    required BuildContext context,
    // Brightness 파라미터
    BrightnessAdjustments? brightnessAdjustments,
    bool? isProcessing,
    ValueChanged<BrightnessAdjustments>? onBrightnessChanged,
    VoidCallback? onBrightnessAutoAdjust,
    VoidCallback? onBrightnessCancel,
    VoidCallback? onBrightnessApply,
    // Effect 파라미터
    FilmEffects? filmEffects,
    ValueChanged<FilmEffects>? onEffectChanged,
    VoidCallback? onEffectCancel,
    VoidCallback? onEffectApply,
    // Filter 파라미터
    String? selectedFilter,
    String? imagePath,
    double? filterIntensity,
    ValueChanged<String?>? onFilterChanged,
    ValueChanged<double>? onFilterIntensityChanged,
    VoidCallback? onFilterCancel,
    VoidCallback? onFilterApply,
    // Crop 파라미터
    CropPreset? selectedCrop,
    ValueChanged<CropPreset>? onCropChanged,
    VoidCallback? onCropCancel,
    Future<void> Function()? onCropApply,
  }) {
    Widget panel;
    switch (selectedTool) {
      case EditorTool.brightness:
        panel = BrightnessToolPanel(
          adjustments: brightnessAdjustments ?? const BrightnessAdjustments(),
          isProcessing: isProcessing ?? false,
          onChanged: onBrightnessChanged ?? (_) {},
          onAutoAdjust: onBrightnessAutoAdjust ?? () {},
          onCancel: onBrightnessCancel ?? () {},
          onApply: onBrightnessApply ?? () {},
        );
        break;

      case EditorTool.effect:
        panel = EffectToolPanel(
          effects: filmEffects ?? const FilmEffects(),
          onChanged: onEffectChanged ?? (_) {},
          onCancel: onEffectCancel,
          onApply: onEffectApply,
        );
        break;

      case EditorTool.filter:
        panel = FilterToolPanel(
          selectedFilter: selectedFilter,
          imagePath: imagePath,
          filterIntensity: filterIntensity ?? 1.0,
          onChanged: onFilterChanged ?? (_) {},
          onIntensityChanged: onFilterIntensityChanged,
          onCancel: onFilterCancel,
          onApply: onFilterApply,
        );
        break;

      case EditorTool.crop:
        panel = CropToolPanel(
          selectedCrop: selectedCrop ?? CropPreset.original,
          onCropChanged: onCropChanged ?? (_) {},
          onCancel: onCropCancel ?? () {},
          onApply: onCropApply ?? () async {},
        );
        break;

      case EditorTool.none:
        panel = const SizedBox.shrink();
        break;
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: panel,
      ),
    );
  }
}
