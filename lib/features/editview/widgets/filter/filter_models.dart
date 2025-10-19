/// 필터 관련 데이터 모델
class FilterInfo {
  final String name;
  final String displayName;
  final String description;

  const FilterInfo({
    required this.name,
    required this.displayName,
    required this.description,
  });
}

/// 필터 정보 제공 클래스
class FilterInfoProvider {
  static String getDisplayName(String filterName) {
    if (filterName.contains('FUJI_C200')) return 'Fuji C200';
    if (filterName.contains('F-Log')) return 'F-Log';
    return filterName;
  }

  static String getDescription(String filterName) {
    if (filterName.contains('FUJI_C200')) {
      return '사진처럼 생생 어렴풋 의미의 분위기를 특징적일수있게 강조하세요';
    }
    if (filterName.contains('F-Log')) {
      return 'Fujifilm F-Log를 BT.709 색 공간으로 변환하는 필터';
    }
    return '3D LUT 색상 그레이딩 필터';
  }

  static FilterInfo getFilterInfo(String filterName) {
    return FilterInfo(
      name: filterName,
      displayName: getDisplayName(filterName),
      description: getDescription(filterName),
    );
  }
}
