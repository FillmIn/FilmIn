import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class AccurateXmpFilterService {
  static final AccurateXmpFilterService _instance = AccurateXmpFilterService._internal();
  factory AccurateXmpFilterService() => _instance;
  AccurateXmpFilterService._internal();

  final Map<String, XmpFilterSettings> _filterCache = {};

  Future<void> initialize() async {
    debugPrint('AccurateXmpFilterService: Initializing...');
    await _loadXmpFilter('PORTRA 160 #1', 'assets/filters/xmp/PORTRA 160 #1.xmp');
    await _loadXmpFilter('Fuji C200 #1', 'assets/filters/xmp/Fuji C200 #1.xmp');
    await _loadXmpFilter('Cinestill 800T #1', 'assets/filters/xmp/Cinestill 800T #1 (Daylight).xmp');
    debugPrint('AccurateXmpFilterService: Loaded ${_filterCache.length} filters');
  }

  Future<void> _loadXmpFilter(String name, String assetPath) async {
    try {
      debugPrint('Loading XMP filter: $name from $assetPath');
      final xmpContent = await rootBundle.loadString(assetPath);
      final settings = _parseXmpSettings(xmpContent);
      _filterCache[name] = settings;
      debugPrint('Successfully loaded filter: $name');
    } catch (e) {
      debugPrint('Error loading XMP filter $name: $e');
    }
  }

  XmpFilterSettings _parseXmpSettings(String xmpContent) {
    final settings = XmpFilterSettings();
    final lines = xmpContent.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();

      // 기본 설정값들 파싱
      if (trimmedLine.contains('crs:Exposure2012=')) {
        settings.exposure = _parseValue(trimmedLine, 'crs:Exposure2012');
      } else if (trimmedLine.contains('crs:Contrast2012=')) {
        settings.contrast = _parseValue(trimmedLine, 'crs:Contrast2012');
      } else if (trimmedLine.contains('crs:Highlights2012=')) {
        settings.highlights = _parseValue(trimmedLine, 'crs:Highlights2012');
      } else if (trimmedLine.contains('crs:Shadows2012=')) {
        settings.shadows = _parseValue(trimmedLine, 'crs:Shadows2012');
      } else if (trimmedLine.contains('crs:Whites2012=')) {
        settings.whites = _parseValue(trimmedLine, 'crs:Whites2012');
      } else if (trimmedLine.contains('crs:Blacks2012=')) {
        settings.blacks = _parseValue(trimmedLine, 'crs:Blacks2012');
      } else if (trimmedLine.contains('crs:Vibrance=')) {
        settings.vibrance = _parseValue(trimmedLine, 'crs:Vibrance');
      } else if (trimmedLine.contains('crs:Saturation=')) {
        settings.saturation = _parseValue(trimmedLine, 'crs:Saturation');
      }

      // HSL 조정값들 파싱
      else if (trimmedLine.contains('crs:SaturationAdjustmentRed=')) {
        settings.saturationRed = _parseValue(trimmedLine, 'crs:SaturationAdjustmentRed');
      } else if (trimmedLine.contains('crs:SaturationAdjustmentGreen=')) {
        settings.saturationGreen = _parseValue(trimmedLine, 'crs:SaturationAdjustmentGreen');
      } else if (trimmedLine.contains('crs:SaturationAdjustmentBlue=')) {
        settings.saturationBlue = _parseValue(trimmedLine, 'crs:SaturationAdjustmentBlue');
      }

      else if (trimmedLine.contains('crs:LuminanceAdjustmentRed=')) {
        settings.luminanceRed = _parseValue(trimmedLine, 'crs:LuminanceAdjustmentRed');
      } else if (trimmedLine.contains('crs:LuminanceAdjustmentGreen=')) {
        settings.luminanceGreen = _parseValue(trimmedLine, 'crs:LuminanceAdjustmentGreen');
      } else if (trimmedLine.contains('crs:LuminanceAdjustmentBlue=')) {
        settings.luminanceBlue = _parseValue(trimmedLine, 'crs:LuminanceAdjustmentBlue');
      }
    }

    return settings;
  }

  double _parseValue(String line, String key) {
    try {
      final parts = line.split('=');
      if (parts.length == 2) {
        final valueStr = parts[1].replaceAll('"', '').replaceAll('+', '').trim();
        return double.tryParse(valueStr) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error parsing value from line: $line');
    }
    return 0.0;
  }

  List<String> getAvailableFilters() {
    return _filterCache.keys.toList();
  }

  ColorFilter? createColorFilter(String filterName) {
    final settings = _filterCache[filterName];
    if (settings == null) {
      debugPrint('Filter not found: $filterName');
      return null;
    }

    debugPrint('Creating ColorFilter for: $filterName');
    debugPrint('Settings: ${settings.toString()}');

    // XMP 설정값들을 ColorFilter 매트릭스로 변환
    final matrix = _createColorMatrix(settings);
    return ColorFilter.matrix(matrix);
  }

  List<double> _createColorMatrix(XmpFilterSettings settings) {
    // 기본 매트릭스 (항등 매트릭스)
    List<double> matrix = [
      1.0, 0.0, 0.0, 0.0, 0.0,  // Red
      0.0, 1.0, 0.0, 0.0, 0.0,  // Green
      0.0, 0.0, 1.0, 0.0, 0.0,  // Blue
      0.0, 0.0, 0.0, 1.0, 0.0,  // Alpha
    ];

    // 노출 조정
    final exposureFactor = math.pow(2, settings.exposure).toDouble();
    matrix[0] *= exposureFactor;  // Red
    matrix[6] *= exposureFactor;  // Green
    matrix[12] *= exposureFactor; // Blue

    // 대비 조정 (-100 ~ +100 → 0.0 ~ 2.0)
    final contrastFactor = 1.0 + (settings.contrast / 100.0);
    final contrastOffset = (1.0 - contrastFactor) * 128.0;
    matrix[0] *= contrastFactor;
    matrix[6] *= contrastFactor;
    matrix[12] *= contrastFactor;
    matrix[4] += contrastOffset;   // Red offset
    matrix[9] += contrastOffset;   // Green offset
    matrix[14] += contrastOffset;  // Blue offset

    // 채도 조정
    final satFactor = 1.0 + (settings.saturation / 100.0);
    final vibFactor = 1.0 + (settings.vibrance / 100.0);
    final totalSaturation = satFactor * vibFactor;

    // 그레이스케일 가중치
    const double rw = 0.299;
    const double gw = 0.587;
    const double bw = 0.114;

    // 채도 매트릭스 적용
    matrix[0] = rw + (matrix[0] - rw) * totalSaturation;
    matrix[1] = rw - rw * totalSaturation;
    matrix[2] = rw - rw * totalSaturation;

    matrix[5] = gw - gw * totalSaturation;
    matrix[6] = gw + (matrix[6] - gw) * totalSaturation;
    matrix[7] = gw - gw * totalSaturation;

    matrix[10] = bw - bw * totalSaturation;
    matrix[11] = bw - bw * totalSaturation;
    matrix[12] = bw + (matrix[12] - bw) * totalSaturation;

    // 개별 색상 채널 조정
    // Red 채널
    if (settings.saturationRed != 0 || settings.luminanceRed != 0) {
      final redSatAdj = 1.0 + (settings.saturationRed / 100.0);
      final redLumAdj = settings.luminanceRed / 100.0;
      matrix[0] *= redSatAdj;
      matrix[4] += redLumAdj * 25.5; // 밝기 조정
    }

    // Green 채널
    if (settings.saturationGreen != 0 || settings.luminanceGreen != 0) {
      final greenSatAdj = 1.0 + (settings.saturationGreen / 100.0);
      final greenLumAdj = settings.luminanceGreen / 100.0;
      matrix[6] *= greenSatAdj;
      matrix[9] += greenLumAdj * 25.5;
    }

    // Blue 채널
    if (settings.saturationBlue != 0 || settings.luminanceBlue != 0) {
      final blueSatAdj = 1.0 + (settings.saturationBlue / 100.0);
      final blueLumAdj = settings.luminanceBlue / 100.0;
      matrix[12] *= blueSatAdj;
      matrix[14] += blueLumAdj * 25.5;
    }

    // 하이라이트/섀도우 조정 (간단한 근사치)
    final shadowAdj = settings.shadows / 100.0;
    final highlightAdj = settings.highlights / 100.0;

    matrix[4] += shadowAdj * 15.0;    // 섀도우 밝기
    matrix[9] += shadowAdj * 15.0;
    matrix[14] += shadowAdj * 15.0;

    matrix[4] += highlightAdj * 10.0; // 하이라이트 밝기
    matrix[9] += highlightAdj * 10.0;
    matrix[14] += highlightAdj * 10.0;

    return matrix;
  }
}

class XmpFilterSettings {
  double exposure = 0.0;
  double contrast = 0.0;
  double highlights = 0.0;
  double shadows = 0.0;
  double whites = 0.0;
  double blacks = 0.0;
  double vibrance = 0.0;
  double saturation = 0.0;

  // HSL 개별 색상 조정
  double saturationRed = 0.0;
  double saturationGreen = 0.0;
  double saturationBlue = 0.0;
  double luminanceRed = 0.0;
  double luminanceGreen = 0.0;
  double luminanceBlue = 0.0;

  @override
  String toString() {
    return 'XmpFilterSettings(exposure: $exposure, contrast: $contrast, '
           'highlights: $highlights, shadows: $shadows, saturation: $saturation, '
           'vibrance: $vibrance, satRed: $saturationRed, satGreen: $saturationGreen, '
           'satBlue: $saturationBlue, lumRed: $luminanceRed, lumGreen: $luminanceGreen, lumBlue: $luminanceBlue)';
  }
}
