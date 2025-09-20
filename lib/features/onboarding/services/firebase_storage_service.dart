import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/firebase_image.dart';

class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Future<List<FirebaseImage>> getImagesFromFolder(String folderPath) async {
    try {
      final ListResult result = await _storage.ref(folderPath).listAll();
      final List<FirebaseImage> images = [];

      for (final Reference ref in result.items) {
        final String downloadUrl = await ref.getDownloadURL();
        final FullMetadata metadata = await ref.getMetadata();

        final FirebaseImage image = FirebaseImage(
          name: ref.name,
          downloadUrl: downloadUrl,
          fullPath: ref.fullPath,
          sizeBytes: metadata.size,
          timeCreated: metadata.timeCreated,
          updated: metadata.updated,
          metadata: metadata.customMetadata,
        );

        images.add(image);
      }

      return images;
    } catch (e) {
      throw Exception('Firebase Storage에서 이미지를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  static Future<List<FirebaseImage>> getImagesWithMetadata(String folderPath) async {
    try {
      return await getImagesFromFolder(folderPath);
    } catch (e) {
      throw Exception('이미지를 가져오는 중 오류가 발생했습니다: $e');
    }
  }

  static Future<String> uploadImage(String localPath, String remotePath) async {
    try {
      final Reference ref = _storage.ref(remotePath);
      final TaskSnapshot snapshot = await ref.putFile(File(localPath));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('이미지 업로드 중 오류가 발생했습니다: $e');
    }
  }

  static Future<void> deleteImage(String fullPath) async {
    try {
      final Reference ref = _storage.ref(fullPath);
      await ref.delete();
    } catch (e) {
      throw Exception('이미지 삭제 중 오류가 발생했습니다: $e');
    }
  }
}