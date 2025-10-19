import 'package:flutter/material.dart';
import 'filter_models.dart';

/// 필터 리스트 뷰 UI
class FilterListView extends StatelessWidget {
  final List<String> filters;
  final String? selectedFilter;
  final bool isDark;
  final Color bgColor;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;
  final ValueChanged<String?> onFilterSelected;

  const FilterListView({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.isDark,
    required this.bgColor,
    this.onCancel,
    this.onApply,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // 필터 썸네일 리스트
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filters.length + 1, // +1 for "None" option
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // "없음" 필터
                    return _FilterThumbnail(
                      filterName: null,
                      displayName: 'Original',
                      isSelected: selectedFilter == null,
                      onTap: () => onFilterSelected(null),
                      isDark: isDark,
                    );
                  }

                  final filterName = filters[index - 1];
                  return _FilterThumbnail(
                    filterName: filterName,
                    displayName: FilterInfoProvider.getDisplayName(filterName),
                    isSelected: selectedFilter == filterName,
                    onTap: () => onFilterSelected(filterName),
                    isDark: isDark,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // 취소/완료 버튼과 중앙 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 중앙 텍스트
                  Text(
                    '필터',
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
                        onPressed: onCancel,
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

/// 필터 썸네일 위젯
class _FilterThumbnail extends StatelessWidget {
  final String? filterName;
  final String displayName;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterThumbnail({
    required this.filterName,
    required this.displayName,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // 썸네일 이미지
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.1))
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: isDark ? Colors.white : Colors.black,
                        width: 2,
                      )
                    : null,
              ),
              child: const Icon(
                Icons.image,
                size: 30,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            // 필터 이름
            Text(
              displayName,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
