import 'package:flutter/material.dart';
import 'filter_models.dart';

/// 필터 상세 뷰 UI
class FilterDetailView extends StatelessWidget {
  final String filterName;
  final double filterIntensity;
  final bool isDark;
  final Color bgColor;
  final ValueChanged<double>? onIntensityChanged;
  final VoidCallback? onBack;
  final VoidCallback? onApply;

  const FilterDetailView({
    super.key,
    required this.filterName,
    required this.filterIntensity,
    required this.isDark,
    required this.bgColor,
    this.onIntensityChanged,
    this.onBack,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final filterInfo = FilterInfoProvider.getFilterInfo(filterName);

    return Container(
      color: bgColor,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // 필터 썸네일과 정보
            _FilterInfoSection(
              filterInfo: filterInfo,
              isDark: isDark,
            ),
            const SizedBox(height: 24),
            // 필터 강도 슬라이더
            _FilterIntensitySlider(
              intensity: filterIntensity,
              isDark: isDark,
              onChanged: onIntensityChanged,
            ),
            const SizedBox(height: 16),
            // 취소/완료 버튼과 중앙 필터 이름
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 중앙 필터 이름
                  Text(
                    filterInfo.displayName,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  // 좌우 버튼
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : Colors.black,
                          size: 22,
                        ),
                        onPressed: onBack,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.check,
                          color: isDark ? Colors.white : Colors.black,
                          size: 22,
                        ),
                        onPressed: onApply,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

/// 필터 정보 섹션
class _FilterInfoSection extends StatelessWidget {
  final FilterInfo filterInfo;
  final bool isDark;

  const _FilterInfoSection({
    required this.filterInfo,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 썸네일
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image,
              size: 40,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          // 필터 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filterInfo.displayName,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  filterInfo.description,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 필터 강도 슬라이더
class _FilterIntensitySlider extends StatelessWidget {
  final double intensity;
  final bool isDark;
  final ValueChanged<double>? onChanged;

  const _FilterIntensitySlider({
    required this.intensity,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            '필터 값',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: isDark ? Colors.white : Colors.black,
                inactiveTrackColor: isDark
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.3),
                thumbColor: isDark ? Colors.white : Colors.black,
                overlayColor: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                trackHeight: 2,
              ),
              child: Slider(
                value: intensity,
                min: 0.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          // 리셋 버튼
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: isDark ? Colors.white : Colors.black,
              size: 20,
            ),
            onPressed: () => onChanged?.call(1.0),
          ),
        ],
      ),
    );
  }
}
