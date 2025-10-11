import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'widgets/editor_app_bar.dart';
import 'widgets/image_preview_widget.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/brightness_tool.dart';
import 'widgets/effect_tool.dart';
import 'widgets/filter_tool.dart';
import 'widgets/crop_tool.dart';
import '../../services/shader_xmp_filter_service.dart';
import '../../services/lut_filter_service.dart';

class ViewerPage extends StatefulWidget {
  final dynamic asset;

  const ViewerPage({super.key, this.asset});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late String? _imagePath;
  int _rotation = 0;
  bool _flipH = false;
  double _brightness = 0.0;

  EditorTool _selectedTool = EditorTool.none;
  double _blurSigma = 0.0;
  String? _filter;
  CropPreset _crop = CropPreset.original;
  bool _showOriginal = false;

  ShaderXmpFilterService? _shaderService;
  LutFilterService? _lutService;
  bool _isFiltersInitialized = false;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.asset is String ? widget.asset as String : null;
    _initializeFilterServices();
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
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: ImagePreviewWidget(
                    imagePath: _imagePath,
                    rotation: _rotation,
                    flipH: _flipH,
                    brightness: _brightness,
                    blurSigma: _blurSigma,
                    filter: _filter,
                    crop: _crop,
                    showOriginal: _showOriginal,
                    isFiltersInitialized: _isFiltersInitialized,
                    shaderService: _shaderService,
                    lutService: _lutService,
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
            ),
          ),
          _buildToolPanel(),
          EditorToolbar(
            selectedTool: _selectedTool,
            onToolSelected: (tool) => setState(() => _selectedTool = tool),
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
            debugPrint('Filter selected: $filter');
            setState(() => _filter = filter);
          },
        );
        break;
      case EditorTool.crop:
        panel = CropToolPanel(
          selectedCrop: _crop,
          onCropChanged: (crop) => setState(() => _crop = crop),
          onRotateLeft: () =>
              setState(() => _rotation = (_rotation - 90) % 360),
          onRotateRight: () =>
              setState(() => _rotation = (_rotation + 90) % 360),
          onFlipHorizontal: () => setState(() => _flipH = !_flipH),
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

  Future<void> _saveEdits() async {
    final path = _imagePath;
    if (path == null || path.isEmpty) return;
    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    if (isHttp) {
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
      final bytes = await File(path).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Unsupported image: $path');

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
      switch (_crop) {
        case CropPreset.original:
          break;
        case CropPreset.square:
          image = _centerCropToAspect(image, 1, 1);
          break;
        case CropPreset.r4x5:
          image = _centerCropToAspect(image, 4, 5);
          break;
        case CropPreset.r16x9:
          image = _centerCropToAspect(image, 16, 9);
          break;
      }

      final dir = await getTemporaryDirectory();
      final outPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_edited.jpg';
      final outBytes = img.encodeJpg(image, quality: 95);
      await File(outPath).writeAsBytes(outBytes);

      if (!mounted) return;
      setState(() => _imagePath = outPath);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved edited copy to temp folder.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }

  img.Image _centerCropToAspect(img.Image src, int wRatio, int hRatio) {
    final sw = src.width;
    final sh = src.height;
    final target = wRatio / hRatio;
    final srcAspect = sw / sh;
    int x = 0, y = 0, tw = sw, th = sh;
    if (srcAspect > target) {
      th = sh;
      tw = (sh * target).round();
      x = ((sw - tw) / 2).round();
      y = 0;
    } else {
      tw = sw;
      th = (sw / target).round();
      x = 0;
      y = ((sh - th) / 2).round();
    }
    return img.copyCrop(src, x: x, y: y, width: tw, height: th);
  }
}
