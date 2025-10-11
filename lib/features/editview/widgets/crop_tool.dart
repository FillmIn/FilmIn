import 'package:flutter/material.dart';

enum CropPreset { original, square, r4x5, r16x9 }

class CropToolPanel extends StatelessWidget {
  final CropPreset selectedCrop;
  final ValueChanged<CropPreset> onCropChanged;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onFlipHorizontal;

  const CropToolPanel({
    super.key,
    required this.selectedCrop,
    required this.onCropChanged,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onFlipHorizontal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 이미지 조절 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ImageControlButton(
                icon: Icons.rotate_left,
                onPressed: onRotateLeft,
              ),
              _ImageControlButton(
                icon: Icons.rotate_right,
                onPressed: onRotateRight,
              ),
              _ImageControlButton(
                icon: Icons.flip,
                onPressed: onFlipHorizontal,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 자르기 비율 옵션들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _CropChip(
                label: '원본',
                selected: selectedCrop == CropPreset.original,
                onTap: () => onCropChanged(CropPreset.original),
              ),
              _CropChip(
                label: '1:1',
                selected: selectedCrop == CropPreset.square,
                onTap: () => onCropChanged(CropPreset.square),
              ),
              _CropChip(
                label: '4:5',
                selected: selectedCrop == CropPreset.r4x5,
                onTap: () => onCropChanged(CropPreset.r4x5),
              ),
              _CropChip(
                label: '16:9',
                selected: selectedCrop == CropPreset.r16x9,
                onTap: () => onCropChanged(CropPreset.r16x9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ImageControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _ImageControlButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _CropChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CropChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}