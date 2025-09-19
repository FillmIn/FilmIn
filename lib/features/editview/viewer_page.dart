import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewerPage extends StatefulWidget {
  final dynamic asset; // 전달된 이미지 경로 등

  const ViewerPage({super.key, this.asset});

  @override
  State<ViewerPage> createState() => _ViewerPageState();
}

class _ViewerPageState extends State<ViewerPage> {
  late String? _imagePath;
  int _rotation = 0; // degrees: 0, 90, 180, 270
  bool _flipH = false;
  double _brightness = 0.0; // -1.0 ~ 1.0

  EditorTool _selectedTool = EditorTool.none;
  double _blurSigma = 0.0; // 효과(블러) 강도
  FilterPreset _filter = FilterPreset.none;
  CropPreset _crop = CropPreset.original;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.asset is String ? widget.asset as String : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('편집'),
        actions: [
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.restart_alt),
            onPressed: _reset,
          ),
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _saveEdits,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _buildPreview(),
            ),
          ),
          _buildToolPanel(),
          _buildToolBar(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final path = _imagePath;
    if (path == null || path.isEmpty) {
      return Text(
        'No image provided: ${widget.asset}',
        textAlign: TextAlign.center,
      );
    }
    final isHttp = path.startsWith('http://') || path.startsWith('https://');

    // 미리보기는 위젯 트랜스폼/필터로 빠르게 처리
    final radians = _rotation * math.pi / 180.0;
    Widget preview;
    if (isHttp) {
      preview = CachedNetworkImage(imageUrl: path, fit: BoxFit.contain);
    } else {
      final file = File(path);
      if (!file.existsSync()) {
        return Text('File not found:\n$path', textAlign: TextAlign.center);
      }
      preview = Image.file(file, fit: BoxFit.contain);
    }

    // 밝기 미리보기용 컬러 필터 매트릭스 구성
    final b = (_brightness * 255).clamp(-255.0, 255.0).toDouble();
    final brightnessFilter = ColorFilter.matrix(<double>[
      1, 0, 0, 0, b,
      0, 1, 0, 0, b,
      0, 0, 1, 0, b,
      0, 0, 0, 1, 0,
    ]);

    // 간단한 컬러 프리셋 미리보기
    final ColorFilter? presetFilter = switch (_filter) {
      FilterPreset.none => null,
      FilterPreset.mono => const ColorFilter.matrix(<double>[
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0.33, 0.33, 0.33, 0, 0,
        0,    0,    0,    1, 0,
      ]),
      FilterPreset.warm => const ColorFilter.matrix(<double>[
        1.1, 0.0, 0.0, 0, 10,
        0.0, 1.05,0.0, 0, 5,
        0.0, 0.0, 0.95,0, -5,
        0,   0,   0,   1, 0,
      ]),
      FilterPreset.cool => const ColorFilter.matrix(<double>[
        0.95,0.0, 0.0, 0, -5,
        0.0, 1.0, 0.0, 0, 0,
        0.0, 0.0, 1.08,0, 8,
        0,   0,   0,   1, 0,
      ]),
    };

    Widget content = ColorFiltered(colorFilter: brightnessFilter, child: preview);
    if (presetFilter != null) {
      content = ColorFiltered(colorFilter: presetFilter, child: content);
    }
    if (_flipH) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
        child: content,
      );
    }
    content = Transform.rotate(angle: radians, child: content);

    // 효과(블러) 적용 미리보기
    if (_blurSigma > 0) {
      content = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: content,
      );
    }

    // 자르기 비율 미리보기 (중앙 크롭 형태)
    final aspect = switch (_crop) {
      CropPreset.original => null,
      CropPreset.square => 1.0,
      CropPreset.r4x5 => 4 / 5,
      CropPreset.r16x9 => 16 / 9,
    };

    if (aspect == null) return content;
    return AspectRatio(
      aspectRatio: aspect,
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: 1000, // 충분히 큰 가상 크기로 채워서 cover 동작 유도
            height: 1000,
            child: Center(child: content),
          ),
        ),
      ),
    );
  }

  Widget _buildToolBar() {
    return SafeArea(
      top: false,
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              icon: Icons.wb_sunny_outlined,
              label: '밝기',
              selected: _selectedTool == EditorTool.brightness,
              onTap: () => setState(() => _selectedTool = EditorTool.brightness),
            ),
            _ToolButton(
              icon: Icons.tune,
              label: '효과',
              selected: _selectedTool == EditorTool.effect,
              onTap: () => setState(() => _selectedTool = EditorTool.effect),
            ),
            _ToolButton(
              icon: Icons.filter_vintage_outlined,
              label: '필터',
              selected: _selectedTool == EditorTool.filter,
              onTap: () => setState(() => _selectedTool = EditorTool.filter),
            ),
            _ToolButton(
              icon: Icons.crop,
              label: '자르기',
              selected: _selectedTool == EditorTool.crop,
              onTap: () => setState(() => _selectedTool = EditorTool.crop),
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
        panel = Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.brightness_6, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _brightness,
                    min: -1.0,
                    max: 1.0,
                    onChanged: (v) => setState(() => _brightness = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.brightness_7, size: 20),
            ],
          ),
        );
        break;
      case EditorTool.effect:
        panel = Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.blur_off, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  ),
                  child: Slider(
                    value: _blurSigma,
                    min: 0.0,
                    max: 10.0,
                    onChanged: (v) => setState(() => _blurSigma = v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.blur_on, size: 20),
            ],
          ),
        );
        break;
      case EditorTool.filter:
        panel = Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _filterChip('없음', _filter == FilterPreset.none, () => setState(() => _filter = FilterPreset.none)),
              _filterChip('웜', _filter == FilterPreset.warm, () => setState(() => _filter = FilterPreset.warm)),
              _filterChip('쿨', _filter == FilterPreset.cool, () => setState(() => _filter = FilterPreset.cool)),
              _filterChip('모노', _filter == FilterPreset.mono, () => setState(() => _filter = FilterPreset.mono)),
            ],
          ),
        );
        break;
      case EditorTool.crop:
        panel = Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 이미지 조절 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _imageControlButton(
                    icon: Icons.rotate_left,
                    onPressed: () => setState(() => _rotation = (_rotation - 90) % 360),
                  ),
                  _imageControlButton(
                    icon: Icons.rotate_right,
                    onPressed: () => setState(() => _rotation = (_rotation + 90) % 360),
                  ),
                  _imageControlButton(
                    icon: Icons.flip,
                    onPressed: () => setState(() => _flipH = !_flipH),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 자르기 비율 옵션들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filterChip('원본', _crop == CropPreset.original, () => setState(() => _crop = CropPreset.original)),
                  _filterChip('1:1', _crop == CropPreset.square, () => setState(() => _crop = CropPreset.square)),
                  _filterChip('4:5', _crop == CropPreset.r4x5, () => setState(() => _crop = CropPreset.r4x5)),
                  _filterChip('16:9', _crop == CropPreset.r16x9, () => setState(() => _crop = CropPreset.r16x9)),
                ],
              ),
            ],
          ),
        );
        break;
      case EditorTool.none:
        panel = const SizedBox.shrink();
        break;
    }

    return SafeArea(top: false, child: Padding(padding: const EdgeInsets.only(bottom: 8), child: panel));
  }

  void _reset() {
    setState(() {
      _rotation = 0;
      _flipH = false;
      _brightness = 0.0;
      _blurSigma = 0.0;
      _filter = FilterPreset.none;
      _crop = CropPreset.original;
      _selectedTool = EditorTool.none;
    });
  }

  Future<void> _saveEdits() async {
    final path = _imagePath;
    if (path == null || path.isEmpty) return;
    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    if (isHttp) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editing network images not supported yet. Download first.')),
      );
      return;
    }

    try {
      final bytes = await File(path).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) throw Exception('Unsupported image: $path');

      // 회전
      if (_rotation % 360 != 0) {
        image = img.copyRotate(image, angle: _rotation);
      }
      // 좌우 반전
      if (_flipH) {
        image = img.flipHorizontal(image);
      }
      // 밝기 적용 (-1 ~ 1)
      if (_brightness != 0.0) {
        image = img.adjustColor(image, brightness: _brightness);
      }
      // 필터 적용
      switch (_filter) {
        case FilterPreset.none:
          break;
        case FilterPreset.warm:
          image = img.adjustColor(image, saturation: 0.05, gamma: 0.98);
          image = img.colorOffset(image, red: 10, green: 5, blue: -5);
          break;
        case FilterPreset.cool:
          image = img.adjustColor(image, saturation: 0.0, gamma: 1.02);
          image = img.colorOffset(image, red: -5, green: 0, blue: 8);
          break;
        case FilterPreset.mono:
          image = img.grayscale(image);
          break;
      }
      // 효과(블러)
      if (_blurSigma > 0) {
        final r = _blurSigma.clamp(0, 50).toInt();
        if (r > 0) {
          image = img.gaussianBlur(image, radius: r);
        }
      }
      // 자르기 (중앙 크롭)
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
      setState(() {
        _imagePath = outPath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved edited copy to temp folder.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    }
  }
}

enum EditorTool { none, brightness, effect, filter, crop }

enum FilterPreset { none, warm, cool, mono }

enum CropPreset { original, square, r4x5, r16x9 }

Widget _filterChip(String label, bool selected, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.black : Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );
}

Widget _imageControlButton({required IconData icon, required VoidCallback onPressed}) {
  return GestureDetector(
    onTap: onPressed,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    ),
  );
}

img.Image _centerCropToAspect(img.Image src, int wRatio, int hRatio) {
  final sw = src.width;
  final sh = src.height;
  final target = wRatio / hRatio;
  final srcAspect = sw / sh;
  int x = 0, y = 0, tw = sw, th = sh;
  if (srcAspect > target) {
    // too wide -> crop width
    th = sh;
    tw = (sh * target).round();
    x = ((sw - tw) / 2).round();
    y = 0;
  } else {
    // too tall -> crop height
    tw = sw;
    th = (sw / target).round();
    x = 0;
    y = ((sh - th) / 2).round();
  }
  return img.copyCrop(src, x: x, y: y, width: tw, height: th);
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: selected
            ? (isDark ? Colors.white : Colors.black)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white : Colors.black),
              size: 20,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected
                  ? (isDark ? Colors.black : Colors.white)
                  : (isDark ? Colors.white : Colors.black),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
