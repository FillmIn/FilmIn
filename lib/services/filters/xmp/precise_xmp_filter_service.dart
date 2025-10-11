import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class PreciseXmpFilterService {
  static final PreciseXmpFilterService _instance = PreciseXmpFilterService._internal();
  factory PreciseXmpFilterService() => _instance;
  PreciseXmpFilterService._internal();

  final Map<String, XmpFilterData> _filterCache = {};

  Future<void> initialize() async {
    debugPrint('🔥 PreciseXmpFilterService: INITIALIZING...');
    await _loadXmpFilter('PORTRA 160 #1', 'assets/filters/xmp/PORTRA 160 #1.xmp');
    await _loadXmpFilter('Fuji C200 #1', 'assets/filters/xmp/Fuji C200 #1.xmp');
    await _loadXmpFilter('Cinestill 800T #1', 'assets/filters/xmp/Cinestill 800T #1 (Daylight).xmp');
    debugPrint('🔥 PreciseXmpFilterService: LOADED ${_filterCache.length} filters successfully!');
    for (String filterName in _filterCache.keys) {
      debugPrint('🔥 Available filter: $filterName');
    }
  }

  Future<void> _loadXmpFilter(String name, String assetPath) async {
    try {
      debugPrint('🔥 Loading XMP filter: $name from $assetPath');
      final xmpContent = await rootBundle.loadString(assetPath);
      final filterData = _parseXmpData(xmpContent);
      _filterCache[name] = filterData;
      debugPrint('🔥 Successfully loaded filter: $name');
      debugPrint('🔥 Filter settings: ${filterData.settings.toString()}');
      debugPrint('🔥 ToneCurve points: Main=${filterData.toneCurve.points.length}, R=${filterData.toneCurveRed.points.length}, G=${filterData.toneCurveGreen.points.length}, B=${filterData.toneCurveBlue.points.length}');
    } catch (e) {
      debugPrint('❌ Error loading XMP filter $name: $e');
    }
  }

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

      // Texture and Clarity
      else if (line.contains('crs:Texture=')) {
        settings.texture = _parseValue(line, 'crs:Texture');
      } else if (line.contains('crs:Clarity2012=')) {
        settings.clarity = _parseValue(line, 'crs:Clarity2012');
      } else if (line.contains('crs:Dehaze=')) {
        settings.dehaze = _parseValue(line, 'crs:Dehaze');
      }

      // Hue Adjustments (8개 색상)
      else if (line.contains('crs:HueAdjustmentRed=')) {
        settings.hueRed = _parseValue(line, 'crs:HueAdjustmentRed');
      } else if (line.contains('crs:HueAdjustmentOrange=')) {
        settings.hueOrange = _parseValue(line, 'crs:HueAdjustmentOrange');
      } else if (line.contains('crs:HueAdjustmentYellow=')) {
        settings.hueYellow = _parseValue(line, 'crs:HueAdjustmentYellow');
      } else if (line.contains('crs:HueAdjustmentGreen=')) {
        settings.hueGreen = _parseValue(line, 'crs:HueAdjustmentGreen');
      } else if (line.contains('crs:HueAdjustmentAqua=')) {
        settings.hueAqua = _parseValue(line, 'crs:HueAdjustmentAqua');
      } else if (line.contains('crs:HueAdjustmentBlue=')) {
        settings.hueBlue = _parseValue(line, 'crs:HueAdjustmentBlue');
      } else if (line.contains('crs:HueAdjustmentPurple=')) {
        settings.huePurple = _parseValue(line, 'crs:HueAdjustmentPurple');
      } else if (line.contains('crs:HueAdjustmentMagenta=')) {
        settings.hueMagenta = _parseValue(line, 'crs:HueAdjustmentMagenta');
      }

      // Saturation Adjustments (8개 색상)
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

      // Luminance Adjustments (8개 색상)
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
      } else if (line.contains('crs:SplitToningBalance=')) {
        settings.splitToningBalance = _parseValue(line, 'crs:SplitToningBalance');
      }

      // Color Grading
      else if (line.contains('crs:ColorGradeMidtoneHue=')) {
        settings.colorGradeMidtoneHue = _parseValue(line, 'crs:ColorGradeMidtoneHue');
      } else if (line.contains('crs:ColorGradeMidtoneSat=')) {
        settings.colorGradeMidtoneSat = _parseValue(line, 'crs:ColorGradeMidtoneSat');
      } else if (line.contains('crs:ColorGradeShadowLum=')) {
        settings.colorGradeShadowLum = _parseValue(line, 'crs:ColorGradeShadowLum');
      } else if (line.contains('crs:ColorGradeMidtoneLum=')) {
        settings.colorGradeMidtoneLum = _parseValue(line, 'crs:ColorGradeMidtoneLum');
      } else if (line.contains('crs:ColorGradeHighlightLum=')) {
        settings.colorGradeHighlightLum = _parseValue(line, 'crs:ColorGradeHighlightLum');
      } else if (line.contains('crs:ColorGradeGlobalHue=')) {
        settings.colorGradeGlobalHue = _parseValue(line, 'crs:ColorGradeGlobalHue');
      } else if (line.contains('crs:ColorGradeGlobalSat=')) {
        settings.colorGradeGlobalSat = _parseValue(line, 'crs:ColorGradeGlobalSat');
      } else if (line.contains('crs:ColorGradeGlobalLum=')) {
        settings.colorGradeGlobalLum = _parseValue(line, 'crs:ColorGradeGlobalLum');
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

  List<String> getAvailableFilters() {
    return _filterCache.keys.toList();
  }

  ColorFilter? createColorFilter(String filterName) {
    final filterData = _filterCache[filterName];
    if (filterData == null) {
      debugPrint('❌ Filter not found: $filterName');
      return null;
    }

    debugPrint('🔥 Creating precise ColorFilter for: $filterName');
    debugPrint('🔥 Using XMP data: ${filterData.settings.toString()}');

    // 고급 색상 처리 알고리즘 사용
    final matrix = _createPreciseColorMatrix(filterData);
    debugPrint('🔥 Generated ColorFilter matrix (first 10 values): ${matrix.take(10).toList()}');
    return ColorFilter.matrix(matrix);
  }

  // 새로운 ImageFilter 생성 메서드 (더 정확한 필터링을 위해)
  /*
  ui.ImageFilter? createImageFilter(String filterName) {
    final filterData = _filterCache[filterName];
    if (filterData == null) {
      debugPrint('❌ ImageFilter not found: $filterName');
      return null;
    }

    debugPrint('🔥 Creating precise ImageFilter for: $filterName');

    // 여러 ImageFilter를 조합
    List<ui.ImageFilter> filters = [];

    // 1. ColorFilter 기반 기본 조정
    final colorMatrix = _createPreciseColorMatrix(filterData);
    filters.add(ui.ImageFilter.matrix(colorMatrix));

    // 2. ToneCurve를 위한 추가 처리 (근사치)
    if (filterData.toneCurve.points.isNotEmpty) {
      // 강화된 대비 효과로 ToneCurve 시뮬레이션
      final curveIntensity = _calculateCurveIntensity(filterData.toneCurve);
      if (curveIntensity > 0.1) {
        final contrastMatrix = [
          1.0 + curveIntensity, 0.0, 0.0, 0.0, 0.0,
          0.0, 1.0 + curveIntensity, 0.0, 0.0, 0.0,
          0.0, 0.0, 1.0 + curveIntensity, 0.0, 0.0,
          0.0, 0.0, 0.0, 1.0, 0.0,
        ];
        filters.add(ui.ImageFilter.matrix(contrastMatrix));
      }
    }

    // 모든 필터를 조합
    if (filters.isEmpty) return null;
    if (filters.length == 1) return filters.first;

    return filters.reduce((a, b) => ui.ImageFilter.compose(outer: a, inner: b));
  }
  */

  double _calculateCurveIntensity(ToneCurve curve) {
    if (curve.points.length < 2) return 0.0;

    // 커브의 변화량을 계산해서 강도 결정
    double totalDeviation = 0.0;
    for (final point in curve.points) {
      final expectedY = point.x; // 선형이면 x == y
      final actualY = point.y;
      totalDeviation += (actualY - expectedY).abs();
    }

    return (totalDeviation / curve.points.length) / 255.0; // 0.0 ~ 1.0 범위로 정규화
  }

  List<double> _createPreciseColorMatrix(XmpFilterData filterData) {
    final settings = filterData.settings;

    // 1. 기본 항등 매트릭스
    List<double> matrix = [
      1.0, 0.0, 0.0, 0.0, 0.0,  // Red
      0.0, 1.0, 0.0, 0.0, 0.0,  // Green
      0.0, 0.0, 1.0, 0.0, 0.0,  // Blue
      0.0, 0.0, 0.0, 1.0, 0.0,  // Alpha
    ];

    // 2. 노출 조정 (실제 2^exposure 공식 사용)
    final exposureFactor = math.pow(2, settings.exposure).toDouble();
    matrix[0] *= exposureFactor;  // Red
    matrix[6] *= exposureFactor;  // Green
    matrix[12] *= exposureFactor; // Blue

    // 3. ToneCurve 적용 (가장 중요한 부분)
    final toneCurveMatrix = _createToneCurveMatrix(filterData);
    matrix = _multiplyMatrices(matrix, toneCurveMatrix);

    // 4. 대비 조정 (Adobe의 실제 공식 근사)
    final contrastFactor = 1.0 + (settings.contrast / 50.0); // Adobe 스케일 조정
    final contrastMidpoint = 0.5;
    final contrastOffset = contrastMidpoint * (1.0 - contrastFactor);

    matrix[0] *= contrastFactor;
    matrix[6] *= contrastFactor;
    matrix[12] *= contrastFactor;
    matrix[4] += contrastOffset * 255;
    matrix[9] += contrastOffset * 255;
    matrix[14] += contrastOffset * 255;

    // 5. 하이라이트/섀도우 세밀 조정
    final shadowLift = settings.shadows / 100.0;
    final highlightCompress = settings.highlights / 100.0;

    // 섀도우 리프트 (어두운 영역 밝게)
    matrix[4] += shadowLift * 30.0;
    matrix[9] += shadowLift * 30.0;
    matrix[14] += shadowLift * 30.0;

    // 하이라이트 압축 (밝은 영역 어둡게)
    matrix[4] += highlightCompress * 15.0;
    matrix[9] += highlightCompress * 15.0;
    matrix[14] += highlightCompress * 15.0;

    // 6. 화이트/블랙 포인트 조정
    final whitesFactor = 1.0 + (settings.whites / 200.0);
    final blacksOffset = settings.blacks / 100.0 * 25.5;

    matrix[0] *= whitesFactor;
    matrix[6] *= whitesFactor;
    matrix[12] *= whitesFactor;
    matrix[4] += blacksOffset;
    matrix[9] += blacksOffset;
    matrix[14] += blacksOffset;

    // 7. 채도/비브란스 고급 처리
    final satMatrix = _createSaturationMatrix(settings.saturation, settings.vibrance);
    matrix = _multiplyMatrices(matrix, satMatrix);

    // 8. 화이트 밸런스 조정
    final wbMatrix = _createWhiteBalanceMatrix(settings.temperature, settings.tint);
    matrix = _multiplyMatrices(matrix, wbMatrix);

    // 9. Parametric Curve 조정
    final parametricMatrix = _createParametricMatrix(settings);
    matrix = _multiplyMatrices(matrix, parametricMatrix);

    // 10. 개별 색상 채널 HSL 조정 (8개 색상 모두)
    final hslMatrix = _createCompleteHSLMatrix(settings);
    matrix = _multiplyMatrices(matrix, hslMatrix);

    // 11. Split Toning 적용
    final splitMatrix = _createSplitToningMatrix(settings);
    matrix = _multiplyMatrices(matrix, splitMatrix);

    // 12. Color Grading 적용
    final gradingMatrix = _createColorGradingMatrix(settings);
    matrix = _multiplyMatrices(matrix, gradingMatrix);

    // 13. Texture, Clarity, Dehaze 효과
    final effectsMatrix = _createEffectsMatrix(settings);
    matrix = _multiplyMatrices(matrix, effectsMatrix);

    // 9. 값 클램핑 및 정규화
    for (int i = 0; i < matrix.length; i++) {
      if (i % 5 == 4) { // 오프셋 값들
        matrix[i] = matrix[i].clamp(-255.0, 255.0);
      } else { // 스케일 값들
        matrix[i] = matrix[i].clamp(0.0, 3.0);
      }
    }

    return matrix;
  }

  List<double> _createToneCurveMatrix(XmpFilterData filterData) {
    // ToneCurve를 더 정확하게 분석해서 매트릭스 생성
    final mainCurve = filterData.toneCurve;
    final redCurve = filterData.toneCurveRed;
    final greenCurve = filterData.toneCurveGreen;
    final blueCurve = filterData.toneCurveBlue;

    debugPrint('🔥 ToneCurve Analysis:');
    debugPrint('🔥 Main curve points: ${mainCurve.points.map((p) => '(${p.x},${p.y})').join(', ')}');
    debugPrint('🔥 Red curve points: ${redCurve.points.map((p) => '(${p.x},${p.y})').join(', ')}');
    debugPrint('🔥 Green curve points: ${greenCurve.points.map((p) => '(${p.x},${p.y})').join(', ')}');
    debugPrint('🔥 Blue curve points: ${blueCurve.points.map((p) => '(${p.x},${p.y})').join(', ')}');

    // 각 커브의 특성을 더 정확히 분석
    final redAdjust = _calculateAdvancedCurveAdjustment(redCurve, mainCurve);
    final greenAdjust = _calculateAdvancedCurveAdjustment(greenCurve, mainCurve);
    final blueAdjust = _calculateAdvancedCurveAdjustment(blueCurve, mainCurve);

    debugPrint('🔥 Curve adjustments - R: ${redAdjust.scale}/${redAdjust.offset}, G: ${greenAdjust.scale}/${greenAdjust.offset}, B: ${blueAdjust.scale}/${blueAdjust.offset}');

    return [
      redAdjust.scale, 0.0, 0.0, 0.0, redAdjust.offset,
      0.0, greenAdjust.scale, 0.0, 0.0, greenAdjust.offset,
      0.0, 0.0, blueAdjust.scale, 0.0, blueAdjust.offset,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  CurveAdjustment _calculateAdvancedCurveAdjustment(ToneCurve curve, ToneCurve mainCurve) {
    if (curve.points.isEmpty) {
      return CurveAdjustment(scale: 1.0, offset: 0.0);
    }

    // 더 정교한 커브 분석: 여러 구간의 평균 기울기 계산
    double totalScale = 0.0;
    double totalOffset = 0.0;
    int validSegments = 0;

    // 커브를 여러 구간으로 나누어 분석
    for (int i = 0; i < curve.points.length - 1; i++) {
      final p1 = curve.points[i];
      final p2 = curve.points[i + 1];

      if (p2.x != p1.x) {
        final segmentScale = (p2.y - p1.y) / (p2.x - p1.x);
        final segmentOffset = p1.y - p1.x * segmentScale;

        // 가중치 적용 (중간 톤 영역에 더 높은 가중치)
        final midPoint = (p1.x + p2.x) / 2;
        final weight = _calculateTonalWeight(midPoint);

        totalScale += segmentScale * weight;
        totalOffset += segmentOffset * weight;
        validSegments++;
      }
    }

    if (validSegments == 0) {
      return CurveAdjustment(scale: 1.0, offset: 0.0);
    }

    final avgScale = totalScale / validSegments;
    final avgOffset = totalOffset / validSegments;

    // Main curve와의 차이도 고려
    double mainCurveInfluence = 1.0;
    if (mainCurve.points.isNotEmpty) {
      final mainIntensity = _calculateCurveIntensity(mainCurve);
      mainCurveInfluence = 1.0 + (mainIntensity * 0.5); // Main curve 강도의 50% 반영
    }

    return CurveAdjustment(
      scale: (avgScale * mainCurveInfluence).clamp(0.3, 3.0),
      offset: (avgOffset * mainCurveInfluence).clamp(-100.0, 100.0)
    );
  }

  double _calculateTonalWeight(double toneValue) {
    // 중간 톤(128 주변)에 더 높은 가중치 부여
    final normalizedTone = toneValue / 255.0;
    final distanceFromMidtone = (normalizedTone - 0.5).abs();
    return 1.0 - (distanceFromMidtone * 0.5); // 중간톤은 1.0, 극값은 0.75
  }

  List<double> _createSaturationMatrix(double saturation, double vibrance) {
    final totalSat = 1.0 + ((saturation + vibrance) / 100.0);

    // 정확한 채도 매트릭스 (ITU-R BT.709 가중치 사용)
    const double rw = 0.2126;
    const double gw = 0.7152;
    const double bw = 0.0722;

    final sr = rw * (1.0 - totalSat);
    final sg = gw * (1.0 - totalSat);
    final sb = bw * (1.0 - totalSat);

    return [
      sr + totalSat, sg, sb, 0.0, 0.0,
      sr, sg + totalSat, sb, 0.0, 0.0,
      sr, sg, sb + totalSat, 0.0, 0.0,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  List<double> _createWhiteBalanceMatrix(double temperature, double tint) {
    // 화이트 밸런스 조정 (간단한 근사치)
    // Temperature: 차가운(높은 값) vs 따뜻한(낮은 값)
    // Tint: 녹색(음수) vs 마젠타(양수)

    final tempFactor = (temperature - 5500) / 1000.0; // 표준 5500K 기준
    final tintFactor = tint / 100.0;

    return [
      1.0 + (tempFactor * 0.1), 0.0, 0.0, 0.0, tempFactor * 10,
      0.0, 1.0 + (tintFactor * 0.05), 0.0, 0.0, -tintFactor * 5,
      1.0 - (tempFactor * 0.1), 0.0, 1.0, 0.0, -tempFactor * 5,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  List<double> _createParametricMatrix(XmpSettings settings) {
    // Parametric Curve 조정
    final shadowAdj = settings.parametricShadows / 100.0;
    final darkAdj = settings.parametricDarks / 100.0;
    final lightAdj = settings.parametricLights / 100.0;
    final highlightAdj = settings.parametricHighlights / 100.0;
    final highlightOffset = highlightAdj * 10;

    return [
      1.0 + (lightAdj * 0.02), 0.0, 0.0, 0.0, (shadowAdj + darkAdj) * 10 + highlightOffset,
      0.0, 1.0 + (lightAdj * 0.02), 0.0, 0.0, (shadowAdj + darkAdj) * 10 + highlightOffset,
      0.0, 0.0, 1.0 + (lightAdj * 0.02), 0.0, (shadowAdj + darkAdj) * 10 + highlightOffset,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  List<double> _createCompleteHSLMatrix(XmpSettings settings) {
    // 8개 색상 채널의 HSL 조정을 종합적으로 적용
    // 실제로는 각 색상 영역별로 가중치를 적용해야 하지만, 여기서는 대표 색상들로 근사

    final redFactor = 1.0 + ((settings.saturationRed + settings.saturationOrange) / 200.0);
    final greenFactor = 1.0 + ((settings.saturationGreen + settings.saturationYellow) / 200.0);
    final blueFactor = 1.0 + ((settings.saturationBlue + settings.saturationAqua + settings.saturationPurple) / 300.0);

    final redOffset = (settings.luminanceRed + settings.luminanceOrange) * 0.15;
    final greenOffset = (settings.luminanceGreen + settings.luminanceYellow) * 0.15;
    final blueOffset = (settings.luminanceBlue + settings.luminanceAqua + settings.luminancePurple) * 0.1;

    return [
      redFactor, 0.0, 0.0, 0.0, redOffset,
      0.0, greenFactor, 0.0, 0.0, greenOffset,
      0.0, 0.0, blueFactor, 0.0, blueOffset,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  List<double> _createSplitToningMatrix(XmpSettings settings) {
    // Split Toning 효과
    final shadowHue = settings.splitToningShadowHue;
    final shadowSat = settings.splitToningShadowSaturation / 100.0;
    final highlightHue = settings.splitToningHighlightHue;
    final highlightSat = settings.splitToningHighlightSaturation / 100.0;

    // Hue를 RGB로 변환하는 간단한 근사치
    final shadowR = math.cos(shadowHue * math.pi / 180) * shadowSat * 0.1;
    final shadowG = math.cos((shadowHue + 120) * math.pi / 180) * shadowSat * 0.1;
    final shadowB = math.cos((shadowHue + 240) * math.pi / 180) * shadowSat * 0.1;

    final highlightR = math.cos(highlightHue * math.pi / 180) * highlightSat * 0.1;
    final highlightG = math.cos((highlightHue + 120) * math.pi / 180) * highlightSat * 0.1;
    final highlightB = math.cos((highlightHue + 240) * math.pi / 180) * highlightSat * 0.1;

    return [
      1.0 + shadowR + highlightR, 0.0, 0.0, 0.0, (shadowR + highlightR) * 25,
      0.0, 1.0 + shadowG + highlightG, 0.0, 0.0, (shadowG + highlightG) * 25,
      0.0, 0.0, 1.0 + shadowB + highlightB, 0.0, (shadowB + highlightB) * 25,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  List<double> _createColorGradingMatrix(XmpSettings settings) {
    // Color Grading 조정
    final globalSat = settings.colorGradeGlobalSat / 100.0;
    final globalLum = settings.colorGradeGlobalLum / 100.0;

    final satFactor = 1.0 + globalSat;
    final lumOffset = globalLum * 20;

    return [
      satFactor, 0.0, 0.0, 0.0, lumOffset,
      0.0, satFactor, 0.0, 0.0, lumOffset,
      0.0, 0.0, satFactor, 0.0, lumOffset,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  List<double> _createEffectsMatrix(XmpSettings settings) {
    // Texture, Clarity, Dehaze 효과
    final texture = settings.texture / 100.0;
    final clarity = settings.clarity / 100.0;
    final dehaze = settings.dehaze / 100.0;

    final effectFactor = 1.0 + (clarity + dehaze) * 0.05;
    final textureOffset = texture * 5;

    return [
      effectFactor, 0.0, 0.0, 0.0, textureOffset,
      0.0, effectFactor, 0.0, 0.0, textureOffset,
      0.0, 0.0, effectFactor, 0.0, textureOffset,
      0.0, 0.0, 0.0, 1.0, 0.0,
    ];
  }

  List<double> _multiplyMatrices(List<double> a, List<double> b) {
    // 4x5 매트릭스 곱셈 (ColorFilter 형태)
    List<double> result = List.filled(20, 0.0);

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 5; col++) {
        double sum = 0.0;
        if (col < 4) {
          for (int k = 0; k < 4; k++) {
            sum += a[row * 5 + k] * b[k * 5 + col];
          }
        } else {
          // 오프셋 열 처리
          for (int k = 0; k < 4; k++) {
            sum += a[row * 5 + k] * b[k * 5 + 4];
          }
          sum += a[row * 5 + 4];
        }
        result[row * 5 + col] = sum;
      }
    }

    return result;
  }
}

// 데이터 클래스들
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
  double temperature = 0.0;
  double tint = 0.0;

  // Parametric Curve
  double parametricShadows = 0.0;
  double parametricDarks = 0.0;
  double parametricLights = 0.0;
  double parametricHighlights = 0.0;

  // Texture and Clarity
  double texture = 0.0;
  double clarity = 0.0;
  double dehaze = 0.0;

  // HSL 8개 색상별 조정 (Red, Orange, Yellow, Green, Aqua, Blue, Purple, Magenta)
  double hueRed = 0.0, hueOrange = 0.0, hueYellow = 0.0, hueGreen = 0.0;
  double hueAqua = 0.0, hueBlue = 0.0, huePurple = 0.0, hueMagenta = 0.0;

  double saturationRed = 0.0, saturationOrange = 0.0, saturationYellow = 0.0, saturationGreen = 0.0;
  double saturationAqua = 0.0, saturationBlue = 0.0, saturationPurple = 0.0, saturationMagenta = 0.0;

  double luminanceRed = 0.0, luminanceOrange = 0.0, luminanceYellow = 0.0, luminanceGreen = 0.0;
  double luminanceAqua = 0.0, luminanceBlue = 0.0, luminancePurple = 0.0, luminanceMagenta = 0.0;

  // Split Toning
  double splitToningShadowHue = 0.0;
  double splitToningShadowSaturation = 0.0;
  double splitToningHighlightHue = 0.0;
  double splitToningHighlightSaturation = 0.0;
  double splitToningBalance = 0.0;

  // Color Grading
  double colorGradeMidtoneHue = 0.0;
  double colorGradeMidtoneSat = 0.0;
  double colorGradeShadowLum = 0.0;
  double colorGradeMidtoneLum = 0.0;
  double colorGradeHighlightLum = 0.0;
  double colorGradeGlobalHue = 0.0;
  double colorGradeGlobalSat = 0.0;
  double colorGradeGlobalLum = 0.0;

  @override
  String toString() {
    return 'XmpSettings(\n'
           '  Basic: exposure=$exposure, contrast=$contrast, highlights=$highlights, shadows=$shadows\n'
           '  WhiteBalance: temp=$temperature, tint=$tint\n'
           '  Parametric: shadows=$parametricShadows, darks=$parametricDarks, lights=$parametricLights, highlights=$parametricHighlights\n'
           '  HSL Red: hue=$hueRed, sat=$saturationRed, lum=$luminanceRed\n'
           '  HSL Green: hue=$hueGreen, sat=$saturationGreen, lum=$luminanceGreen\n'
           '  HSL Blue: hue=$hueBlue, sat=$saturationBlue, lum=$luminanceBlue\n'
           '  Split Toning: shadowHue=$splitToningShadowHue, shadowSat=$splitToningShadowSaturation\n'
           ')';
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

class CurveAdjustment {
  final double scale;
  final double offset;

  CurveAdjustment({required this.scale, required this.offset});
}
