import 'package:flutter/material.dart';

class EffectToolPanel extends StatelessWidget {
  final double blurSigma;
  final ValueChanged<double> onChanged;

  const EffectToolPanel({
    super.key,
    required this.blurSigma,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.blur_off, size: 20),
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
                value: blurSigma,
                min: 0.0,
                max: 10.0,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.blur_on, size: 20),
        ],
      ),
    );
  }
}
