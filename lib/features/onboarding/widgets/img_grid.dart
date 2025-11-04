import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/firebase_image.dart';
import '../services/firebase_storage_service.dart';
import '../../../app/di/main_di.dart';

/// Instagram-like photo preview grid.
/// Can display both local files and Firebase Storage images.
class PhotoPreviewGrid extends StatelessWidget {
  final List<String>? imagePaths;
  final String? firebaseFolder;
  final void Function(int index, String path)? onTap;
  final void Function(int index, FirebaseImage image)? onFirebaseImageTap;
  final VoidCallback? onAddTap;
  final int crossAxisCount;
  final double spacing;

  const PhotoPreviewGrid({
    super.key,
    this.imagePaths,
    this.firebaseFolder,
    this.onTap,
    this.onFirebaseImageTap,
    this.onAddTap,
    this.crossAxisCount = 3,
    this.spacing = 1.0,
  }) : assert(imagePaths != null || firebaseFolder != null,
              'Either imagePaths or firebaseFolder must be provided');

  @override
  Widget build(BuildContext context) {
    if (firebaseFolder != null) {
      return _FirebaseGrid(
        folderPath: firebaseFolder!,
        onImageTap: onFirebaseImageTap,
        onAddTap: onAddTap,
        crossAxisCount: crossAxisCount,
        spacing: spacing,
      );
    }

    final itemCount = (imagePaths?.length ?? 0) + (onAddTap != null ? 1 : 0);
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
        final path = imagePaths![idx];
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

class _FirebaseGrid extends ConsumerStatefulWidget {
  final String folderPath;
  final void Function(int index, FirebaseImage image)? onImageTap;
  final VoidCallback? onAddTap;
  final int crossAxisCount;
  final double spacing;

  const _FirebaseGrid({
    required this.folderPath,
    this.onImageTap,
    this.onAddTap,
    this.crossAxisCount = 3,
    this.spacing = 1.0,
  });

  @override
  ConsumerState<_FirebaseGrid> createState() => _FirebaseGridState();
}

class _FirebaseGridState extends ConsumerState<_FirebaseGrid> {
  List<FirebaseImage>? _images;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Firebase 초기화 상태 확인
      final firebaseInitResult = await ref.read(firebaseInitProvider.future);
      if (!firebaseInitResult) {
        throw Exception('Firebase 초기화에 실패했습니다');
      }

      debugPrint('Firebase Storage에서 이미지 로딩 시작: ${widget.folderPath}');
      final images = await FirebaseStorageService.getImagesWithMetadata(widget.folderPath);
      debugPrint('로딩된 이미지 개수: ${images.length}');

      setState(() {
        _images = images;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('이미지 로딩 실패: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseInit = ref.watch(firebaseInitProvider);

    return firebaseInit.when(
      data: (initialized) {
        if (!initialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, size: 48),
                SizedBox(height: 16),
                Text('Firebase 초기화에 실패했습니다'),
              ],
            ),
          );
        }

        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadImages,
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          );
        }

        final images = _images ?? [];
        final itemCount = images.length + (widget.onAddTap != null ? 1 : 0);

        if (images.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_library_outlined, size: 48),
                SizedBox(height: 16),
                Text('이미지가 없습니다'),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.crossAxisCount,
            mainAxisSpacing: widget.spacing,
            crossAxisSpacing: widget.spacing,
            childAspectRatio: 1,
          ),
          itemCount: itemCount,
          itemBuilder: (context, i) {
            final isAdd = widget.onAddTap != null && i == 0;
            if (isAdd) {
              return _AddTile(onTap: widget.onAddTap!);
            }
            final idx = widget.onAddTap != null ? i - 1 : i;
            final image = images[idx];
            return _FirebaseThumbTile(
              image: image,
              onTap: () => widget.onImageTap?.call(idx, image),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text('Firebase 초기화 오류: $error', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _FirebaseThumbTile extends StatelessWidget {
  final FirebaseImage image;
  final VoidCallback? onTap;

  const _FirebaseThumbTile({
    required this.image,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(0),
        child: CachedNetworkImage(
          imageUrl: image.downloadUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Theme.of(context).colorScheme.surface,
            child: const Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surface,
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
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
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.9)),
        ),
        child: Icon(Icons.add, color: scheme.primary),
      ),
    );
  }
}
