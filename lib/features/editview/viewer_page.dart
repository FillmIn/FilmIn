import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import 'widgets/editor_app_bar.dart';
import 'widgets/image_preview_widget.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/brightness/brightness_tool.dart';
import 'widgets/effect/effect_tool.dart';
import 'widgets/filter/filter_tool.dart';
import 'widgets/crop/crop_tool.dart';
import 'debug/editview_logger.dart';
import 'package:filmin/services/filters/lut/lut_filter_service.dart';
import 'services/image_processing_service.dart';
import 'services/image_save_service.dart';

class ViewerPage extends StatefulWidget {
  final dynamic asset;

  const ViewerPage({super.key, this.asset});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  void _logEdit(String message) => EditViewLogger.log(message);
  void _logEditError(String message, [Object? error, StackTrace? stackTrace]) =>
      EditViewLogger.error(message, error, stackTrace);

  // 서비스
  final ImageProcessingService _processingService = ImageProcessingService();
  final ImageSaveService _saveService = ImageSaveService();

  // 상태
  late String? _imagePath;
  final int _rotation = 0;
  final bool _flipH = false;
  double _brightness = 0.0;
  BrightnessAdjustments _brightnessAdjustments = const BrightnessAdjustments();

  EditorTool _selectedTool = EditorTool.none;
  FilmEffects _filmEffects = const FilmEffects();
  String? _filter;
  double _filterIntensity = 1.0;
  CropPreset _crop = CropPreset.original;
  bool _showOriginal = false;

  // 크롭 조정 정보
  Offset _cropOffset = Offset.zero;
  double _cropScale = 1.0;
  Size _screenSize = Size.zero;
  Rect? _freeformCropRect;
  double? _imageAspectRatio;

  // 편집 히스토리
  final List<String> _imageHistory = [];
  int _currentHistoryIndex = -1;

  LutFilterService? _lutService;
  bool _isFiltersInitialized = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.asset is String ? widget.asset as String : null;
    if (_imagePath != null) {
      _imageHistory.add(_imagePath!);
      _currentHistoryIndex = 0;
    }
    _initializeFilterServices();
  }

  Future<void> _loadImageAspectRatio() async {
    final path = _imagePath;
    if (path == null || path.isEmpty) return;

    try {
      final file = File(path);
      if (!file.existsSync()) return;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null && mounted) {
        setState(() {
          _imageAspectRatio = image.width / image.height;
        });
        image.clear();
      }
    } catch (e) {
      _logEditError('Failed to load image aspect ratio', e);
    }
  }

  Future<void> _initializeFilterServices() async {
    _lutService = LutFilterService();
    await _lutService!.initialize();
    if (mounted) {
      setState(() => _isFiltersInitialized = true);
    }
  }

  bool _hasUnsavedChanges() {
    return _brightnessAdjustments.exposure != 0.0 ||
        _brightnessAdjustments.contrast != 0.0 ||
        _brightnessAdjustments.highlights != 0.0 ||
        _brightnessAdjustments.shadows != 0.0 ||
        _brightnessAdjustments.whites != 0.0 ||
        _brightnessAdjustments.blacks != 0.0 ||
        _brightnessAdjustments.saturation != 0.0 ||
        _brightnessAdjustments.warmth != 0.0 ||
        _brightnessAdjustments.sharpness != 0.0 ||
        _brightnessAdjustments.noiseReduction != 0.0 ||
        _filter != null ||
        _filmEffects.grainIntensity > 0 ||
        _filmEffects.dustIntensity > 0;
  }

  Future<void> _handleBackButton() async {
    final hasChanges = _hasUnsavedChanges();

    if (!mounted) return;

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            hasChanges ? '저장되지 않은 변경사항' : '편집 종료',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            hasChanges
                ? '지금까지 편집한 내용은 저장되지 않습니다.\n정말 나가시겠습니까?'
                : '편집을 종료하시겠습니까?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                backgroundColor: hasChanges
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
              ),
              child: Text(
                '나가기',
                style: TextStyle(
                  color: hasChanges ? Colors.red : Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && mounted) {
      Navigator.of(context).pop();
    }
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
        appBar: EditorAppBar(
          onCompareStart: () => setState(() => _showOriginal = true),
          onCompareEnd: () => setState(() => _showOriginal = false),
          onSave: _saveEdits,
          onUndo: _undoEdit,
          onBack: _handleBackButton,
          canUndo: _currentHistoryIndex > 0,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_screenSize != constraints.biggest) {
                          setState(() {
                            _screenSize = constraints.biggest;
                          });
                        }
                      });

                      return Stack(
                        children: [
                          Center(
                            child: ImagePreviewWidget(
                              imagePath: _imagePath,
                              rotation: _rotation,
                              flipH: _flipH,
                              brightness: _brightness,
                              brightnessAdjustments: _brightnessAdjustments,
                              filmEffects: _filmEffects,
                              filter: _filter,
                              filterIntensity: _filterIntensity,
                              crop: _selectedTool == EditorTool.crop
                                  ? CropPreset.original
                                  : _crop,
                              showOriginal: _showOriginal,
                              isFiltersInitialized: _isFiltersInitialized,
                              lutService: _lutService,
                            ),
                          ),
                          if (_selectedTool == EditorTool.crop &&
                              _crop != CropPreset.original)
                            Center(
                              child: CropOverlay(
                                preset: _crop,
                                initialOffset: _cropOffset,
                                initialScale: _cropScale,
                                initialFreeformRect: _freeformCropRect,
                                imagePath: _imagePath,
                                imageAspectRatio: _imageAspectRatio,
                                onCropChanged: (offset, scale) {
                                  _cropOffset = offset;
                                  _cropScale = scale;
                                },
                                onFreeformCropChanged: (rect) {
                                  _freeformCropRect = rect;
                                },
                              ),
                            ),
                          if (_filter != null)
                            Positioned(
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
                                  '필터: $_filter',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                _buildToolPanel(),
                if (_selectedTool == EditorTool.none)
                  EditorToolbar(
                    selectedTool: _selectedTool,
                    onToolSelected: (tool) =>
                        setState(() => _selectedTool = tool),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolPanel() {
    Widget panel;
    switch (_selectedTool) {
      case EditorTool.brightness:
        panel = BrightnessToolPanel(
          adjustments: _brightnessAdjustments,
          isProcessing: _isSaving,
          onChanged: (adjustments) =>
              setState(() => _brightnessAdjustments = adjustments),
          onAutoAdjust: _autoAdjustImage,
          onCancel: () => setState(() {
            _brightnessAdjustments = const BrightnessAdjustments();
            _selectedTool = EditorTool.none;
          }),
          onApply: () {
            setState(() => _selectedTool = EditorTool.none);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('밝기 조정 적용됨 (저장 버튼을 눌러 최종 저장)'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
        );
        break;
      case EditorTool.effect:
        panel = EffectToolPanel(
          effects: _filmEffects,
          onChanged: (effects) => setState(() => _filmEffects = effects),
          onCancel: () => setState(() {
            _filmEffects = const FilmEffects();
            _selectedTool = EditorTool.none;
          }),
          onApply: () {
            setState(() => _selectedTool = EditorTool.none);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('효과 적용됨 (저장 버튼을 눌러 최종 저장)'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
        );
        break;
      case EditorTool.filter:
        panel = FilterToolPanel(
          selectedFilter: _filter,
          imagePath: _imagePath,
          filterIntensity: _filterIntensity,
          onChanged: (filter) {
            _logEdit('Filter selected: $filter');
            setState(() => _filter = filter);
          },
          onIntensityChanged: (intensity) {
            _logEdit('Filter intensity changed: $intensity');
            setState(() => _filterIntensity = intensity);
          },
          onCancel: () => setState(() {
            _filter = null;
            _filterIntensity = 1.0;
            _selectedTool = EditorTool.none;
          }),
          onApply: () {
            setState(() => _selectedTool = EditorTool.none);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('필터 적용됨 (저장 버튼을 눌러 최종 저장)'),
                duration: Duration(milliseconds: 1500),
              ),
            );
          },
        );
        break;
      case EditorTool.crop:
        if (_imageAspectRatio == null) {
          _loadImageAspectRatio();
        }

        panel = CropToolPanel(
          selectedCrop: _crop,
          onCropChanged: (crop) => setState(() {
            _crop = crop;
            _cropOffset = Offset.zero;
            _cropScale = 1.0;
            if (crop == CropPreset.freeform) {
              _freeformCropRect = Rect.zero;
            } else {
              _freeformCropRect = null;
            }
          }),
          onCancel: () => setState(() {
            _crop = CropPreset.original;
            _cropOffset = Offset.zero;
            _cropScale = 1.0;
            _freeformCropRect = null;
            _selectedTool = EditorTool.none;
          }),
          onApply: () async {
            _logEdit('Crop applied: offset=$_cropOffset, scale=$_cropScale');
            _logEdit('Freeform crop rect: $_freeformCropRect');
            setState(() => _selectedTool = EditorTool.none);
            await _saveTempEdits();
          },
        );
        break;
      case EditorTool.none:
        panel = const SizedBox.shrink();
        break;
    }

    return SafeArea(
      top: false,
      child: Padding(padding: const EdgeInsets.only(bottom: 8), child: panel),
    );
  }

  void _undoEdit() {
    if (_currentHistoryIndex > 0) {
      setState(() {
        _currentHistoryIndex--;
        _imagePath = _imageHistory[_currentHistoryIndex];
        _logEdit('Undo: moved to index $_currentHistoryIndex');
        _logEdit('Current image: $_imagePath');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이전으로 되돌렸습니다.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _autoAdjustImage() async {
    final path = _imagePath;
    if (path == null || path.isEmpty) return;

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final adjustments =
          await _processingService.calculateAutoAdjustments(path);

      if (!mounted) return;
      setState(() {
        _brightnessAdjustments = adjustments;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자동 조정 완료'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e, stackTrace) {
      _logEditError('Auto-adjust failed', e, stackTrace);
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveTempEdits() async {
    setState(() => _isSaving = true);

    final path = _imagePath;
    if (path == null || path.isEmpty) {
      _logEdit('Save aborted: no image path');
      setState(() => _isSaving = false);
      return;
    }
    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    if (isHttp) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Editing network images not supported yet. Download first.',
          ),
        ),
      );
      return;
    }

    try {
      final outPath = await _processingService.saveCropOnly(
        imagePath: path,
        crop: _crop,
        cropOffset: _cropOffset,
        cropScale: _cropScale,
        freeformCropRect: _freeformCropRect,
        screenSize: _screenSize,
      );

      // 히스토리 업데이트
      if (_currentHistoryIndex < _imageHistory.length - 1) {
        _imageHistory.removeRange(_currentHistoryIndex + 1, _imageHistory.length);
      }
      _imageHistory.add(outPath);
      _currentHistoryIndex++;

      if (!mounted) return;
      setState(() {
        _imagePath = outPath;
        _isSaving = false;
        _crop = CropPreset.original;
        _cropOffset = Offset.zero;
        _cropScale = 1.0;
        _freeformCropRect = null;
      });

      _logEdit('History updated: index=$_currentHistoryIndex, total=${_imageHistory.length}');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('자르기가 적용되었습니다'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e, stackTrace) {
      _logEditError('Temp save failed', e, stackTrace);
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _saveEdits() async {
    _logEdit('========== SAVE EDITS START ==========');

    setState(() => _isSaving = true);

    final path = _imagePath;
    if (path == null || path.isEmpty) {
      _logEdit('Save aborted: no image path');
      setState(() => _isSaving = false);
      return;
    }
    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    if (isHttp) {
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Editing network images not supported yet. Download first.',
          ),
        ),
      );
      return;
    }

    try {
      final outBytes = await _processingService.processFullEdit(
        imagePath: path,
        rotation: _rotation,
        flipH: _flipH,
        brightness: _brightness,
        brightnessAdjustments: _brightnessAdjustments,
        filter: _filter,
        filterIntensity: _filterIntensity,
        filmEffects: _filmEffects,
        crop: _crop,
        cropOffset: _cropOffset,
        cropScale: _cropScale,
        freeformCropRect: _freeformCropRect,
        screenSize: _screenSize,
        lutService: _lutService,
      );

      final originalExt = path.toLowerCase().split('.').last;
      final isPng = originalExt == 'png';
      final saveResult = await _saveService.saveToGallery(outBytes, isPng);

      if (!mounted) return;
      setState(() => _isSaving = false);
      _logEdit('========== SAVE EDITS END ==========');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(saveResult ? '갤러리에 저장되었습니다' : '저장에 실패했습니다'),
          duration: const Duration(seconds: 2),
          backgroundColor: saveResult ? Colors.green : Colors.red,
        ),
      );
    } catch (e, stackTrace) {
      _logEditError('Save failed', e, stackTrace);
      setState(() => _isSaving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }
}
