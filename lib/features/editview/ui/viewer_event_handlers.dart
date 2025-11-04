import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../state/viewer_state.dart';
import '../widgets/crop/crop_tool.dart';
import '../debug/editview_logger.dart';

/// ViewerPage의 이벤트 핸들러 로직을 담당하는 클래스
///
/// 역할: 사용자 상호작용에 대한 비즈니스 로직을 처리합니다.
class ViewerEventHandlers {
  final ViewerState state;
  final BuildContext Function() getContext;
  final void Function(VoidCallback) setStateCallback;

  ViewerEventHandlers({
    required this.state,
    required this.getContext,
    required this.setStateCallback,
  });

  void _log(String message) => EditViewLogger.log(message);
  void _logError(String message, [Object? error, StackTrace? stackTrace]) =>
      EditViewLogger.error(message, error, stackTrace);

  /// 이미지 비율 로드
  Future<void> loadImageAspectRatio() async {
    final path = state.imagePath;
    if (path == null || path.isEmpty) return;

    try {
      final file = File(path);
      if (!file.existsSync()) return;

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image != null) {
        setStateCallback(() {
          state.imageAspectRatio = image.width / image.height;
        });
        image.clear();
      }
    } catch (e) {
      _logError('Failed to load image aspect ratio', e);
    }
  }

  /// 뒤로가기 버튼 처리
  Future<void> handleBackButton(bool hasUnsavedChanges) async {
    final context = getContext();

    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            hasUnsavedChanges ? '저장되지 않은 변경사항' : '편집 종료',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            hasUnsavedChanges
                ? '지금까지 편집한 내용은 저장되지 않습니다.\n정말 나가시겠습니까?'
                : '편집을 종료하시겠습니까?',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black87,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(
                '취소',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                backgroundColor: hasUnsavedChanges
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
              ),
              child: Text(
                '나가기',
                style: TextStyle(
                  color: hasUnsavedChanges ? Colors.red : Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldExit == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  /// 실행 취소
  void undoEdit() {
    if (state.canUndo()) {
      setStateCallback(() {
        state.undo();
        _log('Undo: moved to index ${state.currentHistoryIndex}');
        _log('Current image: ${state.imagePath}');
      });
      _showSnackBar('이전으로 되돌렸습니다.', duration: 1);
    }
  }

  /// 자동 밝기 조정
  Future<void> autoAdjustImage() async {
    final path = state.imagePath;
    if (path == null || path.isEmpty) return;

    setStateCallback(() => state.isSaving = true);
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      final adjustments =
          await state.processingService.calculateAutoAdjustments(path);

      setStateCallback(() {
        state.brightnessAdjustments = adjustments;
        state.isSaving = false;
      });

      _showSnackBar('자동 조정 완료', duration: 1);
    } catch (e, stackTrace) {
      _logError('Auto-adjust failed', e, stackTrace);
      setStateCallback(() => state.isSaving = false);
    }
  }

  /// 크롭 임시 저장
  Future<void> saveTempEdits() async {
    setStateCallback(() => state.isSaving = true);

    final path = state.imagePath;
    if (path == null || path.isEmpty) {
      _log('Save aborted: no image path');
      setStateCallback(() => state.isSaving = false);
      return;
    }

    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    if (isHttp) {
      setStateCallback(() => state.isSaving = false);
      _showSnackBar('Editing network images not supported yet. Download first.');
      return;
    }

    try {
      final outPath = await state.processingService.saveCropOnly(
        imagePath: path,
        crop: state.crop,
        cropOffset: state.cropOffset,
        cropScale: state.cropScale,
        freeformCropRect: state.freeformCropRect,
        screenSize: state.screenSize,
      );

      // 히스토리 업데이트
      state.addToHistory(outPath);

      setStateCallback(() {
        state.isSaving = false;
        state.crop = CropPreset.original;
        state.cropOffset = Offset.zero;
        state.cropScale = 1.0;
        state.freeformCropRect = null;
      });

      _log('History updated: index=${state.currentHistoryIndex}, total=${state.imageHistory.length}');
      _showSnackBar('자르기가 적용되었습니다', duration: 1);
    } catch (e, stackTrace) {
      _logError('Temp save failed', e, stackTrace);
      setStateCallback(() => state.isSaving = false);
      _showSnackBar('Save failed: $e');
    }
  }

  /// 최종 저장
  Future<void> saveEdits() async {
    _log('========== SAVE EDITS START ==========');

    setStateCallback(() => state.isSaving = true);

    final path = state.imagePath;
    if (path == null || path.isEmpty) {
      _log('Save aborted: no image path');
      setStateCallback(() => state.isSaving = false);
      return;
    }

    final isHttp = path.startsWith('http://') || path.startsWith('https://');
    if (isHttp) {
      setStateCallback(() => state.isSaving = false);
      _showSnackBar('Editing network images not supported yet. Download first.');
      return;
    }

    try {
      final outBytes = await state.processingService.processFullEdit(
        imagePath: path,
        rotation: state.rotation,
        flipH: state.flipH,
        brightness: state.brightness,
        brightnessAdjustments: state.brightnessAdjustments,
        filter: state.filter,
        filterIntensity: state.filterIntensity,
        filmEffects: state.filmEffects,
        crop: state.crop,
        cropOffset: state.cropOffset,
        cropScale: state.cropScale,
        freeformCropRect: state.freeformCropRect,
        screenSize: state.screenSize,
        lutService: state.lutService,
      );

      final originalExt = path.toLowerCase().split('.').last;
      final isPng = originalExt == 'png';
      final saveResult = await state.saveService.saveToGallery(outBytes, isPng);

      setStateCallback(() => state.isSaving = false);
      _log('========== SAVE EDITS END ==========');

      _showSnackBar(
        saveResult ? '갤러리에 저장되었습니다' : '저장에 실패했습니다',
        duration: 2,
        backgroundColor: saveResult ? Colors.green : Colors.red,
      );
    } catch (e, stackTrace) {
      _logError('Save failed', e, stackTrace);
      setStateCallback(() => state.isSaving = false);
      _showSnackBar('Save failed: $e');
    }
  }

  /// 스낵바 표시 헬퍼 메서드
  void _showSnackBar(
    String message, {
    int duration = 2,
    Color? backgroundColor,
  }) {
    final context = getContext();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: duration),
        backgroundColor: backgroundColor,
      ),
    );
  }
}
