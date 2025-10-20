import 'package:flutter/material.dart';
import 'brightness_models.dart';
import 'brightness_list_view.dart';
import 'brightness_slider_view.dart';

export 'brightness_models.dart';

/// 밝기 조정 도구 패널 - 메인 컨트롤러
class BrightnessToolPanel extends StatefulWidget {
  final BrightnessAdjustments adjustments;
  final bool isProcessing;
  final ValueChanged<BrightnessAdjustments> onChanged;
  final VoidCallback? onAutoAdjust;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;

  const BrightnessToolPanel({
    super.key,
    required this.adjustments,
    this.isProcessing = false,
    required this.onChanged,
    this.onAutoAdjust,
    this.onCancel,
    this.onApply,
  });

  @override
  State<BrightnessToolPanel> createState() => _BrightnessToolPanelState();
}

class _BrightnessToolPanelState extends State<BrightnessToolPanel> {
  BrightnessAdjustmentType? _selectedType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: SafeArea(
        top: false,
        child: _selectedType == null
            ? BrightnessListView(
                adjustments: widget.adjustments,
                isDark: isDark,
                isProcessing: widget.isProcessing,
                onAutoAdjust: widget.onAutoAdjust,
                onCancel: widget.onCancel,
                onApply: widget.onApply,
                onTypeSelected: (type) {
                  setState(() {
                    _selectedType = type;
                  });
                },
              )
            : BrightnessSliderView(
                type: _selectedType!,
                value: BrightnessAdjustmentProvider.getValue(
                  widget.adjustments,
                  _selectedType!,
                ),
                isDark: isDark,
                onBack: () {
                  setState(() {
                    _selectedType = null;
                  });
                },
                onValueChanged: (value) {
                  final updated = BrightnessAdjustmentProvider.updateValue(
                    widget.adjustments,
                    _selectedType!,
                    value,
                  );
                  widget.onChanged(updated);
                },
              ),
      ),
    );
  }
}
