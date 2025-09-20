import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import '../../../app/di/main_di.dart';
import '../../../app/debug/debug_settings.dart';
import '../models/firebase_image.dart';

// Configure your bucket URL here (can be overridden by reading this provider).
final storageBucketProvider = Provider<String>((ref) {
  return 'gs://filmin-2a766.firebasestorage.app';
});

// GridImage 폴더 설정
final storageFolderProvider = Provider<String>((ref) => 'GridImage');

// 이미지와 메타데이터를 함께 가져오는 Provider
final storageImagesProvider = FutureProvider.autoDispose<List<FirebaseImage>>((
  ref,
) async {
  final bucket = ref.watch(storageBucketProvider);
  final folder = ref.watch(storageFolderProvider);

  // Firebase 초기화 확인
  final ok = await ref.read(firebaseInitProvider.future);
  if (!ok || Firebase.apps.isEmpty) {
    wlog('Skipping Storage fetch: Firebase not initialized.');
    return <FirebaseImage>[];
  }

  try {
    final storage = FirebaseStorage.instanceFor(bucket: bucket);
    final refFolder = storage.ref(folder);
    final result = await refFolder.listAll();
    final items = result.items;

    // 이미지 파일만 필터링 (jpg, jpeg, png, gif, webp)
    final imageItems = items.where((item) {
      final name = item.name.toLowerCase();
      return name.endsWith('.jpg') ||
          name.endsWith('.jpeg') ||
          name.endsWith('.png') ||
          name.endsWith('.gif') ||
          name.endsWith('.webp');
    }).toList();

    // 병렬로 이미지 정보 가져오기
    final futures = imageItems.map((item) async {
      try {
        final downloadUrl = await item.getDownloadURL();
        final metadata = await item.getMetadata();

        return FirebaseImage(
          name: item.name,
          downloadUrl: downloadUrl,
          fullPath: item.fullPath,
          sizeBytes: metadata.size,
          timeCreated: metadata.timeCreated,
          updated: metadata.updated,
          metadata: metadata.customMetadata,
        );
      } catch (e) {
        wlog('Failed to get metadata for ${item.name}: $e');
        return null;
      }
    });

    final results = await Future.wait(futures);
    final images = results.whereType<FirebaseImage>().toList();

    // JSON 메타데이터가 있는지 확인하고 병합
    final enrichedImages = await _enrichWithJsonMetadata(
      storage,
      folder,
      images,
    );

    // 파일명으로 정렬 (최신순)
    enrichedImages.sort((a, b) => b.name.compareTo(a.name));

    return enrichedImages;
  } on FirebaseException catch (e, st) {
    wlog('Storage fetch failed: ${e.code} ${e.message}', st);
    return <FirebaseImage>[];
  } catch (e, st) {
    wlog('Storage fetch failed: $e', st);
    return <FirebaseImage>[];
  }
});

// JSON 메타데이터로 이미지 정보 보강
Future<List<FirebaseImage>> _enrichWithJsonMetadata(
  FirebaseStorage storage,
  String folder,
  List<FirebaseImage> images,
) async {
  try {
    // metadata.json 파일 확인
    final metadataRef = storage.ref('$folder/metadata.json');
    final metadataUrl = await metadataRef.getDownloadURL();

    // JSON 파일 다운로드
    final response = await http.get(Uri.parse(metadataUrl));
    if (response.statusCode != 200) {
      return images; // JSON이 없으면 기본 이미지 리스트 반환
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final imageMetadata = <String, Map<String, dynamic>>{};

    // JSON에서 이미지별 메타데이터 추출
    if (jsonData['images'] is List) {
      for (final item in jsonData['images']) {
        if (item is Map<String, dynamic> && item['name'] != null) {
          imageMetadata[item['name']] = item;
        }
      }
    }

    // 이미지에 메타데이터 병합
    return images.map((image) {
      final metadata = imageMetadata[image.name];
      if (metadata != null) {
        return FirebaseImage(
          name: image.name,
          downloadUrl: image.downloadUrl,
          fullPath: image.fullPath,
          sizeBytes: image.sizeBytes,
          timeCreated: image.timeCreated,
          updated: image.updated,
          metadata: {...?image.metadata, ...metadata},
        );
      }
      return image;
    }).toList();
  } catch (e) {
    // JSON 파일이 없거나 읽기 실패 시 기본 이미지 리스트 반환
    wlog('No metadata.json found or failed to read: $e');
    return images;
  }
}

// 기존 URL만 가져오는 Provider (호환성용)
final storageImageUrlsProvider = FutureProvider.autoDispose<List<String>>((
  ref,
) async {
  final images = await ref.watch(storageImagesProvider.future);
  return images.map((img) => img.downloadUrl).toList();
});
