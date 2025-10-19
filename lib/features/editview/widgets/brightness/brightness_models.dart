import 'package:flutter/material.dart';

/// 밝기 조정 타입 enum
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

/// 밝기 조정 값 모델
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

/// 밝기 조정 타입 정보
class BrightnessAdjustmentInfo {
  final BrightnessAdjustmentType type;
  final String label;
  final IconData icon;

  const BrightnessAdjustmentInfo({
    required this.type,
    required this.label,
    required this.icon,
  });
}

/// 밝기 조정 정보 제공 클래스
class BrightnessAdjustmentProvider {
  static const List<BrightnessAdjustmentInfo> adjustments = [
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.exposure,
      label: '노출',
      icon: Icons.brightness_6_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.contrast,
      label: '대비',
      icon: Icons.tonality_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.highlights,
      label: '밝은영역',
      icon: Icons.light_mode_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.shadows,
      label: '어두운영역',
      icon: Icons.nightlight_round_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.whites,
      label: '흰색계열',
      icon: Icons.circle,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.blacks,
      label: '검정계열',
      icon: Icons.circle_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.saturation,
      label: '채도',
      icon: Icons.water_drop_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.warmth,
      label: '따듯함',
      icon: Icons.wb_twilight_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.sharpness,
      label: '선명도',
      icon: Icons.details_outlined,
    ),
    BrightnessAdjustmentInfo(
      type: BrightnessAdjustmentType.noiseReduction,
      label: '노이즈 감소',
      icon: Icons.blur_on_outlined,
    ),
  ];

  static String getLabel(BrightnessAdjustmentType type) {
    return adjustments.firstWhere((a) => a.type == type).label;
  }

  static IconData getIcon(BrightnessAdjustmentType type) {
    return adjustments.firstWhere((a) => a.type == type).icon;
  }

  /// 특정 타입의 값 가져오기
  static double getValue(
    BrightnessAdjustments adjustments,
    BrightnessAdjustmentType type,
  ) {
    return switch (type) {
      BrightnessAdjustmentType.exposure => adjustments.exposure,
      BrightnessAdjustmentType.contrast => adjustments.contrast,
      BrightnessAdjustmentType.highlights => adjustments.highlights,
      BrightnessAdjustmentType.shadows => adjustments.shadows,
      BrightnessAdjustmentType.whites => adjustments.whites,
      BrightnessAdjustmentType.blacks => adjustments.blacks,
      BrightnessAdjustmentType.saturation => adjustments.saturation,
      BrightnessAdjustmentType.warmth => adjustments.warmth,
      BrightnessAdjustmentType.sharpness => adjustments.sharpness,
      BrightnessAdjustmentType.noiseReduction => adjustments.noiseReduction,
    };
  }

  /// 특정 타입의 값 업데이트
  static BrightnessAdjustments updateValue(
    BrightnessAdjustments adjustments,
    BrightnessAdjustmentType type,
    double value,
  ) {
    return switch (type) {
      BrightnessAdjustmentType.exposure => adjustments.copyWith(exposure: value),
      BrightnessAdjustmentType.contrast => adjustments.copyWith(contrast: value),
      BrightnessAdjustmentType.highlights => adjustments.copyWith(highlights: value),
      BrightnessAdjustmentType.shadows => adjustments.copyWith(shadows: value),
      BrightnessAdjustmentType.whites => adjustments.copyWith(whites: value),
      BrightnessAdjustmentType.blacks => adjustments.copyWith(blacks: value),
      BrightnessAdjustmentType.saturation => adjustments.copyWith(saturation: value),
      BrightnessAdjustmentType.warmth => adjustments.copyWith(warmth: value),
      BrightnessAdjustmentType.sharpness => adjustments.copyWith(sharpness: value),
      BrightnessAdjustmentType.noiseReduction => adjustments.copyWith(noiseReduction: value),
    };
  }
}
