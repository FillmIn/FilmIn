import 'package:flutter/material.dart';

class SimpleFilterService {
  static final SimpleFilterService _instance = SimpleFilterService._internal();
  factory SimpleFilterService() => _instance;
  SimpleFilterService._internal();

  static const List<FilterData> availableFilters = [
    FilterData(
      name: 'PORTRA 160 #1',
      displayName: 'Portra 160',
      colorMatrix: [
        1.2, 0.1, 0.0, 0, 20,   // 빨간색 강화
        0.05, 1.15, 0.05, 0, 10, // 녹색 약간 강화
        0.0, 0.0, 0.8, 0, -15,   // 파란색 감소 (따뜻한 톤)
        0, 0, 0, 1, 0,
      ],
    ),
    FilterData(
      name: 'Fuji C200 #1',
      displayName: 'Fuji C200',
      colorMatrix: [
        1.1, 0.0, 0.0, 0, 5,    // 빨간색 약간 강화
        0.0, 1.25, 0.0, 0, 15,  // 녹색 강화
        0.0, 0.0, 1.15, 0, 10,  // 파란색 강화 (선명한 색감)
        0, 0, 0, 1, 0,
      ],
    ),
    FilterData(
      name: 'Cinestill 800T #1',
      displayName: 'Cinestill 800T',
      colorMatrix: [
        1.3, 0.1, 0.0, 0, 25,   // 빨간색 강화
        0.1, 1.1, 0.0, 0, 15,   // 녹색 약간 강화
        0.0, 0.0, 0.7, 0, -20,  // 파란색 감소 (영화적 따뜻함)
        0, 0, 0, 1, 0,
      ],
    ),
  ];

  List<FilterData> getFilters() {
    return availableFilters;
  }

  FilterData? getFilterByName(String name) {
    try {
      return availableFilters.firstWhere((filter) => filter.name == name);
    } catch (e) {
      return null;
    }
  }

  ColorFilter? createColorFilter(String filterName) {
    final filter = getFilterByName(filterName);
    if (filter == null) return null;

    debugPrint('Creating ColorFilter for: $filterName');
    return ColorFilter.matrix(filter.colorMatrix);
  }
}

class FilterData {
  final String name;
  final String displayName;
  final List<double> colorMatrix;

  const FilterData({
    required this.name,
    required this.displayName,
    required this.colorMatrix,
  });
}