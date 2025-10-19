import 'package:flutter/material.dart';
import 'brightness_models.dart';
import '../edit_action_bar.dart';

/// 밝기 조정 리스트 뷰
class BrightnessListView extends StatelessWidget {
  final BrightnessAdjustments adjustments;
  final bool isDark;
  final VoidCallback? onAutoAdjust;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;
  final ValueChanged<BrightnessAdjustmentType> onTypeSelected;

  const BrightnessListView({
    super.key,
    required this.adjustments,
    required this.isDark,
    this.onAutoAdjust,
    this.onCancel,
    this.onApply,
    required this.onTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 10),
              _AutoButton(
                isDark: isDark,
                onTap: onAutoAdjust,
              ),
              const SizedBox(width: 10),
              for (final info in BrightnessAdjustmentProvider.adjustments) ...[
                _AdjustmentButton(
                  info: info,
                  value: BrightnessAdjustmentProvider.getValue(adjustments, info.type),
                  isDark: isDark,
                  onTap: () => onTypeSelected(info.type),
                ),
                const SizedBox(width: 10),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        EditActionBar(
          onCancel: onCancel,
          onApply: onApply,
        ),
      ],
    );
  }
}

/// 자동 조정 버튼
class _AutoButton extends StatelessWidget {
  final bool isDark;
  final VoidCallback? onTap;

  const _AutoButton({
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Icon(
                Icons.auto_awesome_outlined,
                size: 34,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '자동',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// 조정 타입 버튼
class _AdjustmentButton extends StatelessWidget {
  final BrightnessAdjustmentInfo info;
  final double value;
  final bool isDark;
  final VoidCallback onTap;

  const _AdjustmentButton({
    required this.info,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != 0.0;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: hasValue
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white70 : Colors.black54,
                        width: 2,
                      ),
                    )
                  : null,
              child: Icon(
                _getIconForType(info.type, isDark),
                size: 34,
                color: _getIconColor(info.type, hasValue, isDark),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              info.label,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(BrightnessAdjustmentType type, bool isDark) {
    if (type == BrightnessAdjustmentType.whites) {
      return isDark ? Icons.circle : Icons.circle_outlined;
    } else if (type == BrightnessAdjustmentType.blacks) {
      return isDark ? Icons.circle_outlined : Icons.circle;
    }
    return info.icon;
  }

  Color _getIconColor(BrightnessAdjustmentType type, bool hasValue, bool isDark) {
    if (type == BrightnessAdjustmentType.whites ||
        type == BrightnessAdjustmentType.blacks) {
      return hasValue
          ? (isDark ? Colors.white70 : Colors.black54)
          : (isDark ? Colors.white60 : Colors.black45);
    }
    return hasValue
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.white70 : Colors.black54);
  }
}
