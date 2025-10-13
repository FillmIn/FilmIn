import 'package:flutter/material.dart';
import '../edit_action_bar.dart';

class EffectToolPanel extends StatelessWidget {
  final double blurSigma;
  final ValueChanged<double> onChanged;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;

  const EffectToolPanel({
    super.key,
    required this.blurSigma,
    required this.onChanged,
    this.onCancel,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
            ),
            const SizedBox(height: 16),
            EditActionBar(
              onCancel: onCancel,
              onApply: onApply,
            ),
          ],
        ),
      ),
    );
  }
}
