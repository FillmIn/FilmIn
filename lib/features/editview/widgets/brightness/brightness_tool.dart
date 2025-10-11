import 'package:flutter/material.dart';

class BrightnessToolPanel extends StatelessWidget {
  final double brightness;
  final ValueChanged<double> onChanged;

  const BrightnessToolPanel({
    super.key,
    required this.brightness,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.brightness_6, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 16),
              ),
              child: Slider(
                value: brightness,
                min: -1.0,
                max: 1.0,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.brightness_7, size: 20),
        ],
      ),
    );
  }
}
