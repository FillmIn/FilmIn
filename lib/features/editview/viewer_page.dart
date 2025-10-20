import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

import 'widgets/editor_app_bar.dart';
import 'widgets/image_preview_widget.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/brightness/brightness_tool.dart';
import 'widgets/effect/effect_tool.dart';
import 'widgets/filter/filter_tool.dart';
import 'widgets/crop/crop_tool.dart';
import 'debug/editview_logger.dart';
import 'package:filmin/services/filters/lut/lut_filter_service.dart';
import 'viewer_page_brightness_functions.dart' as brightness_funcs;

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

  late String? _imagePath;
  final int _rotation = 0;
  final bool _flipH = false;
  double _brightness = 0.0;
  BrightnessAdjustments _brightnessAdjustments = const BrightnessAdjustments();

  EditorTool _selectedTool = EditorTool.none;
  double _blurSigma = 0.0;
  String? _filter;
  double _filterIntensity = 1.0; // 필터 강도 (0.0 ~ 1.0)
  CropPreset _crop = CropPreset.original;
  bool _showOriginal = false;

  // 크롭 조정 정보
  Offset _cropOffset = Offset.zero;
  double _cropScale = 1.0;
  Size _screenSize = Size.zero; // 화면 크기 저장
  Rect? _freeformCropRect; // 자유 형식 크롭 영역
  double? _imageAspectRatio; // 이미지 비율 (width / height)

  // 편집 히스토리
  final List<String> _imageHistory = [];
  int _currentHistoryIndex = -1;

  LutFilterService? _lutService;
  bool _isFiltersInitialized = false;
  bool _isSaving = false; // 저장 중 상태

  @override
  void initState() {
    super.initState();
    _imagePath = widget.asset is String ? widget.asset as String : null;
    // 초기 이미지를 히스토리에 추가
    if (_imagePath != null) {
      _imageHistory.add(_imagePath!);
      _currentHistoryIndex = 0;
    }
    // 필터 서비스만 백그라운드에서 초기화
    // 이미지 비율은 Crop 도구 사용 시에만 로드 (지연 로딩)
    _initializeFilterServices();
  }

  Future<void> _loadImageAspectRatio() async {
    final path = _imagePath;
    if (path == null || path.isEmpty) return;

    try {
      final file = File(path);
      if (!file.existsSync()) return;

      // 작은 크기로 디코딩하여 비율만 확인 (성능 최적화)
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null && mounted) {
        setState(() {
          _imageAspectRatio = image.width / image.height;
        });
        // 메모리 해제
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
    // 편집 내용이 있는지 확인
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
        _blurSigma > 0;
  }

  Future<void> _handleBackButton() async {
    // 편집 내용이 있는지 확인
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
                              blurSigma: _blurSigma,
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
                // 도구가 선택되지 않았을 때만 툴바 표시
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
            // 완료 버튼 - 상태만 유지하고 도구 닫기 (저장 안함)
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
          blurSigma: _blurSigma,
          onChanged: (v) => setState(() => _blurSigma = v),
          onCancel: () => setState(() {
            _blurSigma = 0.0;
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
        // Crop 도구 선택 시 이미지 비율 로드 (지연 로딩)
        if (_imageAspectRatio == null) {
          _loadImageAspectRatio();
        }

        panel = CropToolPanel(
          selectedCrop: _crop,
          onCropChanged: (crop) => setState(() {
            _crop = crop;
            // 비율 변경 시 offset과 scale 초기화
            _cropOffset = Offset.zero;
            _cropScale = 1.0;
            // 자유 형식으로 변경 시 기본 rect 생성, 다른 비율은 null로 초기화
            if (crop == CropPreset.freeform) {
              // CropOverlay가 기본 rect를 생성하도록 Rect.zero 설정
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
            // 자르기는 임시 파일로 저장하고 히스토리 관리
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

  Future<bool> _saveToGallery(List<int> imageBytes, bool isPng) async {
    try {
      _logEdit('Requesting storage permission...');

      // 권한 요청
      PermissionStatus status;
      if (Platform.isAndroid) {
        // Android 13 (API 33) 이상에서는 사진/동영상 권한 따로 요청
        if (await Permission.photos.isGranted ||
            await Permission.storage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
      } else {
        // iOS
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        _logEdit('Storage permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('갤러리 저장 권한이 필요합니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return false;
      }

      _logEdit('Permission granted, saving to gallery...');

      // 갤러리에 저장
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(imageBytes),
        quality: isPng ? 100 : 95,
        name: 'FilmIn_${DateTime.now().millisecondsSinceEpoch}',
      );

      _logEdit('Gallery save result: $result');

      if (result != null && result['isSuccess'] == true) {
        _logEdit('Image successfully saved to gallery');
        return true;
      } else {
        _logEdit('Failed to save image to gallery');
        return false;
      }
    } catch (e, stackTrace) {
      _logEditError('Gallery save failed', e, stackTrace);
      return false;
    }
  }

  Future<void> _autoAdjustImage() async {
    final path = _imagePath;
    if (path == null || path.isEmpty) return;

    // 먼저 로딩 상태 표시
    setState(() => _isSaving = true);

    // 현재 프레임이 렌더링될 때까지 대기 (UI 업데이트 보장)
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final file = File(path);
      if (!file.existsSync()) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        if (mounted) setState(() => _isSaving = false);
        return;
      }

      // 이미지 분석 (샘플링)
      int totalR = 0, totalG = 0, totalB = 0;
      int minLum = 255, maxLum = 0;
      int darkPixels = 0, brightPixels = 0;
      final sampleStep = 10;
      int sampledPixels = 0;

      for (var y = 0; y < image.height; y += sampleStep) {
        for (var x = 0; x < image.width; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r.toInt();
          final g = pixel.g.toInt();
          final b = pixel.b.toInt();

          totalR += r;
          totalG += g;
          totalB += b;
          sampledPixels++;

          final lum = (0.299 * r + 0.587 * g + 0.114 * b).toInt();
          if (lum < minLum) minLum = lum;
          if (lum > maxLum) maxLum = lum;
          if (lum < 85) darkPixels++;
          if (lum > 170) brightPixels++;
        }
      }

      final avgR = totalR / sampledPixels;
      final avgG = totalG / sampledPixels;
      final avgB = totalB / sampledPixels;
      final avgLum = (0.299 * avgR + 0.587 * avgG + 0.114 * avgB);
      final lumRange = maxLum - minLum;

      // 자동 조정 값 계산
      double exposure = 0.0;
      double contrast = 0.0;
      double highlights = 0.0;
      double shadows = 0.0;
      double saturation = 0.0;

      if (avgLum < 100) {
        exposure = ((100 - avgLum) / 255.0).clamp(0.0, 0.3);
      } else if (avgLum > 155) {
        exposure = -((avgLum - 155) / 255.0).clamp(0.0, 0.3);
      }

      if (lumRange < 150) {
        contrast = ((150 - lumRange) / 300.0).clamp(0.0, 0.3);
      }

      if (brightPixels > sampledPixels * 0.15) {
        highlights = -((brightPixels / sampledPixels - 0.15) * 2).clamp(
          0.0,
          0.2,
        );
      }

      if (darkPixels > sampledPixels * 0.15) {
        shadows = ((darkPixels / sampledPixels - 0.15) * 2).clamp(0.0, 0.2);
      }

      final colorVariance =
          (avgR - avgG).abs() + (avgG - avgB).abs() + (avgR - avgB).abs();
      if (colorVariance < 30) {
        saturation = 0.15;
      }

      if (!mounted) return;
      setState(() {
        _brightnessAdjustments = BrightnessAdjustments(
          exposure: exposure,
          contrast: contrast,
          highlights: highlights,
          shadows: shadows,
          saturation: saturation,
          warmth: 0.2,
          sharpness: 0.1,
        );
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

  // 임시 파일로 저장 (자르기용 - 히스토리 관리)
  // ⚠️ 중요: 이 함수는 순수하게 자르기만 수행합니다 (다른 편집은 적용하지 않음)
  // 다른 편집(밝기, 필터 등)을 다시 적용하면 PNG로 저장해도 품질이 계속 떨어집니다
  Future<void> _saveTempEdits() async {
    _logEdit('========== SAVE TEMP EDITS (CROP ONLY) START ==========');

    // 로딩 시작
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
      _logEdit('Reading image from: $path');

      final bytes = await File(path).readAsBytes();

      // 포맷별 디코더 사용으로 품질 향상
      img.Image? image;
      final ext = path.toLowerCase().split('.').last;
      if (ext == 'jpg' || ext == 'jpeg') {
        image = img.decodeJpg(bytes);
        _logEdit('Decoded as JPEG with format-specific decoder');
      } else if (ext == 'png') {
        image = img.decodePng(bytes);
        _logEdit('Decoded as PNG with format-specific decoder');
      } else {
        image = img.decodeImage(bytes);
        _logEdit('Decoded with generic decoder');
      }

      if (image == null) throw Exception('Unsupported image: $path');

      _logEdit('Original image format: ${image.numChannels} channels');
      _logEdit('Image size: ${image.width}x${image.height}');

      // ⚠️ 자르기만 수행 - 다른 편집은 건너뜀
      // 이미지는 이미 이전 단계에서 밝기/필터가 적용된 상태이므로 다시 적용하지 않음
      _logEdit('⚠️ CROP ONLY MODE - Skipping brightness/filter adjustments');
      _logEdit('Current crop preset: $_crop');
      _logEdit('Crop offset: $_cropOffset, scale: $_cropScale');

      // 크롭만 적용
      switch (_crop) {
        case CropPreset.original:
          _logEdit('No crop applied (original preset)');
          break;
        case CropPreset.freeform:
          if (_freeformCropRect != null && _freeformCropRect != Rect.zero) {
            _logEdit('Applying freeform crop...');
            _logEdit('Freeform rect: $_freeformCropRect');
            image = _freeformCrop(image, _freeformCropRect!);
          } else {
            _logEdit('⚠️ Freeform crop skipped: rect is null or zero');
          }
          break;
        case CropPreset.square:
          _logEdit('Applying square crop...');
          image = _customCropToAspect(image, 1, 1, _cropOffset, _cropScale);
          break;
        case CropPreset.r4x5:
          _logEdit('Applying 4:5 crop...');
          image = _customCropToAspect(image, 4, 5, _cropOffset, _cropScale);
          break;
        case CropPreset.r3x4:
          _logEdit('Applying 3:4 crop...');
          image = _customCropToAspect(image, 3, 4, _cropOffset, _cropScale);
          break;
        case CropPreset.r9x16:
          _logEdit('Applying 9:16 crop...');
          image = _customCropToAspect(image, 9, 16, _cropOffset, _cropScale);
          break;
        case CropPreset.r16x9:
          _logEdit('Applying 16:9 crop...');
          image = _customCropToAspect(image, 16, 9, _cropOffset, _cropScale);
          break;
      }

      // 임시 파일은 무손실 PNG로 저장 (색상 변동 방지)
      // 압축 레벨 6을 사용 (9는 너무 느리고, 6이 품질과 속도의 최적 균형점)
      _logEdit('Starting image encoding to PNG (lossless)...');
      _logEdit('Image bit depth: ${image.numChannels} channels');
      _logEdit('Image has alpha: ${image.hasAlpha}');
      final encodeParams = _EncodeParams(
        image,
        true,  // 항상 PNG로 저장
        6,     // PNG compression level (6 = 좋은 품질과 적당한 속도)
      );
      final outBytes = await compute(_encodeImageInIsolate, encodeParams);
      _logEdit('Encoding completed');

      // 임시 디렉토리에 PNG로 저장
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = '${tempDir.path}/edited_$timestamp.png';

      await File(outPath).writeAsBytes(outBytes);
      _logEdit('Temp file saved: $outPath');
      _logEdit('File size: ${outBytes.length} bytes');

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
        // 크롭 상태 초기화
        _crop = CropPreset.original;
        _cropOffset = Offset.zero;
        _cropScale = 1.0;
        _freeformCropRect = null;
      });

      _logEdit('History updated: index=$_currentHistoryIndex, total=${_imageHistory.length}');
      _logEdit('========== SAVE TEMP EDITS END ==========');

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

  // 갤러리에 최종 저장
  Future<void> _saveEdits() async {
    _logEdit('========== SAVE EDITS START ==========');

    // 로딩 시작
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
      _logEdit('Reading image from: $path');

      // 크롭만 있고 다른 편집이 없는지 확인
      final hasOtherEdits =
          _rotation % 360 != 0 ||
          _flipH ||
          _brightness != 0.0 ||
          _filter != null ||
          _blurSigma > 0;

      if (hasOtherEdits) {
        _logEdit('Multiple edits detected, processing full pipeline');
      } else {
        _logEdit('Crop only, using optimized pipeline');
      }

      final bytes = await File(path).readAsBytes();

      // 포맷별 디코더 사용으로 품질 향상
      img.Image? image;
      final ext = path.toLowerCase().split('.').last;
      if (ext == 'jpg' || ext == 'jpeg') {
        image = img.decodeJpg(bytes);
        _logEdit('Decoded as JPEG with format-specific decoder');
      } else if (ext == 'png') {
        image = img.decodePng(bytes);
        _logEdit('Decoded as PNG with format-specific decoder');
      } else {
        image = img.decodeImage(bytes);
        _logEdit('Decoded with generic decoder');
      }

      if (image == null) throw Exception('Unsupported image: $path');

      _logEdit('Original image format: ${image.numChannels} channels');
      _logEdit('Image size: ${image.width}x${image.height}');

      if (_rotation % 360 != 0) {
        image = img.copyRotate(image, angle: _rotation);
      }
      if (_flipH) {
        image = img.flipHorizontal(image);
      }
      if (_brightness != 0.0) {
        image = img.adjustColor(image, brightness: _brightness);
      }

      // 고급 밝기 조정 (병렬 처리)
      if (_brightnessAdjustments.exposure != 0.0) {
        final adjust = (_brightnessAdjustments.exposure * 100).round();
        final params = brightness_funcs.ExposureParams(image, adjust);
        image = await compute(brightness_funcs.applyExposureInIsolate, params);
      }
      if (_brightnessAdjustments.contrast != 0.0) {
        final contrastValue = 1.0 + _brightnessAdjustments.contrast;
        image = img.adjustColor(image, contrast: contrastValue);
      }
      if (_brightnessAdjustments.saturation != 0.0) {
        final saturationValue = 1.0 + _brightnessAdjustments.saturation;
        image = img.adjustColor(image, saturation: saturationValue);
      }
      if (_brightnessAdjustments.highlights != 0.0 ||
          _brightnessAdjustments.shadows != 0.0) {
        final params = brightness_funcs.HighlightsShadowsParams(
          image,
          _brightnessAdjustments.highlights,
          _brightnessAdjustments.shadows,
        );
        image = await compute(
          brightness_funcs.applyHighlightsShadowsInIsolate,
          params,
        );
      }
      if (_brightnessAdjustments.whites != 0.0 ||
          _brightnessAdjustments.blacks != 0.0) {
        final params = brightness_funcs.WhitesBlacksParams(
          image,
          _brightnessAdjustments.whites,
          _brightnessAdjustments.blacks,
        );
        image = await compute(
          brightness_funcs.applyWhitesBlacksInIsolate,
          params,
        );
      }
      if (_brightnessAdjustments.warmth != 0.0) {
        final params = brightness_funcs.WarmthParams(
          image,
          _brightnessAdjustments.warmth,
        );
        image = await compute(brightness_funcs.applyWarmthInIsolate, params);
      }
      if (_brightnessAdjustments.sharpness != 0.0 &&
          _brightnessAdjustments.sharpness > 0) {
        final params = brightness_funcs.SharpenParams(
          image,
          _brightnessAdjustments.sharpness,
        );
        image = await compute(brightness_funcs.applySharpenInIsolate, params);
      }
      if (_brightnessAdjustments.noiseReduction > 0) {
        final radius = (_brightnessAdjustments.noiseReduction * 3)
            .toInt()
            .clamp(1, 5);
        image = img.gaussianBlur(image, radius: radius);
      }

      // LUT 필터 적용 (원본 LUT 색감 그대로 사용, intensity 적용)
      if (_filter != null && _lutService != null) {
        _logEdit('Applying LUT filter: $_filter (intensity: $_filterIntensity)');
        final lut = _lutService!.getLut(_filter!);
        if (lut != null) {
          final lutParams = brightness_funcs.LutParams(image, lut, _filterIntensity);
          image = await compute(brightness_funcs.applyLutInIsolate, lutParams);
          _logEdit('LUT filter applied successfully with intensity $_filterIntensity');
        } else {
          _logEdit('LUT not found for filter: $_filter');
        }
      }
      if (_blurSigma > 0) {
        final r = _blurSigma.clamp(0, 50).toInt();
        if (r > 0) {
          image = img.gaussianBlur(image, radius: r);
        }
      }
      _logEdit('Current crop preset: $_crop');
      _logEdit('Crop offset: $_cropOffset, scale: $_cropScale');

      switch (_crop) {
        case CropPreset.original:
          _logEdit('No crop applied (original preset)');
          break;
        case CropPreset.freeform:
          if (_freeformCropRect != null && _freeformCropRect != Rect.zero) {
            _logEdit('Applying freeform crop...');
            _logEdit('Freeform rect: $_freeformCropRect');
            image = _freeformCrop(image, _freeformCropRect!);
          } else {
            _logEdit('⚠️ Freeform crop skipped: rect is null or zero');
          }
          break;
        case CropPreset.square:
          _logEdit('Applying square crop...');
          image = _customCropToAspect(image, 1, 1, _cropOffset, _cropScale);
          break;
        case CropPreset.r4x5:
          _logEdit('Applying 4:5 crop...');
          image = _customCropToAspect(image, 4, 5, _cropOffset, _cropScale);
          break;
        case CropPreset.r3x4:
          _logEdit('Applying 3:4 crop...');
          image = _customCropToAspect(image, 3, 4, _cropOffset, _cropScale);
          break;
        case CropPreset.r9x16:
          _logEdit('Applying 9:16 crop...');
          image = _customCropToAspect(image, 9, 16, _cropOffset, _cropScale);
          break;
        case CropPreset.r16x9:
          _logEdit('Applying 16:9 crop...');
          image = _customCropToAspect(image, 16, 9, _cropOffset, _cropScale);
          break;
      }

      // 원본 파일 확장자 확인
      final originalExt = path.toLowerCase().split('.').last;
      final isPng = originalExt == 'png';

      // 별도 isolate에서 인코딩 처리 (UI 블로킹 방지)
      _logEdit('Starting image encoding in background...');
      _logEdit('Output format: ${isPng ? 'PNG' : 'JPEG'}');
      final encodeParams = _EncodeParams(
        image,
        isPng,
        isPng ? 6 : 95, // PNG: level 6 (좋은 압축), JPG: quality 95 (고품질)
      );
      final outBytes = await compute(_encodeImageInIsolate, encodeParams);
      _logEdit('Encoding completed');
      _logEdit('File size: ${outBytes.length} bytes');

      // 갤러리에 직접 저장
      final saveResult = await _saveToGallery(outBytes, isPng);

      if (!mounted) return;
      setState(() {
        // 로딩 종료
        _isSaving = false;
      });
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
      setState(() => _isSaving = false); // 에러 발생 시에도 로딩 종료
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  img.Image _freeformCrop(img.Image src, Rect screenRect) {
    final sw = src.width;
    final sh = src.height;
    final imageAspect = sw / sh;

    _logEdit('========== FREEFORM CROP DEBUG ==========');
    _logEdit('Image size: ${sw}x$sh');
    _logEdit('Screen rect: $screenRect');
    _logEdit('Screen size: $_screenSize');

    // 화면에서 이미지가 실제로 표시되는 크기 계산 (BoxFit.contain 로직)
    final screenAspect = _screenSize.width / _screenSize.height;
    double screenImageWidth, screenImageHeight;
    double imageLeft, imageTop;

    if (imageAspect > screenAspect) {
      // 이미지가 화면보다 가로로 더 넓음 - 화면 너비에 맞춤
      screenImageWidth = _screenSize.width;
      screenImageHeight = _screenSize.width / imageAspect;
      imageLeft = 0;
      imageTop = (_screenSize.height - screenImageHeight) / 2;
    } else {
      // 이미지가 화면보다 세로로 더 김 - 화면 높이에 맞춤
      screenImageHeight = _screenSize.height;
      screenImageWidth = _screenSize.height * imageAspect;
      imageLeft = (_screenSize.width - screenImageWidth) / 2;
      imageTop = 0;
    }

    _logEdit('Screen image position: ($imageLeft, $imageTop)');
    _logEdit('Screen image size: ${screenImageWidth}x$screenImageHeight');

    // 화면 픽셀 -> 이미지 픽셀 변환 비율
    final double pixelRatioX = sw / screenImageWidth;
    final double pixelRatioY = sh / screenImageHeight;

    _logEdit('Pixel ratio: x=$pixelRatioX, y=$pixelRatioY');

    // 크롭 영역을 이미지 좌표계로 변환
    // screenRect는 전체 화면 기준이므로, 이미지 영역 내의 좌표로 변환
    final cropLeftInImage = (screenRect.left - imageLeft) * pixelRatioX;
    final cropTopInImage = (screenRect.top - imageTop) * pixelRatioY;
    final cropWidthInImage = screenRect.width * pixelRatioX;
    final cropHeightInImage = screenRect.height * pixelRatioY;

    _logEdit(
      'Crop in image coords: left=$cropLeftInImage, top=$cropTopInImage, w=$cropWidthInImage, h=$cropHeightInImage',
    );

    // 경계 체크
    final x = cropLeftInImage.clamp(0.0, sw.toDouble());
    final y = cropTopInImage.clamp(0.0, sh.toDouble());
    final w = cropWidthInImage.clamp(1.0, sw - x);
    final h = cropHeightInImage.clamp(1.0, sh - y);

    _logEdit(
      'Final crop: x=${x.round()}, y=${y.round()}, w=${w.round()}, h=${h.round()}',
    );
    _logEdit('====================================');

    return img.copyCrop(
      src,
      x: x.round(),
      y: y.round(),
      width: w.round(),
      height: h.round(),
    );
  }

  img.Image _customCropToAspect(
    img.Image src,
    int wRatio,
    int hRatio,
    Offset offset,
    double scale,
  ) {
    final sw = src.width;
    final sh = src.height;
    final target = wRatio / hRatio;
    final imageAspect = sw / sh;

    _logEdit('========== CROP DEBUG ==========');
    _logEdit('Image size: ${sw}x$sh');
    _logEdit('Image aspect: $imageAspect');
    _logEdit('Screen offset: $offset, Scale: $scale');
    _logEdit('Screen size: $_screenSize');
    _logEdit('Target aspect: $wRatio:$hRatio = $target');

    // 화면에서 이미지가 실제로 표시되는 크기 계산 (BoxFit.contain 로직)
    final screenAspect = _screenSize.width / _screenSize.height;
    double screenImageWidth, screenImageHeight;

    if (imageAspect > screenAspect) {
      // 이미지가 화면보다 가로로 더 넓음 - 화면 너비에 맞춤
      screenImageWidth = _screenSize.width;
      screenImageHeight = _screenSize.width / imageAspect;
    } else {
      // 이미지가 화면보다 세로로 더 김 - 화면 높이에 맞춤
      screenImageHeight = _screenSize.height;
      screenImageWidth = _screenSize.height * imageAspect;
    }

    _logEdit('Screen image size: ${screenImageWidth}x$screenImageHeight');

    // 화면 픽셀 -> 이미지 픽셀 변환 비율
    final double pixelRatioX = sw / screenImageWidth;
    final double pixelRatioY = sh / screenImageHeight;

    _logEdit('Pixel ratio: x=$pixelRatioX, y=$pixelRatioY');

    // CropOverlay와 동일한 기준 크기 계산 (화면 크기의 90%)
    double baseCropWidth = screenImageWidth * 0.9;
    double baseCropHeight = baseCropWidth / target;

    if (baseCropHeight > screenImageHeight * 0.9) {
      baseCropHeight = screenImageHeight * 0.9;
      baseCropWidth = baseCropHeight * target;
    }

    _logEdit('Base crop size (screen): ${baseCropWidth}x$baseCropHeight');

    // scale 적용
    double screenCropWidth = baseCropWidth * scale;
    double screenCropHeight = baseCropHeight * scale;

    _logEdit('Scaled crop size (screen): ${screenCropWidth}x$screenCropHeight');

    // 이미지 픽셀 단위로 변환
    double cropWidth = screenCropWidth * pixelRatioX;
    double cropHeight = screenCropHeight * pixelRatioY;

    _logEdit('Crop size (image pixels): ${cropWidth}x$cropHeight');

    // offset을 이미지 좌표계로 변환
    final double imageOffsetX = offset.dx * pixelRatioX;
    final double imageOffsetY = offset.dy * pixelRatioY;

    _logEdit('Image offset: ($imageOffsetX, $imageOffsetY)');

    // 중앙 기준 좌표 계산
    double centerX = sw / 2;
    double centerY = sh / 2;

    // offset 적용
    double x = centerX - (cropWidth / 2) + imageOffsetX;
    double y = centerY - (cropHeight / 2) + imageOffsetY;

    _logEdit('Center: ($centerX, $centerY)');
    _logEdit('Crop position before clamp: ($x, $y)');

    // 경계 체크
    x = x.clamp(0.0, sw - cropWidth);
    y = y.clamp(0.0, sh - cropHeight);

    _logEdit(
      'Final crop: x=${x.round()}, y=${y.round()}, w=${cropWidth.round()}, h=${cropHeight.round()}',
    );
    _logEdit('================================');

    return img.copyCrop(
      src,
      x: x.round(),
      y: y.round(),
      width: cropWidth.round(),
      height: cropHeight.round(),
    );
  }
}

// Isolate에서 실행할 이미지 인코딩 함수들
class _EncodeParams {
  final img.Image image;
  final bool isPng;
  final int quality; // JPG quality or PNG compression level

  _EncodeParams(this.image, this.isPng, this.quality);
}

List<int> _encodeImageInIsolate(_EncodeParams params) {
  if (params.isPng) {
    return img.encodePng(params.image, level: params.quality);
  } else {
    return img.encodeJpg(params.image, quality: params.quality);
  }
}
