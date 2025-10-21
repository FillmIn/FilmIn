import 'package:flutter/material.dart';
import 'widgets/brightness/brightness_tool.dart';
import 'widgets/effect/effect_tool.dart';
import 'widgets/crop/crop_tool.dart';
import 'widgets/editor_toolbar.dart';
import 'package:filmin/services/filters/lut/lut_filter_service.dart';

/// 에디터 상태 관리 클래스
class ViewerState extends ChangeNotifier {
  String? _imagePath;
  final int rotation = 0;
  final bool flipH = false;
  double brightness = 0.0;
  BrightnessAdjustments brightnessAdjustments = const BrightnessAdjustments();

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

  LutFilterService? lutService;
  bool isFiltersInitialized = false;
  bool isSaving = false;

  String? get imagePath => _imagePath;

  ViewerState(String? initialPath) {
    _imagePath = initialPath;
    if (_imagePath != null) {
      imageHistory.add(_imagePath!);
      currentHistoryIndex = 0;
    }
  }

  void setImagePath(String path) {
    _imagePath = path;
    notifyListeners();
  }

  void setSelectedTool(EditorTool tool) {
    selectedTool = tool;
    notifyListeners();
  }

  void setShowOriginal(bool value) {
    showOriginal = value;
    notifyListeners();
  }

  void setBrightnessAdjustments(BrightnessAdjustments adjustments) {
    brightnessAdjustments = adjustments;
    notifyListeners();
  }

  void setFilmEffects(FilmEffects effects) {
    filmEffects = effects;
    notifyListeners();
  }

  void setFilter(String? filterName) {
    filter = filterName;
    notifyListeners();
  }

  void setFilterIntensity(double intensity) {
    filterIntensity = intensity;
    notifyListeners();
  }

  void setCrop(CropPreset preset) {
    crop = preset;
    cropOffset = Offset.zero;
    cropScale = 1.0;
    if (preset == CropPreset.freeform) {
      freeformCropRect = Rect.zero;
    } else {
      freeformCropRect = null;
    }
    notifyListeners();
  }

  void setCropTransform(Offset offset, double scale) {
    cropOffset = offset;
    cropScale = scale;
  }

  void setFreeformCropRect(Rect? rect) {
    freeformCropRect = rect;
  }

  void setScreenSize(Size size) {
    if (screenSize != size) {
      screenSize = size;
    }
  }

  void setImageAspectRatio(double ratio) {
    imageAspectRatio = ratio;
    notifyListeners();
  }

  void setSaving(bool value) {
    isSaving = value;
    notifyListeners();
  }

  void setFiltersInitialized(bool value) {
    isFiltersInitialized = value;
    notifyListeners();
  }

  void setLutService(LutFilterService service) {
    lutService = service;
  }

  bool hasUnsavedChanges() {
    return brightnessAdjustments.exposure != 0.0 ||
        brightnessAdjustments.contrast != 0.0 ||
        brightnessAdjustments.highlights != 0.0 ||
        brightnessAdjustments.shadows != 0.0 ||
        brightnessAdjustments.whites != 0.0 ||
        brightnessAdjustments.blacks != 0.0 ||
        brightnessAdjustments.saturation != 0.0 ||
        brightnessAdjustments.warmth != 0.0 ||
        brightnessAdjustments.sharpness != 0.0 ||
        brightnessAdjustments.noiseReduction != 0.0 ||
        filter != null ||
        filmEffects.grainIntensity > 0 ||
        filmEffects.dustIntensity > 0;
  }

  void resetBrightness() {
    brightnessAdjustments = const BrightnessAdjustments();
    notifyListeners();
  }

  void resetEffects() {
    filmEffects = const FilmEffects();
    notifyListeners();
  }

  void resetFilter() {
    filter = null;
    filterIntensity = 1.0;
    notifyListeners();
  }

  void resetCrop() {
    crop = CropPreset.original;
    cropOffset = Offset.zero;
    cropScale = 1.0;
    freeformCropRect = null;
    notifyListeners();
  }

  void addToHistory(String path) {
    if (currentHistoryIndex < imageHistory.length - 1) {
      imageHistory.removeRange(currentHistoryIndex + 1, imageHistory.length);
    }
    imageHistory.add(path);
    currentHistoryIndex++;
  }

  bool canUndo() => currentHistoryIndex > 0;

  void undo() {
    if (canUndo()) {
      currentHistoryIndex--;
      _imagePath = imageHistory[currentHistoryIndex];
      notifyListeners();
    }
  }
}
