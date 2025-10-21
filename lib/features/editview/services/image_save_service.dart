import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import '../debug/editview_logger.dart';

/// 이미지 저장 서비스
class ImageSaveService {
  void _log(String message) => EditViewLogger.log(message);
  void _logError(String message, [Object? error, StackTrace? stackTrace]) =>
      EditViewLogger.error(message, error, stackTrace);

  /// 갤러리에 이미지 저장
  Future<bool> saveToGallery(List<int> imageBytes, bool isPng) async {
    try {
      _log('Requesting storage permission...');

      // 권한 요청
      PermissionStatus status;
      if (Platform.isAndroid) {
        // Android 13 (API 33) 이상에서는 사진/동영상 권한 따로 요청
        if (await Permission.photos.isGranted ||
            await Permission.storage.isGranted) {
          status = PermissionStatus.granted;
        } else {
          status = await Permission.photos.request();
          if (status.isDenied) {
            status = await Permission.storage.request();
          }
        }
      } else {
        // iOS
        status = await Permission.photos.request();
      }

      if (!status.isGranted) {
        _log('Storage permission denied');
        return false;
      }

      _log('Permission granted, saving to gallery...');

      // 갤러리에 저장
      final result = await ImageGallerySaver.saveImage(
        Uint8List.fromList(imageBytes),
        quality: isPng ? 100 : 95,
        name: 'FilmIn_${DateTime.now().millisecondsSinceEpoch}',
      );

      _log('Gallery save result: $result');

      if (result != null && result['isSuccess'] == true) {
        _log('Image successfully saved to gallery');
        return true;
      } else {
        _log('Failed to save image to gallery');
        return false;
      }
    } catch (e, stackTrace) {
      _logError('Gallery save failed', e, stackTrace);
      return false;
    }
  }
}
