import 'package:flutter/material.dart';
import '../features/editview/services/lut_filter_service.dart';
import '../features/editview/widgets/filter/filter_tool.dart';

/// LUT 필터 예제 페이지
///
/// 이 페이지는 LutFilterService와 FilterToolPanel을 사용하여
/// 실시간으로 필터를 미리보고 테스트할 수 있습니다.
class FilterExamplePage extends StatefulWidget {
  const FilterExamplePage({super.key});

  @override
  State<FilterExamplePage> createState() => _FilterExamplePageState();
}

class _FilterExamplePageState extends State<FilterExamplePage> {
  String? selectedFilter;
  double filterIntensity = 1.0;
  final String sampleImagePath = 'assets/images/MainBanner.jpg';

  LutFilterService? _lutService;
  bool _isFiltersInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  Future<void> _initializeFilters() async {
    _lutService = LutFilterService();
    await _lutService!.initialize();

    if (mounted) {
      setState(() {
        _isFiltersInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LUT 필터 예제'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 이미지 미리보기 영역
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildFilteredImage(),
              ),
            ),
          ),

          // 필터 강도 조절
          if (selectedFilter != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        '필터 강도',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '${(filterIntensity * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: filterIntensity,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white.withValues(alpha: 0.3),
                    onChanged: (value) {
                      setState(() {
                        filterIntensity = value;
                      });
                    },
                  ),
                ],
              ),
            ),

          // 필터 정보 표시
          if (selectedFilter != null) ...[
            const SizedBox(height: 8),
            _buildFilterInfo(),
            const SizedBox(height: 16),
          ],

          // 필터 선택 영역
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isFiltersInitialized)
                  FilterToolPanel(
                    selectedFilter: selectedFilter,
                    filterIntensity: filterIntensity,
                    onChanged: (filter) {
                      setState(() {
                        selectedFilter = filter;
                      });
                    },
                    onIntensityChanged: (intensity) {
                      setState(() {
                        filterIntensity = intensity;
                      });
                    },
                  )
                else
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilteredImage() {
    // ColorFilter를 적용한 이미지 표시
    Widget imageWidget = Image.asset(
      sampleImagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey[800],
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  '샘플 이미지를 찾을 수 없습니다',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );

    // LUT 필터 적용
    if (selectedFilter != null && _lutService != null && _isFiltersInitialized) {
      final colorFilter = _lutService!.createLutColorFilter(
        selectedFilter!,
        intensity: filterIntensity,
      );
      if (colorFilter != null) {
        imageWidget = ColorFiltered(
          colorFilter: colorFilter,
          child: imageWidget,
        );
      }
    }

    return imageWidget;
  }

  Widget _buildFilterInfo() {
    if (selectedFilter == null || _lutService == null) {
      return const SizedBox.shrink();
    }

    final lut = _lutService!.getLut(selectedFilter!);

    if (lut == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                selectedFilter!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoItem('타입', '3D LUT'),
              const SizedBox(width: 16),
              _buildInfoItem('크기', '${lut.size}³'),
              const SizedBox(width: 16),
              _buildInfoItem('엔트리', '${lut.entries.length}개'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getFilterDescription(selectedFilter!),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getFilterDescription(String filterName) {
    if (filterName.contains('FUJI_C200')) {
      return 'Fujifilm C200 필름 톤을 재현한 LUT 필터입니다. '
          '따뜻하고 부드러운 색감이 특징입니다.';
    } else if (filterName.contains('F-Log')) {
      return 'Fujifilm F-Log to BT.709 변환 LUT입니다. '
          'Log 포맷 영상을 표준 색 공간으로 변환합니다.';
    }
    return '3D LUT 색상 그레이딩 필터';
  }
}

/// 필터 예제 실행용 메인 함수
void main() {
  runApp(const FilterExampleApp());
}

class FilterExampleApp extends StatelessWidget {
  const FilterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUT Filter Demo',
      theme: ThemeData.dark(),
      home: const FilterExamplePage(),
    );
  }
}
