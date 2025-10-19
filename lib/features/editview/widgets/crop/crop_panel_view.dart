import 'package:flutter/material.dart';
import 'crop_models.dart';

/// 자르기 도구 패널 UI
class CropToolPanel extends StatelessWidget {
  final CropPreset selectedCrop;
  final ValueChanged<CropPreset> onCropChanged;
  final VoidCallback onCancel;
  final VoidCallback onApply;

  const CropToolPanel({
    super.key,
    required this.selectedCrop,
    required this.onCropChanged,
    required this.onCancel,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 자르기 비율 버튼 리스트
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 10),
                  for (final presetInfo in CropPresetProvider.presets) ...[
                    _RatioButton(
                      presetInfo: presetInfo,
                      selected: selectedCrop == presetInfo.preset,
                      onTap: () => onCropChanged(presetInfo.preset),
                    ),
                    const SizedBox(width: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 취소/완료 버튼과 중앙 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: iconColor,
                      size: 22,
                      weight: 300,
                    ),
                    onPressed: onCancel,
                  ),
                  const Spacer(),
                  Text(
                    '편집',
                    style: TextStyle(
                      color: iconColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.check,
                      color: iconColor,
                      size: 22,
                      weight: 300,
                    ),
                    onPressed: onApply,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 자르기 비율 버튼
class _RatioButton extends StatelessWidget {
  final CropPresetInfo presetInfo;
  final bool selected;
  final VoidCallback onTap;

  const _RatioButton({
    required this.presetInfo,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;
    final selectedColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.1);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: selected ? selectedColor : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: switch (presetInfo.preset) {
                CropPreset.original => Icon(
                    Icons.crop_original,
                    color: iconColor,
                    size: 32,
                  ),
                CropPreset.freeform => Icon(
                    Icons.crop_free,
                    color: iconColor,
                    size: 32,
                  ),
                _ => Container(
                    width: presetInfo.iconWidth,
                    height: presetInfo.iconHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: iconColor, width: 2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            presetInfo.label,
            style: TextStyle(
              color: iconColor,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
