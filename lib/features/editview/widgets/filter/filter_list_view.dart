import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/lut_filter_service.dart';
import 'package:image/image.dart' as img;
import 'filter_models.dart';

/// 필터 리스트 뷰 UI
class FilterListView extends StatelessWidget {
  final List<String> filters;
  final String? selectedFilter;
  final String? imagePath;
  final bool isDark;
  final Color bgColor;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;
  final ValueChanged<String?> onFilterSelected;

  const FilterListView({
    super.key,
    required this.filters,
    required this.selectedFilter,
    this.imagePath,
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
                      imagePath: imagePath,
                      isSelected: selectedFilter == null,
                      onTap: () => onFilterSelected(null),
                      isDark: isDark,
                    );
                  }

                  final filterName = filters[index - 1];
                  return _FilterThumbnail(
                    filterName: filterName,
                    displayName: FilterInfoProvider.getDisplayName(filterName),
                    imagePath: imagePath,
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
class _FilterThumbnail extends StatefulWidget {
  final String? filterName;
  final String displayName;
  final String? imagePath;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterThumbnail({
    required this.filterName,
    required this.displayName,
    this.imagePath,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_FilterThumbnail> createState() => _FilterThumbnailState();
}

class _FilterThumbnailState extends State<_FilterThumbnail> {
  img.Image? _thumbnailImage;
  bool _isLoading = false;
  bool _hasStartedLoading = false;

  @override
  void initState() {
    super.initState();
    // 썸네일 로딩을 완전히 비활성화 - 성능 개선을 위해 필터 아이콘만 표시
    // 필요 시 주석 해제하여 썸네일 활성화 가능
    /*
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_hasStartedLoading) {
        _loadThumbnail();
      }
    });
    */
  }

  @override
  void didUpdateWidget(_FilterThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.filterName != widget.filterName) {
      setState(() {
        _thumbnailImage = null;
        _hasStartedLoading = false;
      });
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (widget.imagePath == null || _hasStartedLoading) {
      return;
    }

    setState(() {
      _hasStartedLoading = true;
      _isLoading = true;
    });

    try {
      // 디버그 로그 제거 (성능 향상)

      // 원본 이미지 로드
      final file = File(widget.imagePath!);
      if (!file.existsSync()) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _thumbnailImage = null;
          });
        }
        return;
      }

      final bytes = await file.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _thumbnailImage = null;
          });
        }
        return;
      }

      // 썸네일 크기로 축소 (성능 최적화 - 더 작은 크기로)
      const thumbnailSize = 80; // 작은 썸네일 크기
      if (image.width > thumbnailSize || image.height > thumbnailSize) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? thumbnailSize : null,
          height: image.height >= image.width ? thumbnailSize : null,
        );
      }

      // 필터 적용
      if (widget.filterName != null) {
        final lutService = LutFilterService();

        // LUT 서비스 초기화 확인
        if (!lutService.isInitialized) {
          await lutService.initialize();
        }

        final lut = lutService.getLut(widget.filterName!);
        if (lut != null) {
          image = _applyLutToImage(image, lut);
        }
      }

      if (mounted) {
        setState(() {
          _thumbnailImage = image;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading thumbnail: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _thumbnailImage = null;
        });
      }
    }
  }

  img.Image _applyLutToImage(img.Image image, Lut3D lut) {
    final result = image.clone();

    for (int y = 0; y < result.height; y++) {
      for (int x = 0; x < result.width; x++) {
        final pixel = result.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        // LUT 보간 적용
        final transformed = _interpolateLut(lut, r, g, b);

        result.setPixel(
          x,
          y,
          img.ColorRgba8(
            (transformed[0] * 255).clamp(0, 255).toInt(),
            (transformed[1] * 255).clamp(0, 255).toInt(),
            (transformed[2] * 255).clamp(0, 255).toInt(),
            pixel.a.toInt(),
          ),
        );
      }
    }

    return result;
  }

  List<double> _interpolateLut(Lut3D lut, double r, double g, double b) {
    final size = lut.size;

    final rIndex = (r * (size - 1)).clamp(0.0, size - 1.0);
    final gIndex = (g * (size - 1)).clamp(0.0, size - 1.0);
    final bIndex = (b * (size - 1)).clamp(0.0, size - 1.0);

    final r0 = rIndex.floor();
    final r1 = (r0 + 1).clamp(0, size - 1);
    final g0 = gIndex.floor();
    final g1 = (g0 + 1).clamp(0, size - 1);
    final b0 = bIndex.floor();
    final b1 = (b0 + 1).clamp(0, size - 1);

    final rWeight = rIndex - r0;
    final gWeight = gIndex - g0;
    final bWeight = bIndex - b0;

    final c000 = _getLutValue(lut, r0, g0, b0);
    final c001 = _getLutValue(lut, r0, g0, b1);
    final c010 = _getLutValue(lut, r0, g1, b0);
    final c011 = _getLutValue(lut, r0, g1, b1);
    final c100 = _getLutValue(lut, r1, g0, b0);
    final c101 = _getLutValue(lut, r1, g0, b1);
    final c110 = _getLutValue(lut, r1, g1, b0);
    final c111 = _getLutValue(lut, r1, g1, b1);

    final c00 = _lerp3(c000, c001, bWeight);
    final c01 = _lerp3(c010, c011, bWeight);
    final c10 = _lerp3(c100, c101, bWeight);
    final c11 = _lerp3(c110, c111, bWeight);

    final c0 = _lerp3(c00, c01, gWeight);
    final c1 = _lerp3(c10, c11, gWeight);

    return _lerp3(c0, c1, rWeight);
  }

  List<double> _getLutValue(Lut3D lut, int r, int g, int b) {
    // LUT 인덱스 계산: R이 가장 빠르게 변하고, B가 가장 느리게 변함
    final index = r + g * lut.size + b * lut.size * lut.size;
    if (index >= 0 && index < lut.entries.length) {
      final entry = lut.entries[index];
      return [entry.r, entry.g, entry.b];
    }

    // 범위를 벗어나면 원본 색상 반환
    return [r / (lut.size - 1).toDouble(), g / (lut.size - 1).toDouble(), b / (lut.size - 1).toDouble()];
  }

  List<double> _lerp3(List<double> a, List<double> b, double t) {
    return [
      a[0] + (b[0] - a[0]) * t,
      a[1] + (b[1] - a[1]) * t,
      a[2] + (b[2] - a[2]) * t,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            // 필터 이름
            Text(
              widget.displayName,
              style: TextStyle(
                color: widget.isDark ? Colors.white : Colors.black,
                fontSize: 11,
                fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 썸네일 이미지
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? (widget.isDark
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.1))
                    : (widget.isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05)),
                borderRadius: BorderRadius.circular(8),
                border: widget.isSelected
                    ? Border.all(
                        color: widget.isDark ? Colors.white : Colors.black,
                        width: 2,
                      )
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _thumbnailImage != null
                    ? Image.memory(
                        img.encodeJpg(_thumbnailImage!, quality: 85),
                        fit: BoxFit.cover,
                        width: 80,
                        height: 80,
                      )
                    : (_isLoading
                        ? Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.image,
                            size: 30,
                            color: Colors.grey,
                          )),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
