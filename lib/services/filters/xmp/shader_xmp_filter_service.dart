import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShaderXmpFilterService {
  static final ShaderXmpFilterService _instance = ShaderXmpFilterService._internal();
  factory ShaderXmpFilterService() => _instance;
  ShaderXmpFilterService._internal();

  final Map<String, XmpShaderData> _filterCache = {};
  // ignore: unused_field
  ui.FragmentShader? _shader;

  Future<void> initialize() async {
    debugPrint('🔥 ShaderXmpFilterService: INITIALIZING...');

    // Fragment Shader 로드
    try {
      final program = await ui.FragmentProgram.fromAsset('shaders/xmp_filter.frag');
      _shader = program.fragmentShader();
      debugPrint('🔥 Fragment Shader loaded successfully!');
    } catch (e) {
      debugPrint('❌ Failed to load fragment shader: $e');
      return;
    }

    // XMP 데이터 로드
    await _loadXmpFilter('PORTRA 160 #1', 'assets/filters/xmp/PORTRA 160 #1.xmp');
    await _loadXmpFilter('Fuji C200 #1', 'assets/filters/xmp/Fuji C200 #1.xmp');
    await _loadXmpFilter('Cinestill 800T #1', 'assets/filters/xmp/Cinestill 800T #1 (Daylight).xmp');

    debugPrint('🔥 ShaderXmpFilterService: LOADED ${_filterCache.length} filters successfully!');
    for (String filterName in _filterCache.keys) {
      debugPrint('🔥 Available shader filter: $filterName');
    }
  }

  Future<void> _loadXmpFilter(String name, String assetPath) async {
    try {
      debugPrint('🔥 Loading XMP data for shader: $name from $assetPath');
      final xmpContent = await rootBundle.loadString(assetPath);
      final xmpData = _parseXmpData(xmpContent);
      final toneCurveTexture = await _createToneCurveTexture(xmpData);

      _filterCache[name] = XmpShaderData(
        settings: xmpData.settings,
        toneCurve: xmpData.toneCurve,
        toneCurveRed: xmpData.toneCurveRed,
        toneCurveGreen: xmpData.toneCurveGreen,
        toneCurveBlue: xmpData.toneCurveBlue,
        toneCurveTexture: toneCurveTexture,
      );

      debugPrint('🔥 Successfully loaded shader data for: $name');
      debugPrint('🔥 Settings: ${xmpData.settings.toString()}');
    } catch (e) {
      debugPrint('❌ Error loading XMP for shader $name: $e');
    }
  }

  // ToneCurve를 텍스처로 변환
  Future<ui.Image> _createToneCurveTexture(XmpFilterData xmpData) async {
    const int width = 256;
    const int height = 4; // Main, Red, Green, Blue curves

    final Uint8List pixels = Uint8List(width * height * 4); // RGBA

    // Main curve (y=0)
    _fillCurveRow(pixels, width, 0, xmpData.toneCurve, width);

    // Red curve (y=1)
    _fillCurveRow(pixels, width, 1, xmpData.toneCurveRed, width);

    // Green curve (y=2)
    _fillCurveRow(pixels, width, 2, xmpData.toneCurveGreen, width);

    // Blue curve (y=3)
    _fillCurveRow(pixels, width, 3, xmpData.toneCurveBlue, width);

    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  void _fillCurveRow(Uint8List pixels, int width, int row, ToneCurve curve, int imageWidth) {
    for (int x = 0; x < width; x++) {
      final double input = x / (width - 1) * 255.0;
      final double output = _interpolateCurve(curve, input);
      final int pixelIndex = (row * imageWidth + x) * 4;

      final int value = (output / 255.0 * 255).round().clamp(0, 255);
      pixels[pixelIndex] = value;     // R
      pixels[pixelIndex + 1] = value; // G
      pixels[pixelIndex + 2] = value; // B
      pixels[pixelIndex + 3] = 255;   // A
    }
  }

  double _interpolateCurve(ToneCurve curve, double input) {
    if (curve.points.isEmpty) return input;
    if (curve.points.length == 1) return curve.points.first.y.toDouble();

    // 선형 보간
    for (int i = 0; i < curve.points.length - 1; i++) {
      final p1 = curve.points[i];
      final p2 = curve.points[i + 1];

      if (input >= p1.x && input <= p2.x) {
        final t = (input - p1.x) / (p2.x - p1.x);
        return p1.y + t * (p2.y - p1.y);
      }
    }

    // 범위를 벗어난 경우
    if (input < curve.points.first.x) return curve.points.first.y.toDouble();
    return curve.points.last.y.toDouble();
  }

  List<String> getAvailableFilters() {
    return _filterCache.keys.toList();
  }

  // 향상된 ColorFilter 생성 (실제 XMP 데이터 기반)
  ColorFilter? createEnhancedColorFilter(String filterName) {
    final filterData = _filterCache[filterName];
    if (filterData == null) {
      debugPrint('❌ Shader filter data not found: $filterName');
      return null;
    }

    debugPrint('🔥 Creating enhanced color filter for: $filterName');
    final settings = filterData.settings;

    // 향상된 색상 매트릭스 생성 (실제 XMP 데이터 기반)
    return _createAdvancedColorMatrix(settings, filterData);
  }

  // Fragment Shader 지원시 사용할 메소드 (미래용)
  ui.ImageFilter? createShaderFilter(String filterName) {
    debugPrint('🔥 Shader filter requested for: $filterName');
    debugPrint('⚠️ Fragment Shader ImageFilter not yet supported in Flutter');
    debugPrint('📝 Using enhanced ColorFilter as fallback');

    // 현재는 null 반환, 미래에 Fragment Shader 지원시 구현
    return null;
  }

  ColorFilter _createAdvancedColorMatrix(XmpSettings settings, XmpShaderData filterData) {
    // 기본 매트릭스 (단위 행렬)
    List<double> matrix = [
      1, 0, 0, 0, 0, // Red
      0, 1, 0, 0, 0, // Green
      0, 0, 1, 0, 0, // Blue
      0, 0, 0, 1, 0, // Alpha
    ];

    // Exposure 적용 (2^exposure)
    if (settings.exposure != 0.0) {
      final exposureFactor = 1.0 + (settings.exposure * 0.3);
      matrix[0] *= exposureFactor; // R
      matrix[6] *= exposureFactor; // G
      matrix[12] *= exposureFactor; // B
    }

    // Contrast 적용
    if (settings.contrast != 0.0) {
      final contrastFactor = 1.0 + (settings.contrast / 100.0);
      final offset = (1.0 - contrastFactor) * 128.0;

      matrix[0] *= contrastFactor; // R
      matrix[6] *= contrastFactor; // G
      matrix[12] *= contrastFactor; // B
      matrix[4] += offset; // R offset
      matrix[9] += offset; // G offset
      matrix[14] += offset; // B offset
    }

    // Saturation 적용
    if (settings.saturation != 0.0) {
      final satFactor = 1.0 + (settings.saturation / 100.0);
      final lumR = 0.299, lumG = 0.587, lumB = 0.114;
      final sr = (1.0 - satFactor) * lumR;
      final sg = (1.0 - satFactor) * lumG;
      final sb = (1.0 - satFactor) * lumB;

      matrix[0] = sr + satFactor; matrix[1] = sg; matrix[2] = sb;
      matrix[5] = sr; matrix[6] = sg + satFactor; matrix[7] = sb;
      matrix[10] = sr; matrix[11] = sg; matrix[12] = sb + satFactor;
    }

    // Temperature/Tint (White Balance) 간단 적용
    if (settings.temperature != 5500.0) {
      final tempShift = (settings.temperature - 5500.0) / 1000.0;
      matrix[0] += tempShift * 0.05; // 빨간색 증가/감소
      matrix[12] -= tempShift * 0.03; // 파란색 반대 조정
    }

    if (settings.tint != 0.0) {
      final tintShift = settings.tint / 100.0;
      matrix[6] += tintShift * 0.02; // 녹색 조정
    }

    // 개별 색상 채도 조정 (Red 채널 예시)
    if (settings.saturationRed != 0.0) {
      final redSatAdjust = settings.saturationRed / 100.0;
      matrix[0] += redSatAdjust * 0.1;
    }

    debugPrint('🔥 Enhanced color matrix created with XMP data');
    debugPrint('📊 Exposure: ${settings.exposure}, Contrast: ${settings.contrast}');
    debugPrint('📊 Temperature: ${settings.temperature}, Saturation: ${settings.saturation}');

    return ColorFilter.matrix(matrix);
  }

  // XMP 파싱 (기존 코드 재사용)
  XmpFilterData _parseXmpData(String xmpContent) {
    final settings = XmpSettings();
    final toneCurve = ToneCurve();
    final toneCurveRed = ToneCurve();
    final toneCurveGreen = ToneCurve();
    final toneCurveBlue = ToneCurve();

    final lines = xmpContent.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();

      // 기본 설정값들 파싱
      if (line.contains('crs:Exposure2012=')) {
        settings.exposure = _parseValue(line, 'crs:Exposure2012');
      } else if (line.contains('crs:Contrast2012=')) {
        settings.contrast = _parseValue(line, 'crs:Contrast2012');
      } else if (line.contains('crs:Highlights2012=')) {
        settings.highlights = _parseValue(line, 'crs:Highlights2012');
      } else if (line.contains('crs:Shadows2012=')) {
        settings.shadows = _parseValue(line, 'crs:Shadows2012');
      } else if (line.contains('crs:Whites2012=')) {
        settings.whites = _parseValue(line, 'crs:Whites2012');
      } else if (line.contains('crs:Blacks2012=')) {
        settings.blacks = _parseValue(line, 'crs:Blacks2012');
      } else if (line.contains('crs:Vibrance=')) {
        settings.vibrance = _parseValue(line, 'crs:Vibrance');
      } else if (line.contains('crs:Saturation=')) {
        settings.saturation = _parseValue(line, 'crs:Saturation');
      }

      // White Balance
      else if (line.contains('crs:Temperature=')) {
        settings.temperature = _parseValue(line, 'crs:Temperature');
      } else if (line.contains('crs:Tint=')) {
        settings.tint = _parseValue(line, 'crs:Tint');
      }

      // Parametric Curve
      else if (line.contains('crs:ParametricShadows=')) {
        settings.parametricShadows = _parseValue(line, 'crs:ParametricShadows');
      } else if (line.contains('crs:ParametricDarks=')) {
        settings.parametricDarks = _parseValue(line, 'crs:ParametricDarks');
      } else if (line.contains('crs:ParametricLights=')) {
        settings.parametricLights = _parseValue(line, 'crs:ParametricLights');
      } else if (line.contains('crs:ParametricHighlights=')) {
        settings.parametricHighlights = _parseValue(line, 'crs:ParametricHighlights');
      }

      // HSL Saturation Adjustments (8개 색상)
      else if (line.contains('crs:SaturationAdjustmentRed=')) {
        settings.saturationRed = _parseValue(line, 'crs:SaturationAdjustmentRed');
      } else if (line.contains('crs:SaturationAdjustmentOrange=')) {
        settings.saturationOrange = _parseValue(line, 'crs:SaturationAdjustmentOrange');
      } else if (line.contains('crs:SaturationAdjustmentYellow=')) {
        settings.saturationYellow = _parseValue(line, 'crs:SaturationAdjustmentYellow');
      } else if (line.contains('crs:SaturationAdjustmentGreen=')) {
        settings.saturationGreen = _parseValue(line, 'crs:SaturationAdjustmentGreen');
      } else if (line.contains('crs:SaturationAdjustmentAqua=')) {
        settings.saturationAqua = _parseValue(line, 'crs:SaturationAdjustmentAqua');
      } else if (line.contains('crs:SaturationAdjustmentBlue=')) {
        settings.saturationBlue = _parseValue(line, 'crs:SaturationAdjustmentBlue');
      } else if (line.contains('crs:SaturationAdjustmentPurple=')) {
        settings.saturationPurple = _parseValue(line, 'crs:SaturationAdjustmentPurple');
      } else if (line.contains('crs:SaturationAdjustmentMagenta=')) {
        settings.saturationMagenta = _parseValue(line, 'crs:SaturationAdjustmentMagenta');
      }

      // HSL Luminance Adjustments (8개 색상)
      else if (line.contains('crs:LuminanceAdjustmentRed=')) {
        settings.luminanceRed = _parseValue(line, 'crs:LuminanceAdjustmentRed');
      } else if (line.contains('crs:LuminanceAdjustmentOrange=')) {
        settings.luminanceOrange = _parseValue(line, 'crs:LuminanceAdjustmentOrange');
      } else if (line.contains('crs:LuminanceAdjustmentYellow=')) {
        settings.luminanceYellow = _parseValue(line, 'crs:LuminanceAdjustmentYellow');
      } else if (line.contains('crs:LuminanceAdjustmentGreen=')) {
        settings.luminanceGreen = _parseValue(line, 'crs:LuminanceAdjustmentGreen');
      } else if (line.contains('crs:LuminanceAdjustmentAqua=')) {
        settings.luminanceAqua = _parseValue(line, 'crs:LuminanceAdjustmentAqua');
      } else if (line.contains('crs:LuminanceAdjustmentBlue=')) {
        settings.luminanceBlue = _parseValue(line, 'crs:LuminanceAdjustmentBlue');
      } else if (line.contains('crs:LuminanceAdjustmentPurple=')) {
        settings.luminancePurple = _parseValue(line, 'crs:LuminanceAdjustmentPurple');
      } else if (line.contains('crs:LuminanceAdjustmentMagenta=')) {
        settings.luminanceMagenta = _parseValue(line, 'crs:LuminanceAdjustmentMagenta');
      }

      // Split Toning
      else if (line.contains('crs:SplitToningShadowHue=')) {
        settings.splitToningShadowHue = _parseValue(line, 'crs:SplitToningShadowHue');
      } else if (line.contains('crs:SplitToningShadowSaturation=')) {
        settings.splitToningShadowSaturation = _parseValue(line, 'crs:SplitToningShadowSaturation');
      } else if (line.contains('crs:SplitToningHighlightHue=')) {
        settings.splitToningHighlightHue = _parseValue(line, 'crs:SplitToningHighlightHue');
      } else if (line.contains('crs:SplitToningHighlightSaturation=')) {
        settings.splitToningHighlightSaturation = _parseValue(line, 'crs:SplitToningHighlightSaturation');
      }

      // ToneCurve 섹션 파싱
      else if (line.contains('<crs:ToneCurvePV2012>')) {
        i = _parseToneCurveSection(lines, i, toneCurve);
      } else if (line.contains('<crs:ToneCurvePV2012Red>')) {
        i = _parseToneCurveSection(lines, i, toneCurveRed);
      } else if (line.contains('<crs:ToneCurvePV2012Green>')) {
        i = _parseToneCurveSection(lines, i, toneCurveGreen);
      } else if (line.contains('<crs:ToneCurvePV2012Blue>')) {
        i = _parseToneCurveSection(lines, i, toneCurveBlue);
      }
    }

    return XmpFilterData(
      settings: settings,
      toneCurve: toneCurve,
      toneCurveRed: toneCurveRed,
      toneCurveGreen: toneCurveGreen,
      toneCurveBlue: toneCurveBlue,
    );
  }

  int _parseToneCurveSection(List<String> lines, int startIndex, ToneCurve curve) {
    int i = startIndex + 1;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.contains('</rdf:Seq>')) {
        break;
      }
      if (line.contains('<rdf:li>') && line.contains('</rdf:li>')) {
        final pointStr = line.replaceAll('<rdf:li>', '').replaceAll('</rdf:li>', '').trim();
        final parts = pointStr.split(',');
        if (parts.length == 2) {
          final x = int.tryParse(parts[0].trim()) ?? 0;
          final y = int.tryParse(parts[1].trim()) ?? 0;
          curve.points.add(CurvePoint(x, y));
        }
      }
      i++;
    }
    return i;
  }

  double _parseValue(String line, String key) {
    try {
      final parts = line.split('=');
      if (parts.length >= 2) {
        final valueStr = parts[1].replaceAll('"', '').replaceAll('+', '').trim();
        return double.tryParse(valueStr) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error parsing value from line: $line');
    }
    return 0.0;
  }
}

// 데이터 클래스들 (기존 코드와 동일)
class XmpShaderData {
  final XmpSettings settings;
  final ToneCurve toneCurve;
  final ToneCurve toneCurveRed;
  final ToneCurve toneCurveGreen;
  final ToneCurve toneCurveBlue;
  final ui.Image toneCurveTexture;

  XmpShaderData({
    required this.settings,
    required this.toneCurve,
    required this.toneCurveRed,
    required this.toneCurveGreen,
    required this.toneCurveBlue,
    required this.toneCurveTexture,
  });
}

class XmpFilterData {
  final XmpSettings settings;
  final ToneCurve toneCurve;
  final ToneCurve toneCurveRed;
  final ToneCurve toneCurveGreen;
  final ToneCurve toneCurveBlue;

  XmpFilterData({
    required this.settings,
    required this.toneCurve,
    required this.toneCurveRed,
    required this.toneCurveGreen,
    required this.toneCurveBlue,
  });
}

class XmpSettings {
  // Basic adjustments
  double exposure = 0.0;
  double contrast = 0.0;
  double highlights = 0.0;
  double shadows = 0.0;
  double whites = 0.0;
  double blacks = 0.0;
  double vibrance = 0.0;
  double saturation = 0.0;

  // White Balance
  double temperature = 5500.0; // Default daylight
  double tint = 0.0;

  // Parametric Curve
  double parametricShadows = 0.0;
  double parametricDarks = 0.0;
  double parametricLights = 0.0;
  double parametricHighlights = 0.0;

  // HSL 8개 색상별 조정
  double saturationRed = 0.0, saturationOrange = 0.0, saturationYellow = 0.0, saturationGreen = 0.0;
  double saturationAqua = 0.0, saturationBlue = 0.0, saturationPurple = 0.0, saturationMagenta = 0.0;

  double luminanceRed = 0.0, luminanceOrange = 0.0, luminanceYellow = 0.0, luminanceGreen = 0.0;
  double luminanceAqua = 0.0, luminanceBlue = 0.0, luminancePurple = 0.0, luminanceMagenta = 0.0;

  // Split Toning
  double splitToningShadowHue = 0.0;
  double splitToningShadowSaturation = 0.0;
  double splitToningHighlightHue = 0.0;
  double splitToningHighlightSaturation = 0.0;

  @override
  String toString() {
    return 'XmpSettings(exposure: $exposure, contrast: $contrast, temp: $temperature, satRed: $saturationRed, lumRed: $luminanceRed)';
  }
}

class ToneCurve {
  final List<CurvePoint> points = [];
}

class CurvePoint {
  final int x;
  final int y;

  CurvePoint(this.x, this.y);

  @override
  String toString() => '($x, $y)';
}
