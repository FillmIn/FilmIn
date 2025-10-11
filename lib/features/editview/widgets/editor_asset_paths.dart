String editorGroupAssetPath({
  required bool isDarkMode,
  required int groupNumber,
}) {
  const supportedGroups = {1, 2, 3, 4, 5};
  if (!supportedGroups.contains(groupNumber)) {
    throw ArgumentError.value(
      groupNumber,
      'groupNumber',
      'Unsupported editor group. Expected 1(밝기), 2(효과), 3(필터), 4(자르기), or 5(비교).',
    );
  }

  final folder = isDarkMode ? 'dark' : 'light';
  final prefix = isDarkMode ? 'Dark' : 'Light';
  return 'assets/svg/$folder/${prefix}Group$groupNumber.svg';
}
