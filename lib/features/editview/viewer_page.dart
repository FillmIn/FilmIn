import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'widgets/editor_app_bar.dart';
import 'widgets/image_preview_widget.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/brightness/brightness_tool.dart';
import 'widgets/effect/effect_tool.dart';
import 'widgets/filter/filter_tool.dart';
import 'widgets/crop/crop_tool.dart';
import 'debug/editview_logger.dart';
import 'package:filmin/services/filters/lut/lut_filter_service.dart';
import 'package:filmin/services/filters/xmp/shader_xmp_filter_service.dart';

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

  EditorTool _selectedTool = EditorTool.none;
  double _blurSigma = 0.0;
  String? _filter;
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

  ShaderXmpFilterService? _shaderService;
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
      _loadImageAspectRatio(); // 이미지 비율 로드
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
      }
    } catch (e) {
      _logEditError('Failed to load image aspect ratio', e);
    }
  }

  Future<void> _initializeFilterServices() async {
    await Future.wait([_initializeShaderService(), _initializeLutService()]);
    if (mounted) {
      setState(() => _isFiltersInitialized = true);
    }
  }

  Future<void> _initializeShaderService() async {
    _shaderService = ShaderXmpFilterService();
    await _shaderService!.initialize();
  }

  Future<void> _initializeLutService() async {
    _lutService = LutFilterService();
    await _lutService!.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: EditorAppBar(
        onCompareStart: () => setState(() => _showOriginal = true),
        onCompareEnd: () => setState(() => _showOriginal = false),
        onSave: _saveEdits,
        onUndo: _undoEdit,
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
                            blurSigma: _blurSigma,
                            filter: _filter,
                            crop: _selectedTool == EditorTool.crop
                                ? CropPreset.original
                                : _crop,
                            showOriginal: _showOriginal,
                            isFiltersInitialized: _isFiltersInitialized,
                            shaderService: _shaderService,
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
              if (_selectedTool != EditorTool.crop)
                EditorToolbar(
                  selectedTool: _selectedTool,
                  onToolSelected: (tool) =>
                      setState(() => _selectedTool = tool),
                ),
            ],
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '이미지 처리 중...',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToolPanel() {
    Widget panel;
    switch (_selectedTool) {
      case EditorTool.brightness:
        panel = BrightnessToolPanel(
          brightness: _brightness,
          onChanged: (v) => setState(() => _brightness = v),
        );
        break;
      case EditorTool.effect:
        panel = EffectToolPanel(
          blurSigma: _blurSigma,
          onChanged: (v) => setState(() => _blurSigma = v),
        );
        break;
      case EditorTool.filter:
        panel = FilterToolPanel(
          selectedFilter: _filter,
          onChanged: (filter) {
            _logEdit('Filter selected: $filter');
            setState(() => _filter = filter);
          },
        );
        break;
      case EditorTool.crop:
        panel = CropToolPanel(
          selectedCrop: _crop,
          onCropChanged: (crop) => setState(() {
            _crop = crop;
            // 비율 변경 시 offset과 scale 초기화
            _cropOffset = Offset.zero;
            _cropScale = 1.0;
            _freeformCropRect = null; // 자유 형식 영역도 초기화
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
            setState(() => _selectedTool = EditorTool.none);
            // 완료 버튼 누르면 자동으로 저장
            await _saveEdits();
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
      final hasOtherEdits = _rotation % 360 != 0 ||
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

      // EXIF 정보와 색 공간을 보존하기 위해 명시적으로 디코드
      img.Image? image = img.decodeImage(bytes);
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
      if (_filter != null) {
        if (_filter!.contains('PORTRA')) {
          image = img.adjustColor(image, saturation: 0.05, gamma: 0.98);
        } else if (_filter!.contains('Fuji')) {
          image = img.adjustColor(image, saturation: 0.1, gamma: 1.02);
        } else if (_filter!.contains('Cinestill')) {
          image = img.adjustColor(image, saturation: -0.05, gamma: 0.95);
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
          if (_freeformCropRect != null) {
            _logEdit('Applying freeform crop...');
            image = _freeformCrop(image, _freeformCropRect!);
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

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 원본 파일 확장자 확인
      final originalExt = path.toLowerCase().split('.').last;
      final isPng = originalExt == 'png';

      // 원본 형식 유지 (PNG는 PNG로, 그 외는 고품질 JPG로)
      final outPath = '${dir.path}/${timestamp}_edited.${isPng ? 'png' : 'jpg'}';

      // 별도 isolate에서 인코딩 처리 (UI 블로킹 방지)
      _logEdit('Starting image encoding in background...');
      final encodeParams = _EncodeParams(
        image,
        isPng,
        isPng ? 3 : 92, // PNG: level 3, JPG: quality 92
      );
      final outBytes = await compute(_encodeImageInIsolate, encodeParams);
      _logEdit('Encoding completed');

      await File(outPath).writeAsBytes(outBytes);
      _logEdit('File size: ${outBytes.length} bytes');

      if (!mounted) return;
      setState(() {
        _imagePath = outPath;
        // 히스토리에 추가
        // 현재 인덱스 이후의 히스토리 제거 (새로운 편집 경로 생성)
        if (_currentHistoryIndex < _imageHistory.length - 1) {
          _imageHistory.removeRange(_currentHistoryIndex + 1, _imageHistory.length);
        }
        _imageHistory.add(outPath);
        _currentHistoryIndex = _imageHistory.length - 1;
        _logEdit('History updated: ${_imageHistory.length} items, current index: $_currentHistoryIndex');
        // 로딩 종료
        _isSaving = false;
      });
      _logEdit('Image saved to: $outPath');
      _logEdit('========== SAVE EDITS END ==========');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved edited copy to temp folder.')),
      );
    } catch (e, stackTrace) {
      _logEditError('Save failed', e, stackTrace);
      setState(() => _isSaving = false); // 에러 발생 시에도 로딩 종료
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
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

    _logEdit('Crop in image coords: left=$cropLeftInImage, top=$cropTopInImage, w=$cropWidthInImage, h=$cropHeightInImage');

    // 경계 체크
    final x = cropLeftInImage.clamp(0.0, sw.toDouble());
    final y = cropTopInImage.clamp(0.0, sh.toDouble());
    final w = cropWidthInImage.clamp(1.0, sw - x);
    final h = cropHeightInImage.clamp(1.0, sh - y);

    _logEdit('Final crop: x=${x.round()}, y=${y.round()}, w=${w.round()}, h=${h.round()}');
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

    _logEdit('Final crop: x=${x.round()}, y=${y.round()}, w=${cropWidth.round()}, h=${cropHeight.round()}');
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
