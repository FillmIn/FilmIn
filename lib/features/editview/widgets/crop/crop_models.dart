import 'package:flutter/material.dart';

/// 자르기 프리셋 enum
enum CropPreset { original, freeform, square, r4x5, r3x4, r9x16, r16x9 }

/// 자르기 프리셋 정보
class CropPresetInfo {
  final CropPreset preset;
  final String label;
  final double? aspectRatio;
  final double iconWidth;
  final double iconHeight;

  const CropPresetInfo({
    required this.preset,
    required this.label,
    this.aspectRatio,
    required this.iconWidth,
    required this.iconHeight,
  });
}

/// 자르기 프리셋 정보 제공 클래스
class CropPresetProvider {
  static const List<CropPresetInfo> presets = [
    CropPresetInfo(
      preset: CropPreset.freeform,
      label: '자유 형식',
      aspectRatio: null,
      iconWidth: 40,
      iconHeight: 40,
    ),
    CropPresetInfo(
      preset: CropPreset.square,
      label: '1 : 1',
      aspectRatio: 1 / 1,
      iconWidth: 40,
      iconHeight: 40,
    ),
    CropPresetInfo(
      preset: CropPreset.r4x5,
      label: '4 : 5',
      aspectRatio: 4 / 5,
      iconWidth: 32,
      iconHeight: 40,
    ),
    CropPresetInfo(
      preset: CropPreset.r3x4,
      label: '3 : 4',
      aspectRatio: 3 / 4,
      iconWidth: 30,
      iconHeight: 40,
    ),
    CropPresetInfo(
      preset: CropPreset.r9x16,
      label: '9 : 16',
      aspectRatio: 9 / 16,
      iconWidth: 22,
      iconHeight: 40,
    ),
    CropPresetInfo(
      preset: CropPreset.r16x9,
      label: '16 : 9',
      aspectRatio: 16 / 9,
      iconWidth: 40,
      iconHeight: 22,
    ),
  ];

  static CropPresetInfo? getInfo(CropPreset preset) {
    try {
      return presets.firstWhere((p) => p.preset == preset);
    } catch (e) {
      return null;
    }
  }

  static double? getAspectRatio(CropPreset preset) {
    return switch (preset) {
      CropPreset.original => null,
      CropPreset.freeform => null,
      CropPreset.square => 1 / 1,
      CropPreset.r4x5 => 4 / 5,
      CropPreset.r3x4 => 3 / 4,
      CropPreset.r9x16 => 9 / 16,
      CropPreset.r16x9 => 16 / 9,
    };
  }
}

/// 자르기 계산 유틸리티
class CropCalculator {
  /// 이미지가 실제로 표시되는 영역 계산 (BoxFit.contain 로직)
  static Rect calculateImageArea(Size screenSize, double? imageAspectRatio) {
    if (imageAspectRatio == null) {
      return Rect.fromLTWH(0, 0, screenSize.width, screenSize.height);
    }

    final screenAspect = screenSize.width / screenSize.height;

    if (imageAspectRatio > screenAspect) {
      final imageWidth = screenSize.width;
      final imageHeight = screenSize.width / imageAspectRatio;
      final top = (screenSize.height - imageHeight) / 2;
      return Rect.fromLTWH(0, top, imageWidth, imageHeight);
    } else {
      final imageHeight = screenSize.height;
      final imageWidth = screenSize.height * imageAspectRatio;
      final left = (screenSize.width - imageWidth) / 2;
      return Rect.fromLTWH(left, 0, imageWidth, imageHeight);
    }
  }
}
