import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../features/editview/services/lut_filter_service.dart';
import '../features/editview/services/brightness_service.dart';
import '../features/editview/services/film_effects_service.dart';
import '../features/editview/widgets/brightness/brightness_tool.dart';
import '../features/editview/widgets/effect/effect_models.dart';

/// 서비스 통합 테스트 페이지
///
/// 이 페이지는 다음 서비스들을 테스트합니다:
/// 1. BrightnessService - 밝기 조정
/// 2. FilmEffectsService - 그레인, 더스트, 할레이션
/// 3. LutFilterService - LUT 필터
class ServiceTestPage extends StatefulWidget {
  const ServiceTestPage({super.key});

  @override
  State<ServiceTestPage> createState() => _ServiceTestPageState();
}

class _ServiceTestPageState extends State<ServiceTestPage> {
  // 서비스 인스턴스
  final BrightnessService _brightnessService = BrightnessService();
  final FilmEffectsService _filmEffectsService = FilmEffectsService();
  LutFilterService? _lutService;

  // 테스트 상태
  String _testStatus = '준비';
  String _testLog = '';
  bool _isTestRunning = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _testStatus = 'LUT 서비스 초기화 중...';
      _testLog += '🔵 LUT 서비스 초기화 시작\n';
    });

    try {
      _lutService = LutFilterService();
      await _lutService!.initialize();

      setState(() {
        _testStatus = '초기화 완료';
        _testLog += '✅ LUT 서비스 초기화 성공\n';
        _testLog += '✅ 사용 가능한 필터: ${_lutService!.getAvailableFilters().join(", ")}\n\n';
      });
    } catch (e) {
      setState(() {
        _testStatus = '초기화 실패';
        _testLog += '❌ LUT 서비스 초기화 실패: $e\n\n';
      });
    }
  }

  /// 밝기 조정 서비스 테스트
  Future<void> _testBrightnessService() async {
    setState(() {
      _testStatus = '밝기 조정 테스트 중...';
      _testLog += '\n📝 밝기 조정 서비스 테스트\n';
      _testLog += '─────────────────────────\n';
    });

    try {
      // 테스트 이미지 생성 (100x100 회색)
      final testImage = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          testImage.setPixel(x, y, img.ColorRgba8(128, 128, 128, 255));
        }
      }

      // 테스트 조정값
      final adjustments = const BrightnessAdjustments(
        exposure: 0.5,
        contrast: 0.3,
        saturation: 0.2,
        warmth: 0.1,
        highlights: 0.2,
        shadows: -0.1,
        whites: 0.15,
        blacks: -0.15,
      );

      final result = _brightnessService.applyQuick(
        testImage,
        0.2,
        adjustments,
      );

      setState(() {
        _testLog += '✅ Exposure 조정: ${adjustments.exposure}\n';
        _testLog += '✅ Contrast 조정: ${adjustments.contrast}\n';
        _testLog += '✅ Saturation 조정: ${adjustments.saturation}\n';
        _testLog += '✅ Warmth 조정: ${adjustments.warmth}\n';
        _testLog += '✅ Highlights 조정: ${adjustments.highlights}\n';
        _testLog += '✅ Shadows 조정: ${adjustments.shadows}\n';
        _testLog += '✅ Whites 조정: ${adjustments.whites}\n';
        _testLog += '✅ Blacks 조정: ${adjustments.blacks}\n';
        _testLog += '✅ 결과 이미지 크기: ${result.width}x${result.height}\n\n';
      });
    } catch (e) {
      setState(() {
        _testLog += '❌ 밝기 조정 테스트 실패: $e\n\n';
      });
    }
  }

  /// 필름 효과 서비스 테스트
  Future<void> _testFilmEffectsService() async {
    setState(() {
      _testStatus = '필름 효과 테스트 중...';
      _testLog += '\n📝 필름 효과 서비스 테스트\n';
      _testLog += '─────────────────────────\n';
    });

    try {
      // 테스트 이미지 생성 (100x100 흰색)
      final testImage = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          testImage.setPixel(x, y, img.ColorRgba8(255, 255, 255, 255));
        }
      }

      // 1. 그레인 효과 테스트
      _testLog += '🔵 그레인 효과 테스트 시작...\n';
      try {
        final grainResult = await _filmEffectsService.applyGrainEffect(
          testImage.clone(),
          GrainTextures.fujiReala,
          0.5,
        );
        setState(() {
          _testLog += '✅ 그레인 효과 적용 성공: ${GrainTextures.fujiReala}\n';
        });
      } catch (e) {
        setState(() {
          _testLog += '⚠️ 그레인 효과 테스트 실패 (에셋 없음?): $e\n';
        });
      }

      // 2. 더스트 효과 테스트
      _testLog += '🔵 더스트 효과 테스트 시작...\n';
      try {
        final dustResult = await _filmEffectsService.applyDustEffect(
          testImage.clone(),
          DustTextures.vintage1,
          0.5,
        );
        setState(() {
          _testLog += '✅ 더스트 효과 적용 성공: ${DustTextures.vintage1}\n';
        });
      } catch (e) {
        setState(() {
          _testLog += '⚠️ 더스트 효과 테스트 실패 (에셋 없음?): $e\n';
        });
      }

      // 3. 할레이션 효과 테스트
      setState(() {
        _testLog += '🔵 할레이션 효과 테스트 시작...\n';
      });

      final halationResult = _filmEffectsService.applyHalationEffect(
        testImage.clone(),
        0.7,
      );

      setState(() {
        _testLog += '✅ 할레이션 효과 적용 성공\n';
        _testLog += '✅ 결과 이미지 크기: ${halationResult.width}x${halationResult.height}\n\n';
      });
    } catch (e) {
      setState(() {
        _testLog += '❌ 필름 효과 테스트 실패: $e\n\n';
      });
    }
  }

  /// LUT 필터 서비스 테스트
  Future<void> _testLutFilterService() async {
    setState(() {
      _testStatus = 'LUT 필터 테스트 중...';
      _testLog += '\n📝 LUT 필터 서비스 테스트\n';
      _testLog += '─────────────────────────\n';
    });

    if (_lutService == null) {
      setState(() {
        _testLog += '❌ LUT 서비스가 초기화되지 않았습니다\n\n';
      });
      return;
    }

    try {
      final filters = _lutService!.getAvailableFilters();
      setState(() {
        _testLog += '✅ 사용 가능한 필터 수: ${filters.length}\n';
      });

      for (final filterName in filters) {
        final lut = _lutService!.getLut(filterName);
        if (lut != null) {
          setState(() {
            _testLog += '✅ 필터: $filterName\n';
            _testLog += '   - LUT 크기: ${lut.size}x${lut.size}x${lut.size}\n';
            _testLog += '   - 엔트리 수: ${lut.entries.length}\n';
          });

          // ColorFilter 생성 테스트
          final colorFilter = _lutService!.createLutColorFilter(filterName, intensity: 0.8);
          if (colorFilter != null) {
            setState(() {
              _testLog += '   - ColorFilter 생성 성공\n';
            });
          }
        }
      }

      setState(() {
        _testLog += '\n';
      });
    } catch (e) {
      setState(() {
        _testLog += '❌ LUT 필터 테스트 실패: $e\n\n';
      });
    }
  }

  /// 모든 서비스 통합 테스트
  Future<void> _runAllTests() async {
    if (_isTestRunning) return;

    setState(() {
      _isTestRunning = true;
      _testLog = '';
      _testStatus = '전체 테스트 실행 중...';
    });

    await _testBrightnessService();
    await _testFilmEffectsService();
    await _testLutFilterService();

    setState(() {
      _isTestRunning = false;
      _testStatus = '테스트 완료';
      _testLog += '\n✅ 모든 테스트가 완료되었습니다!\n';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('서비스 통합 테스트'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // 상태 표시
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black,
              child: Row(
                children: [
                  Icon(
                    _isTestRunning ? Icons.hourglass_empty : Icons.check_circle,
                    color: _isTestRunning ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _testStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 테스트 버튼
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _testBrightnessService,
                          icon: const Icon(Icons.brightness_6),
                          label: const Text('밝기 조정'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _testFilmEffectsService,
                          icon: const Icon(Icons.grain),
                          label: const Text('필름 효과'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _testLutFilterService,
                          icon: const Icon(Icons.filter),
                          label: const Text('LUT 필터'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isTestRunning ? null : _runAllTests,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('전체 테스트'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 로그 출력
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testLog.isEmpty ? '테스트를 시작하려면 버튼을 눌러주세요.' : _testLog,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 테스트 페이지 실행용 메인 함수
void main() {
  runApp(const ServiceTestApp());
}

class ServiceTestApp extends StatelessWidget {
  const ServiceTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '서비스 테스트',
      theme: ThemeData.dark(),
      home: const ServiceTestPage(),
    );
  }
}
