import 'package:flutter/material.dart';
import 'package:filmin/services/filters/lut/lut_filter_service.dart';

import 'filter_list_view.dart';
import 'filter_detail_view.dart';

/// 필터 도구 패널 - 메인 컨트롤러
class FilterToolPanel extends StatefulWidget {
  final String? selectedFilter;
  final double filterIntensity;
  final ValueChanged<String?> onChanged;
  final ValueChanged<double>? onIntensityChanged;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;

  static final Future<List<String>> _filtersFuture = _loadFilters();

  const FilterToolPanel({
    super.key,
    required this.selectedFilter,
    required this.filterIntensity,
    required this.onChanged,
    this.onIntensityChanged,
    this.onCancel,
    this.onApply,
  });

  @override
  State<FilterToolPanel> createState() => _FilterToolPanelState();

  /// 필터 초기화 및 로드
  static Future<List<String>> _loadFilters() async {
    debugPrint('🔥 FilterToolPanel: Starting LUT filter initialization...');

    final List<String> allFilters = [];

    // 3D LUT 기반 필터 로드
    final lutService = LutFilterService();
    await lutService.initialize();
    final lutFilters = lutService.getAvailableFilters();
    allFilters.addAll(lutFilters);
    debugPrint(
      '🔥 FilterToolPanel: Loaded ${lutFilters.length} LUT filters: $lutFilters',
    );

    debugPrint(
      '🔥 FilterToolPanel: Total ${allFilters.length} filters available: $allFilters',
    );
    return allFilters;
  }
}

class _FilterToolPanelState extends State<FilterToolPanel> {
  String? _detailViewFilter; // 상세 화면에 표시 중인 필터

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return FutureBuilder(
      future: FilterToolPanel._filtersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingView(bgColor);
        }

        final filters = snapshot.data ?? const <String>[];

        // 상세 화면이 열려있으면 상세 화면 표시
        if (_detailViewFilter != null) {
          return FilterDetailView(
            filterName: _detailViewFilter!,
            filterIntensity: widget.filterIntensity,
            isDark: isDark,
            bgColor: bgColor,
            onIntensityChanged: widget.onIntensityChanged,
            onBack: _closeDetailView,
            onApply: _applyAndCloseDetailView,
          );
        }

        // 필터 목록 화면
        return FilterListView(
          filters: filters,
          selectedFilter: widget.selectedFilter,
          isDark: isDark,
          bgColor: bgColor,
          onCancel: widget.onCancel,
          onApply: widget.onApply,
          onFilterSelected: _onFilterSelected,
        );
      },
    );
  }

  /// 로딩 화면
  Widget _buildLoadingView(Color bgColor) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: const Center(
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }

  /// 필터 선택 핸들러
  void _onFilterSelected(String? filterName) {
    // 필터 바로 적용
    widget.onChanged(filterName);

    // null이 아니면 상세 화면으로 이동
    if (filterName != null) {
      setState(() {
        _detailViewFilter = filterName;
      });
    }
  }

  /// 상세 화면 닫기
  void _closeDetailView() {
    setState(() {
      _detailViewFilter = null;
    });
  }

  /// 필터 적용하고 상세 화면 닫기
  void _applyAndCloseDetailView() {
    if (_detailViewFilter != null) {
      widget.onChanged(_detailViewFilter);
    }
    setState(() {
      _detailViewFilter = null;
    });
  }
}
