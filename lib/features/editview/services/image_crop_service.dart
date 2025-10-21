import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../debug/editview_logger.dart';

/// 이미지 크롭 서비스
class ImageCropService {
  void _log(String message) => EditViewLogger.log(message);

  /// 자유 형식 크롭 적용
  img.Image freeformCrop(
    img.Image src,
    Rect screenRect,
    Size screenSize,
  ) {
    final sw = src.width;
    final sh = src.height;
    final imageAspect = sw / sh;

    _log('========== FREEFORM CROP DEBUG ==========');
    _log('Image size: ${sw}x$sh');
    _log('Screen rect: $screenRect');
    _log('Screen size: $screenSize');

    // 화면에서 이미지가 실제로 표시되는 크기 계산 (BoxFit.contain 로직)
    final screenAspect = screenSize.width / screenSize.height;
    double screenImageWidth, screenImageHeight;
    double imageLeft, imageTop;

    if (imageAspect > screenAspect) {
      // 이미지가 화면보다 가로로 더 넓음 - 화면 너비에 맞춤
      screenImageWidth = screenSize.width;
      screenImageHeight = screenSize.width / imageAspect;
      imageLeft = 0;
      imageTop = (screenSize.height - screenImageHeight) / 2;
    } else {
      // 이미지가 화면보다 세로로 더 김 - 화면 높이에 맞춤
      screenImageHeight = screenSize.height;
      screenImageWidth = screenSize.height * imageAspect;
      imageLeft = (screenSize.width - screenImageWidth) / 2;
      imageTop = 0;
    }

    _log('Screen image position: ($imageLeft, $imageTop)');
    _log('Screen image size: ${screenImageWidth}x$screenImageHeight');

    // 화면 픽셀 -> 이미지 픽셀 변환 비율
    final double pixelRatioX = sw / screenImageWidth;
    final double pixelRatioY = sh / screenImageHeight;

    _log('Pixel ratio: x=$pixelRatioX, y=$pixelRatioY');

    // 크롭 영역을 이미지 좌표계로 변환
    final cropLeftInImage = (screenRect.left - imageLeft) * pixelRatioX;
    final cropTopInImage = (screenRect.top - imageTop) * pixelRatioY;
    final cropWidthInImage = screenRect.width * pixelRatioX;
    final cropHeightInImage = screenRect.height * pixelRatioY;

    _log(
      'Crop in image coords: left=$cropLeftInImage, top=$cropTopInImage, w=$cropWidthInImage, h=$cropHeightInImage',
    );

    // 경계 체크
    final x = cropLeftInImage.clamp(0.0, sw.toDouble());
    final y = cropTopInImage.clamp(0.0, sh.toDouble());
    final w = cropWidthInImage.clamp(1.0, sw - x);
    final h = cropHeightInImage.clamp(1.0, sh - y);

    _log(
      'Final crop: x=${x.round()}, y=${y.round()}, w=${w.round()}, h=${h.round()}',
    );
    _log('====================================');

    return img.copyCrop(
      src,
      x: x.round(),
      y: y.round(),
      width: w.round(),
      height: h.round(),
    );
  }

  /// 비율 기반 크롭 적용
  img.Image cropToAspect(
    img.Image src,
    int wRatio,
    int hRatio,
    Offset offset,
    double scale,
    Size screenSize,
  ) {
    final sw = src.width;
    final sh = src.height;
    final target = wRatio / hRatio;
    final imageAspect = sw / sh;

    _log('========== CROP DEBUG ==========');
    _log('Image size: ${sw}x$sh');
    _log('Image aspect: $imageAspect');
    _log('Screen offset: $offset, Scale: $scale');
    _log('Screen size: $screenSize');
    _log('Target aspect: $wRatio:$hRatio = $target');

    // 화면에서 이미지가 실제로 표시되는 크기 계산 (BoxFit.contain 로직)
    final screenAspect = screenSize.width / screenSize.height;
    double screenImageWidth, screenImageHeight;

    if (imageAspect > screenAspect) {
      // 이미지가 화면보다 가로로 더 넓음 - 화면 너비에 맞춤
      screenImageWidth = screenSize.width;
      screenImageHeight = screenSize.width / imageAspect;
    } else {
      // 이미지가 화면보다 세로로 더 김 - 화면 높이에 맞춤
      screenImageHeight = screenSize.height;
      screenImageWidth = screenSize.height * imageAspect;
    }

    _log('Screen image size: ${screenImageWidth}x$screenImageHeight');

    // 화면 픽셀 -> 이미지 픽셀 변환 비율
    final double pixelRatioX = sw / screenImageWidth;
    final double pixelRatioY = sh / screenImageHeight;

    _log('Pixel ratio: x=$pixelRatioX, y=$pixelRatioY');

    // CropOverlay와 동일한 기준 크기 계산 (화면 크기의 90%)
    double baseCropWidth = screenImageWidth * 0.9;
    double baseCropHeight = baseCropWidth / target;

    if (baseCropHeight > screenImageHeight * 0.9) {
      baseCropHeight = screenImageHeight * 0.9;
      baseCropWidth = baseCropHeight * target;
    }

    _log('Base crop size (screen): ${baseCropWidth}x$baseCropHeight');

    // scale 적용
    double screenCropWidth = baseCropWidth * scale;
    double screenCropHeight = baseCropHeight * scale;

    _log('Scaled crop size (screen): ${screenCropWidth}x$screenCropHeight');

    // 이미지 픽셀 단위로 변환
    double cropWidth = screenCropWidth * pixelRatioX;
    double cropHeight = screenCropHeight * pixelRatioY;

    _log('Crop size (image pixels): ${cropWidth}x$cropHeight');

    // offset을 이미지 좌표계로 변환
    final double imageOffsetX = offset.dx * pixelRatioX;
    final double imageOffsetY = offset.dy * pixelRatioY;

    _log('Image offset: ($imageOffsetX, $imageOffsetY)');

    // 중앙 기준 좌표 계산
    double centerX = sw / 2;
    double centerY = sh / 2;

    // offset 적용
    double x = centerX - (cropWidth / 2) + imageOffsetX;
    double y = centerY - (cropHeight / 2) + imageOffsetY;

    _log('Center: ($centerX, $centerY)');
    _log('Crop position before clamp: ($x, $y)');

    // 경계 체크
    x = x.clamp(0.0, sw - cropWidth);
    y = y.clamp(0.0, sh - cropHeight);

    _log(
      'Final crop: x=${x.round()}, y=${y.round()}, w=${cropWidth.round()}, h=${cropHeight.round()}',
    );
    _log('================================');

    return img.copyCrop(
      src,
      x: x.round(),
      y: y.round(),
      width: cropWidth.round(),
      height: cropHeight.round(),
    );
  }
}
