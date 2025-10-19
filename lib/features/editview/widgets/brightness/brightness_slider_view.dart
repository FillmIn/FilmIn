import 'package:flutter/material.dart';
import 'brightness_models.dart';

/// 밝기 조정 슬라이더 뷰
class BrightnessSliderView extends StatelessWidget {
  final BrightnessAdjustmentType type;
  final double value;
  final bool isDark;
  final VoidCallback onBack;
  final ValueChanged<double> onValueChanged;

  const BrightnessSliderView({
    super.key,
    required this.type,
    required this.value,
    required this.isDark,
    required this.onBack,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = BrightnessAdjustmentProvider.getLabel(type);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                padding: EdgeInsets.zero,
                onPressed: onBack,
                tooltip: '뒤로',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh, size: 18),
                padding: EdgeInsets.zero,
                onPressed: () => onValueChanged(0.0),
                tooltip: '초기화',
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value: value,
              min: -1.0,
              max: 1.0,
              onChanged: onValueChanged,
            ),
          ),
        ],
      ),
    );
  }
}
