import 'dart:io';

import 'package:flutter/material.dart';

/// Instagram-like photo preview grid.
/// Pass a list of local file paths to render square thumbnails.
class PhotoPreviewGrid extends StatelessWidget {
  final List<String> imagePaths;
  final void Function(int index, String path)? onTap;
  final VoidCallback? onAddTap;
  final int crossAxisCount;
  final double spacing;

  const PhotoPreviewGrid({
    super.key,
    required this.imagePaths,
    this.onTap,
    this.onAddTap,
    this.crossAxisCount = 3,
    this.spacing = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final itemCount = imagePaths.length + (onAddTap != null ? 1 : 0);
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        final isAdd = onAddTap != null && i == 0;
        if (isAdd) {
          return _AddTile(onTap: onAddTap!);
        }
        final idx = onAddTap != null ? i - 1 : i;
        final path = imagePaths[idx];
        return _ThumbTile(path: path, onTap: () => onTap?.call(idx, path));
      },
    );
  }
}

class _ThumbTile extends StatelessWidget {
  final String path;
  final VoidCallback? onTap;

  const _ThumbTile({required this.path, this.onTap});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    Widget content;
    if (file.existsSync()) {
      content = Image.file(file, fit: BoxFit.cover);
    } else {
      content = Container(
        color: Theme.of(context).colorScheme.surface,
        child: const Icon(Icons.broken_image),
      );
    }
    return InkWell(
      onTap: onTap,
      child: ClipRRect(borderRadius: BorderRadius.circular(0), child: content),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.9)),
        ),
        child: Icon(Icons.add, color: scheme.primary),
      ),
    );
  }
}
