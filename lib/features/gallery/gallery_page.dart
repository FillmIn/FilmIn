import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../onboarding/data/storage_repository.dart';
import '../onboarding/network/network_photo_grid.dart';
import '../../app/di/main_di.dart';
import 'package:image_picker/image_picker.dart';

class GalleryPage extends ConsumerWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: const Text('앨범'),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final asyncUrls = ref.watch(storageImageUrlsProvider);
          return asyncUrls.when(
            data: (urls) => NetworkPhotoGrid(
              urls: urls,
              onTap: (index, url) {
                context.push('/editview', extra: url);
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Failed to load: $e')),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: '기기에서 선택',
        child: const Icon(Icons.add_photo_alternate),
        onPressed: () async {
          final picker = ImagePicker();
          final XFile? image = await picker.pickImage(
            source: ImageSource.gallery,
          );
          if (image != null && context.mounted) {
            // 리스트에 추가해두면 온보딩 그리드 등에서도 보일 수 있음
            final list = [...ref.read(pickedImagesProvider)];
            list.insert(0, image.path);
            ref.read(pickedImagesProvider.notifier).state = list;
            context.push('/editview', extra: image.path);
          }
        },
      ),
    );
  }
}
