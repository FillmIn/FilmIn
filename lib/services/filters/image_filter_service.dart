import 'package:flutter/material.dart';
import 'package:filmin/services/filters/xmp/xmp_service.dart';

/// Generates simple color filters based on XMP settings.
///
/// This service only provides lightweight approximations that can be used with
/// `ColorFiltered`. The heavy image-processing path (pixel manipulation) was
/// removed because it depended on duplicate `XmpFilterData` definitions and raw
/// byte conversions that caused build errors after the service refactor.
class ImageFilterService {
  static final ImageFilterService _instance = ImageFilterService._internal();
  factory ImageFilterService() => _instance;
  ImageFilterService._internal();

  /// Returns a color filter that approximates the selected XMP preset.
  /// If the preset is unknown, returns `null`.
  ColorFilter? createColorFilter(String filterName) {
    final filterData = XmpService().getFilterByName(filterName);
    if (filterData == null) return null;

    final settings = filterData.settings;
    final contrast = 1.0 + ((settings['Contrast2012'] ?? 0.0) / 100.0);
    final saturation = 1.0 + ((settings['Saturation'] ?? 0.0) / 100.0);
    final exposure = (settings['Exposure2012'] ?? 0.0).toDouble();
    final brightness = exposure * 0.1;

    return ColorFilter.matrix(
      [
        contrast * saturation, 0, 0, 0, brightness * 255,
        0, contrast * saturation, 0, 0, brightness * 255,
        0, 0, contrast * saturation, 0, brightness * 255,
        0, 0, 0, 1, 0,
      ],
    );
  }
}
