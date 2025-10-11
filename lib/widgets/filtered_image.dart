import 'package:flutter/material.dart';
import 'package:filmin/services/filters/image_filter_service.dart';

class FilteredImage extends StatelessWidget {
  final ImageProvider imageProvider;
  final String? filterName;
  final double? width;
  final double? height;
  final BoxFit? fit;

  const FilteredImage({
    super.key,
    required this.imageProvider,
    this.filterName,
    this.width,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (filterName == null) {
      return Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit,
      );
    }

    final filterService = ImageFilterService();
    final colorFilter = filterService.createColorFilter(filterName!);

    if (colorFilter == null) {
      return Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return ColorFiltered(
      colorFilter: colorFilter,
      child: Image(
        image: imageProvider,
        width: width,
        height: height,
        fit: fit,
      ),
    );
  }
}
