import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NetworkPhotoGrid extends StatelessWidget {
  final List<String> urls;
  final void Function(int index, String url)? onTap;
  final int crossAxisCount;
  final double spacing;

  const NetworkPhotoGrid({
    super.key,
    required this.urls,
    this.onTap,
    this.crossAxisCount = 3,
    this.spacing = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: urls.length,
      itemBuilder: (context, i) {
        final url = urls[i];
        return InkWell(
          onTap: onTap == null ? null : () => onTap!(i, url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (c, _) => Container(
                color: Theme.of(context).colorScheme.surface,
              ),
              errorWidget: (c, _, __) => Container(
                color: Theme.of(context).colorScheme.surface,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        );
      },
    );
  }
}

