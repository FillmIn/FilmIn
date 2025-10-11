import 'package:flutter/material.dart';

import 'package:filmin/services/filters/lut/lut_filter_service.dart';
import 'package:filmin/services/filters/xmp/shader_xmp_filter_service.dart';

enum FilterPreset { none, warm, cool, mono }

class FilterToolPanel extends StatelessWidget {
  final String? selectedFilter;
  final ValueChanged<String?> onChanged;

  const FilterToolPanel({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeFilters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

        final filters = snapshot.data ?? [];
        debugPrint(
          'FilterToolPanel: Building with ${filters.length} filters',
        );
        debugPrint(
          'FilterToolPanel: Current selected filter: $selectedFilter',
        );

        return Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: '없음',
                  selected: selectedFilter == null,
                  onTap: () {
                    debugPrint('FilterToolPanel: None filter selected');
                    onChanged(null);
                  },
                ),
                const SizedBox(width: 8),
                ...filters.map(
                  (filterName) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: _getDisplayName(filterName),
                      selected: selectedFilter == filterName,
                      onTap: () {
                        debugPrint(
                          'FilterToolPanel: Filter selected: $filterName',
                        );
                        onChanged(filterName);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<String>> _initializeFilters() async {
    debugPrint(
      '🔥 FilterToolPanel: Starting combined filter initialization...',
    );

    final List<String> allFilters = [];

    // XMP 기반 Shader 필터 로드
    final shaderService = ShaderXmpFilterService();
    await shaderService.initialize();
    final xmpFilters = shaderService.getAvailableFilters();
    allFilters.addAll(xmpFilters);
    debugPrint(
      '🔥 FilterToolPanel: Loaded ${xmpFilters.length} XMP filters: $xmpFilters',
    );

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

  String _getDisplayName(String filterName) {
    // XMP 필터 표시명
    if (filterName.contains('PORTRA')) return 'Portra 160';
    if (filterName.contains('Fuji C200')) return 'Fuji C200';
    if (filterName.contains('Cinestill')) return 'Cinestill 800T';

    // LUT 필터 표시명
    if (filterName.contains('F-Log to BT.709')) return 'Fuji F-Log';

    return filterName;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 다크/라이트 모드에 따른 색상 설정
    final backgroundColor = selected
        ? (isDark ? Colors.white : Colors.black)
        : Colors.transparent;
    final textColor = selected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black);
    final borderColor = selected
        ? Colors.transparent
        : (isDark
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.black.withValues(alpha: 0.3));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
