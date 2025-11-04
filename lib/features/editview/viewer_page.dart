import 'package:flutter/material.dart';

import 'widgets/brightness/brightness_tool.dart';
import 'widgets/effect/effect_tool.dart';
import 'widgets/crop/crop_tool.dart';
import 'widgets/editor_toolbar.dart';
import 'state/viewer_state.dart';
import 'ui/viewer_ui_builder.dart';
import 'ui/viewer_event_handlers.dart';
import 'services/lut_filter_service.dart';

class ViewerPage extends StatefulWidget {
  final dynamic asset;

  const ViewerPage({super.key, this.asset});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  // 상태 관리 객체
  late ViewerState _state;
  late ViewerEventHandlers _handlers;

  @override
  void initState() {
    super.initState();
    final initialPath = widget.asset is String ? widget.asset as String : null;
    _state = ViewerState(initialImagePath: initialPath);
    _handlers = ViewerEventHandlers(
      state: _state,
      getContext: () => context,
      setStateCallback: setState,
    );
    _initializeFilterServices();
  }

  Future<void> _initializeFilterServices() async {
    _state.lutService = LutFilterService();
    await _state.lutService!.initialize();
    if (mounted) {
      setState(() => _state.isFiltersInitialized = true);
    }
  }

  bool _hasUnsavedChanges() {
    return _state.brightnessAdjustments.exposure != 0.0 ||
        _state.brightnessAdjustments.contrast != 0.0 ||
        _state.brightnessAdjustments.highlights != 0.0 ||
        _state.brightnessAdjustments.shadows != 0.0 ||
        _state.brightnessAdjustments.whites != 0.0 ||
        _state.brightnessAdjustments.blacks != 0.0 ||
        _state.brightnessAdjustments.saturation != 0.0 ||
        _state.brightnessAdjustments.warmth != 0.0 ||
        _state.brightnessAdjustments.sharpness != 0.0 ||
        _state.brightnessAdjustments.noiseReduction != 0.0 ||
        _state.filter != null ||
        _state.filmEffects.grainIntensity > 0 ||
        _state.filmEffects.dustIntensity > 0 ||
        _state.filmEffects.halationIntensity > 0;
  }

  Future<void> _handleBackButton() async {
    await _handlers.handleBackButton(_hasUnsavedChanges());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackButton();
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: ViewerUIBuilder.buildAppBar(
          onCompareStart: () => setState(() => _state.showOriginal = true),
          onCompareEnd: () => setState(() => _state.showOriginal = false),
          onSave: _handlers.saveEdits,
          onUndo: _handlers.undoEdit,
          onBack: _handleBackButton,
          canUndo: _state.canUndo(),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_state.screenSize != constraints.biggest) {
                          setState(() {
                            _state.screenSize = constraints.biggest;
                          });
                        }
                      });

                      return Stack(
                        children: [
                          Center(
                            child: ViewerUIBuilder.buildImagePreview(
                              imagePath: _state.imagePath,
                              rotation: _state.rotation,
                              flipH: _state.flipH,
                              brightness: _state.brightness,
                              brightnessAdjustments: _state.brightnessAdjustments,
                              filmEffects: _state.filmEffects,
                              filter: _state.filter,
                              filterIntensity: _state.filterIntensity,
                              crop: _state.crop,
                              showOriginal: _state.showOriginal,
                              isFiltersInitialized: _state.isFiltersInitialized,
                              lutService: _state.lutService,
                              selectedTool: _state.selectedTool,
                            ),
                          ),
                          if (ViewerUIBuilder.buildCropOverlay(
                            selectedTool: _state.selectedTool,
                            crop: _state.crop,
                            cropOffset: _state.cropOffset,
                            cropScale: _state.cropScale,
                            freeformCropRect: _state.freeformCropRect,
                            imagePath: _state.imagePath,
                            imageAspectRatio: _state.imageAspectRatio,
                            onCropChanged: (offset, scale) {
                              _state.cropOffset = offset;
                              _state.cropScale = scale;
                            },
                            onFreeformCropChanged: (rect) {
                              _state.freeformCropRect = rect;
                            },
                          ) != null)
                            Center(
                              child: ViewerUIBuilder.buildCropOverlay(
                                selectedTool: _state.selectedTool,
                                crop: _state.crop,
                                cropOffset: _state.cropOffset,
                                cropScale: _state.cropScale,
                                freeformCropRect: _state.freeformCropRect,
                                imagePath: _state.imagePath,
                                imageAspectRatio: _state.imageAspectRatio,
                                onCropChanged: (offset, scale) {
                                  _state.cropOffset = offset;
                                  _state.cropScale = scale;
                                },
                                onFreeformCropChanged: (rect) {
                                  _state.freeformCropRect = rect;
                                },
                              ),
                            ),
                          if (ViewerUIBuilder.buildFilterTag(
                            filter: _state.filter,
                            isDark: isDark,
                          ) != null)
                            ViewerUIBuilder.buildFilterTag(
                              filter: _state.filter,
                              isDark: isDark,
                            )!,
                        ],
                      );
                    },
                  ),
                ),
                _buildToolPanel(),
                if (_state.selectedTool == EditorTool.none)
                  ViewerUIBuilder.buildToolbar(
                    selectedTool: _state.selectedTool,
                    onToolSelected: (tool) =>
                        setState(() => _state.selectedTool = tool),
                  ),
              ],
            ),

            // 로딩 오버레이
            if (ViewerUIBuilder.buildLoadingOverlay(isSaving: _state.isSaving) != null)
              ViewerUIBuilder.buildLoadingOverlay(isSaving: _state.isSaving)!,
          ],
        ),
      ),
    );
  }

  Widget _buildToolPanel() {
    // Crop 도구 선택 시 이미지 비율 로드
    if (_state.selectedTool == EditorTool.crop && _state.imageAspectRatio == null) {
      _handlers.loadImageAspectRatio();
    }

    return ViewerUIBuilder.buildToolPanel(
      selectedTool: _state.selectedTool,
      context: context,
      // Brightness
      brightnessAdjustments: _state.brightnessAdjustments,
      isProcessing: _state.isSaving,
      onBrightnessChanged: (adjustments) =>
          setState(() => _state.brightnessAdjustments = adjustments),
      onBrightnessAutoAdjust: _handlers.autoAdjustImage,
      onBrightnessCancel: () => setState(() {
        _state.brightnessAdjustments = const BrightnessAdjustments();
        _state.selectedTool = EditorTool.none;
      }),
      onBrightnessApply: () {
        setState(() => _state.selectedTool = EditorTool.none);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('밝기 조정 적용됨 (저장 버튼을 눌러 최종 저장)'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      },
      // Effect
      filmEffects: _state.filmEffects,
      onEffectChanged: (effects) => setState(() => _state.filmEffects = effects),
      onEffectCancel: () => setState(() {
        _state.filmEffects = const FilmEffects();
        _state.selectedTool = EditorTool.none;
      }),
      onEffectApply: () {
        setState(() => _state.selectedTool = EditorTool.none);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('효과 적용됨 (저장 버튼을 눌러 최종 저장)'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      },
      // Filter
      selectedFilter: _state.filter,
      imagePath: _state.imagePath,
      filterIntensity: _state.filterIntensity,
      onFilterChanged: (filter) => setState(() => _state.filter = filter),
      onFilterIntensityChanged: (intensity) =>
          setState(() => _state.filterIntensity = intensity),
      onFilterCancel: () => setState(() {
        _state.filter = null;
        _state.filterIntensity = 1.0;
        _state.selectedTool = EditorTool.none;
      }),
      onFilterApply: () {
        setState(() => _state.selectedTool = EditorTool.none);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('필터 적용됨 (저장 버튼을 눌러 최종 저장)'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      },
      // Crop
      selectedCrop: _state.crop,
      onCropChanged: (crop) => setState(() {
        _state.crop = crop;
        _state.cropOffset = Offset.zero;
        _state.cropScale = 1.0;
        if (crop == CropPreset.freeform) {
          _state.freeformCropRect = Rect.zero;
        } else {
          _state.freeformCropRect = null;
        }
      }),
      onCropCancel: () => setState(() {
        _state.crop = CropPreset.original;
        _state.cropOffset = Offset.zero;
        _state.cropScale = 1.0;
        _state.freeformCropRect = null;
        _state.selectedTool = EditorTool.none;
      }),
      onCropApply: () async {
        setState(() => _state.selectedTool = EditorTool.none);
        await _handlers.saveTempEdits();
      },
    );
  }

}
