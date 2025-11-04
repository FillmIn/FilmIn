import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/storage_repository.dart';
import 'image_detail_overlay.dart';

/// Firebase Storage 이미지 그리드 섹션
///
/// storageImagesProvider를 사용하여 Firebase 이미지를 로딩하고
/// 3열 그리드로 표시합니다.
class FirebaseImageGridSection extends ConsumerWidget {
  const FirebaseImageGridSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(storageImagesProvider).when(
          data: (images) {
            if (images.isEmpty) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text('이미지가 없습니다')),
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  return GestureDetector(
                    onTap: () => ImageDetailOverlay.show(
                      context,
                      images,
                      index,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(0),
                      child: Image.network(
                        image.downloadUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 20,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, st) => const SizedBox(
            height: 200,
            child: Center(child: Text('이미지 로딩 실패')),
          ),
        );
  }
}
