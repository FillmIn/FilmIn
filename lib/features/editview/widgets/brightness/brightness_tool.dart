import 'package:flutter/material.dart';
import '../edit_action_bar.dart';

enum BrightnessAdjustmentType {
  exposure,      // 노출
  contrast,      // 대비
  highlights,    // 밝은영역
  shadows,       // 어두운영역
  whites,        // 흰색계열
  blacks,        // 검정계열
  saturation,    // 채도
  warmth,        // 따듯함
  sharpness,     // 선명도
  noiseReduction // 노이즈 감소
}

class BrightnessAdjustments {
  final double exposure;
  final double contrast;
  final double highlights;
  final double shadows;
  final double whites;
  final double blacks;
  final double saturation;
  final double warmth;
  final double sharpness;
  final double noiseReduction;

  const BrightnessAdjustments({
    this.exposure = 0.0,
    this.contrast = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.whites = 0.0,
    this.blacks = 0.0,
    this.saturation = 0.0,
    this.warmth = 0.0,
    this.sharpness = 0.0,
    this.noiseReduction = 0.0,
  });

  BrightnessAdjustments copyWith({
    double? exposure,
    double? contrast,
    double? highlights,
    double? shadows,
    double? whites,
    double? blacks,
    double? saturation,
    double? warmth,
    double? sharpness,
    double? noiseReduction,
  }) {
    return BrightnessAdjustments(
      exposure: exposure ?? this.exposure,
      contrast: contrast ?? this.contrast,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      whites: whites ?? this.whites,
      blacks: blacks ?? this.blacks,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      sharpness: sharpness ?? this.sharpness,
      noiseReduction: noiseReduction ?? this.noiseReduction,
    );
  }
}

class BrightnessToolPanel extends StatefulWidget {
  final BrightnessAdjustments adjustments;
  final ValueChanged<BrightnessAdjustments> onChanged;
  final VoidCallback? onAutoAdjust;
  final VoidCallback? onCancel;
  final VoidCallback? onApply;

  const BrightnessToolPanel({
    super.key,
    required this.adjustments,
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
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 10),
                        _buildAutoButton(isDark),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.exposure,
                          '노출',
                          Icons.brightness_6_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.contrast,
                          '대비',
                          Icons.tonality_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.highlights,
                          '밝은영역',
                          Icons.light_mode_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.shadows,
                          '어두운영역',
                          Icons.nightlight_round_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.whites,
                          '흰색계열',
                          Icons.circle,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.blacks,
                          '검정계열',
                          Icons.circle_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.saturation,
                          '채도',
                          Icons.water_drop_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.warmth,
                          '따듯함',
                          Icons.wb_twilight_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.sharpness,
                          '선명도',
                          Icons.details_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                        _buildAdjustmentButton(
                          BrightnessAdjustmentType.noiseReduction,
                          '노이즈 감소',
                          Icons.blur_on_outlined,
                          isDark,
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  EditActionBar(
                    onCancel: widget.onCancel,
                    onApply: widget.onApply,
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSlider(_selectedType!, isDark),
              ),
      ),
    );
  }

  Widget _buildAutoButton(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () {
        if (widget.onAutoAdjust != null) {
          widget.onAutoAdjust!();
        }
      },
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

  Widget _buildAdjustmentButton(
    BrightnessAdjustmentType type,
    String label,
    IconData icon,
    bool isDark,
  ) {
    final value = _getValueForType(type);
    final hasValue = value != 0.0;
    final textColor = isDark ? Colors.white : Colors.black;

    // 흰색계열/검정계열은 모드에 따라 다른 아이콘 사용
    IconData getIconForType() {
      if (type == BrightnessAdjustmentType.whites) {
        // 흰색계열: 다크모드에서는 채움, 라이트모드에서는 테두리만
        return isDark ? Icons.circle : Icons.circle_outlined;
      } else if (type == BrightnessAdjustmentType.blacks) {
        // 검정계열: 다크모드에서는 테두리만, 라이트모드에서는 채움
        return isDark ? Icons.circle_outlined : Icons.circle;
      } else {
        return icon;
      }
    }

    // 흰색계열/검정계열 아이콘의 색상을 다르게 처리
    Color getIconColor() {
      if (type == BrightnessAdjustmentType.whites) {
        // 흰색계열: 밝은 회색으로 채움
        return hasValue
            ? (isDark ? Colors.white70 : Colors.black54)
            : (isDark ? Colors.white60 : Colors.black45);
      } else if (type == BrightnessAdjustmentType.blacks) {
        // 검정계열: 어두운 회색으로 채움
        return hasValue
            ? (isDark ? Colors.white70 : Colors.black54)
            : (isDark ? Colors.white60 : Colors.black45);
      } else {
        // 나머지: 기존 로직
        return hasValue
            ? (isDark ? Colors.white : Colors.black87)
            : (isDark ? Colors.white70 : Colors.black54);
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
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
                getIconForType(),
                size: 34,
                color: getIconColor(),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
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

  Widget _buildSlider(BrightnessAdjustmentType type, bool isDark) {
    final value = _getValueForType(type);
    final label = _getLabelForType(type);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  _selectedType = null;
                });
              },
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
              onPressed: () {
                _updateValue(type, 0.0);
              },
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
            onChanged: (newValue) {
              _updateValue(type, newValue);
            },
          ),
        ),
      ],
    );
  }

  String _getLabelForType(BrightnessAdjustmentType type) {
    switch (type) {
      case BrightnessAdjustmentType.exposure:
        return '노출';
      case BrightnessAdjustmentType.contrast:
        return '대비';
      case BrightnessAdjustmentType.highlights:
        return '밝은영역';
      case BrightnessAdjustmentType.shadows:
        return '어두운영역';
      case BrightnessAdjustmentType.whites:
        return '흰색계열';
      case BrightnessAdjustmentType.blacks:
        return '검정계열';
      case BrightnessAdjustmentType.saturation:
        return '채도';
      case BrightnessAdjustmentType.warmth:
        return '따듯함';
      case BrightnessAdjustmentType.sharpness:
        return '선명도';
      case BrightnessAdjustmentType.noiseReduction:
        return '노이즈 감소';
    }
  }

  double _getValueForType(BrightnessAdjustmentType type) {
    switch (type) {
      case BrightnessAdjustmentType.exposure:
        return widget.adjustments.exposure;
      case BrightnessAdjustmentType.contrast:
        return widget.adjustments.contrast;
      case BrightnessAdjustmentType.highlights:
        return widget.adjustments.highlights;
      case BrightnessAdjustmentType.shadows:
        return widget.adjustments.shadows;
      case BrightnessAdjustmentType.whites:
        return widget.adjustments.whites;
      case BrightnessAdjustmentType.blacks:
        return widget.adjustments.blacks;
      case BrightnessAdjustmentType.saturation:
        return widget.adjustments.saturation;
      case BrightnessAdjustmentType.warmth:
        return widget.adjustments.warmth;
      case BrightnessAdjustmentType.sharpness:
        return widget.adjustments.sharpness;
      case BrightnessAdjustmentType.noiseReduction:
        return widget.adjustments.noiseReduction;
    }
  }

  void _updateValue(BrightnessAdjustmentType type, double value) {
    BrightnessAdjustments updated;
    switch (type) {
      case BrightnessAdjustmentType.exposure:
        updated = widget.adjustments.copyWith(exposure: value);
        break;
      case BrightnessAdjustmentType.contrast:
        updated = widget.adjustments.copyWith(contrast: value);
        break;
      case BrightnessAdjustmentType.highlights:
        updated = widget.adjustments.copyWith(highlights: value);
        break;
      case BrightnessAdjustmentType.shadows:
        updated = widget.adjustments.copyWith(shadows: value);
        break;
      case BrightnessAdjustmentType.whites:
        updated = widget.adjustments.copyWith(whites: value);
        break;
      case BrightnessAdjustmentType.blacks:
        updated = widget.adjustments.copyWith(blacks: value);
        break;
      case BrightnessAdjustmentType.saturation:
        updated = widget.adjustments.copyWith(saturation: value);
        break;
      case BrightnessAdjustmentType.warmth:
        updated = widget.adjustments.copyWith(warmth: value);
        break;
      case BrightnessAdjustmentType.sharpness:
        updated = widget.adjustments.copyWith(sharpness: value);
        break;
      case BrightnessAdjustmentType.noiseReduction:
        updated = widget.adjustments.copyWith(noiseReduction: value);
        break;
    }
    widget.onChanged(updated);
  }
}
