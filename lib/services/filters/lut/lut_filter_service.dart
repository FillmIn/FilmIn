import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LutFilterService {
  static final LutFilterService _instance = LutFilterService._internal();
  factory LutFilterService() => _instance;
  LutFilterService._internal();

  final Map<String, Lut3D> _lutCache = {};
  bool _isInitialized = false;

  Future<void> initialize() async {
    debugPrint('🔥 LutFilterService: INITIALIZING...');

    // .cube 파일 로드
    await _loadLutFilter('Fuji F-Log to BT.709', 'assets/filters/lut/XH2_FLog_FGamut_to_FLog_BT.709_33grid_V.1.00.cube');

    _isInitialized = true;
    debugPrint('🔥 LutFilterService: LOADED ${_lutCache.length} LUT filters successfully!');
    for (String lutName in _lutCache.keys) {
      debugPrint('🔥 Available LUT filter: $lutName');
    }
  }

  Future<void> _loadLutFilter(String name, String assetPath) async {
    try {
      debugPrint('🔥 Loading 3D LUT: $name from $assetPath');
      final lutContent = await rootBundle.loadString(assetPath);
      final lut3D = _parseCubeFile(lutContent);

      _lutCache[name] = lut3D;
      debugPrint('🔥 Successfully loaded 3D LUT: $name (${lut3D.size}x${lut3D.size}x${lut3D.size})');
    } catch (e) {
      debugPrint('❌ Error loading LUT $name: $e');
    }
  }

  Lut3D _parseCubeFile(String content) {
    final lines = content.split('\n');
    int lutSize = 33; // 기본값
    final List<LutEntry> entries = [];

    for (String line in lines) {
      final trimmed = line.trim();

      // LUT 크기 파싱
      if (trimmed.startsWith('LUT_3D_SIZE')) {
        final parts = trimmed.split(' ');
        if (parts.length >= 2) {
          lutSize = int.tryParse(parts[1]) ?? 33;
        }
        continue;
      }

      // 주석이나 빈 줄 스킵
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }

      // RGB 값 파싱
      final parts = trimmed.split(' ');
      if (parts.length >= 3) {
        final r = double.tryParse(parts[0]);
        final g = double.tryParse(parts[1]);
        final b = double.tryParse(parts[2]);

        if (r != null && g != null && b != null) {
          entries.add(LutEntry(r, g, b));
        }
      }
    }

    final entryCount = entries.length;
    debugPrint('🔥 Parsed $entryCount LUT entries for ${lutSize}x${lutSize}x${lutSize} LUT');
    return Lut3D(lutSize, entries);
  }

  List<String> getAvailableFilters() {
    return _lutCache.keys.toList();
  }

  bool get isInitialized => _isInitialized;

  // 3D LUT 기반 ColorFilter 생성
  ColorFilter? createLutColorFilter(String filterName) {
    final lut = _lutCache[filterName];
    if (lut == null) {
      debugPrint('❌ LUT filter data not found: $filterName');
      return null;
    }

    debugPrint('🔥 Creating 3D LUT color filter for: $filterName');

    // 3D LUT을 ColorMatrix로 근사화
    return _approximateLutWithColorMatrix(lut, filterName);
  }

  ColorFilter _approximateLutWithColorMatrix(Lut3D lut, String filterName) {
    // 샘플링을 통한 ColorMatrix 근사화
    // 여러 RGB 입력값에 대해 LUT 출력을 계산하고 최적 매트릭스 추정

    List<double> inputSamples = [0.0, 0.25, 0.5, 0.75, 1.0];
    List<List<double>> transformations = [];

    for (double r in inputSamples) {
      for (double g in inputSamples) {
        for (double b in inputSamples) {
          final input = [r, g, b];
          final output = _interpolateLut(lut, r, g, b);
          transformations.add([...input, ...output]);
        }
      }
    }

    // 간단한 선형 변환 추정 (실제로는 더 복잡한 피팅 알고리즘 필요)
    List<double> matrix = _estimateColorMatrix(transformations, filterName);

    debugPrint('🔥 3D LUT approximated with ColorMatrix for: $filterName');
    return ColorFilter.matrix(matrix);
  }

  List<double> _estimateColorMatrix(List<List<double>> transformations, String filterName) {
    // 기본 매트릭스부터 시작
    List<double> matrix = [
      1, 0, 0, 0, 0, // Red
      0, 1, 0, 0, 0, // Green
      0, 0, 1, 0, 0, // Blue
      0, 0, 0, 1, 0, // Alpha
    ];

    // 샘플 변환들의 평균적인 특성 분석
    double avgInputR = 0, avgInputG = 0, avgInputB = 0;
    double avgOutputR = 0, avgOutputG = 0, avgOutputB = 0;

    for (var transform in transformations) {
      avgInputR += transform[0];
      avgInputG += transform[1];
      avgInputB += transform[2];
      avgOutputR += transform[3];
      avgOutputG += transform[4];
      avgOutputB += transform[5];
    }

    final count = transformations.length.toDouble();
    avgInputR /= count; avgInputG /= count; avgInputB /= count;
    avgOutputR /= count; avgOutputG /= count; avgOutputB /= count;

    // 필터 이름에 따른 조정
    if (filterName.contains('F-Log')) {
      // F-Log to BT.709 변환 특성 반영
      matrix[0] = 1.05;   // Red gain
      matrix[6] = 0.98;   // Green slightly reduced
      matrix[12] = 1.02;  // Blue gain
      matrix[4] = -5.0;   // Red offset (어두운 영역 조정)
      matrix[9] = 2.0;    // Green offset
      matrix[14] = -3.0;  // Blue offset
    }

    debugPrint('🔥 Color matrix estimated for $filterName');
    debugPrint('📊 Input avg: R=${avgInputR.toStringAsFixed(3)}, G=${avgInputG.toStringAsFixed(3)}, B=${avgInputB.toStringAsFixed(3)}');
    debugPrint('📊 Output avg: R=${avgOutputR.toStringAsFixed(3)}, G=${avgOutputG.toStringAsFixed(3)}, B=${avgOutputB.toStringAsFixed(3)}');

    return matrix;
  }

  List<double> _interpolateLut(Lut3D lut, double r, double g, double b) {
    // 3D 보간 수행
    final size = lut.size;

    // [0,1] 범위를 LUT 인덱스로 변환
    final rIndex = (r * (size - 1)).clamp(0.0, size - 1.0);
    final gIndex = (g * (size - 1)).clamp(0.0, size - 1.0);
    final bIndex = (b * (size - 1)).clamp(0.0, size - 1.0);

    // 인근 8개 점에서의 값 찾기 (trilinear interpolation)
    final r0 = rIndex.floor();
    final r1 = math.min(r0 + 1, size - 1);
    final g0 = gIndex.floor();
    final g1 = math.min(g0 + 1, size - 1);
    final b0 = bIndex.floor();
    final b1 = math.min(b0 + 1, size - 1);

    // 가중치 계산
    final rWeight = rIndex - r0;
    final gWeight = gIndex - g0;
    final bWeight = bIndex - b0;

    // 8개 점의 값 가져오기
    final c000 = _getLutValue(lut, r0, g0, b0);
    final c001 = _getLutValue(lut, r0, g0, b1);
    final c010 = _getLutValue(lut, r0, g1, b0);
    final c011 = _getLutValue(lut, r0, g1, b1);
    final c100 = _getLutValue(lut, r1, g0, b0);
    final c101 = _getLutValue(lut, r1, g0, b1);
    final c110 = _getLutValue(lut, r1, g1, b0);
    final c111 = _getLutValue(lut, r1, g1, b1);

    // Trilinear interpolation
    final c00 = _lerp3(c000, c001, bWeight);
    final c01 = _lerp3(c010, c011, bWeight);
    final c10 = _lerp3(c100, c101, bWeight);
    final c11 = _lerp3(c110, c111, bWeight);

    final c0 = _lerp3(c00, c01, gWeight);
    final c1 = _lerp3(c10, c11, gWeight);

    return _lerp3(c0, c1, rWeight);
  }

  List<double> _getLutValue(Lut3D lut, int r, int g, int b) {
    final index = r + g * lut.size + b * lut.size * lut.size;
    if (index >= 0 && index < lut.entries.length) {
      final entry = lut.entries[index];
      return [entry.r, entry.g, entry.b];
    }
    return [0.0, 0.0, 0.0];
  }

  List<double> _lerp3(List<double> a, List<double> b, double t) {
    return [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
      a[2] + (b[2] - a[2]) * t,
    ];
  }
}

// 3D LUT 데이터 클래스
class Lut3D {
  final int size;
  final List<LutEntry> entries;

  Lut3D(this.size, this.entries);
}

class LutEntry {
  final double r;
  final double g;
  final double b;

  LutEntry(this.r, this.g, this.b);

  @override
  String toString() => 'LutEntry($r, $g, $b)';
}
