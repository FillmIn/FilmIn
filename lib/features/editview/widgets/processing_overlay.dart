import 'package:flutter/material.dart';

/// 이미지 처리 중 로딩 오버레이
///
/// 반투명 검은색 배경에 로딩 인디케이터와 진행 상태 텍스트를 표시합니다.
class ProcessingOverlay extends StatelessWidget {
  final String message;
  final bool showProgress;
  final double? progress; // 0.0 ~ 1.0

  const ProcessingOverlay({
    super.key,
    this.message = '처리 중...',
    this.showProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 로딩 인디케이터
              if (showProgress && progress != null)
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 배경 원
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      // 진행률 원
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      // 진행률 텍스트
                      Text(
                        '${(progress! * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                // 무한 로딩
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),

              const SizedBox(height: 20),

              // 메시지 텍스트
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),

              // 진행률이 있을 경우 추가 정보
              if (showProgress && progress != null) ...[
                const SizedBox(height: 8),
                Text(
                  '잠시만 기다려주세요',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 애니메이션 효과가 있는 처리 오버레이
class AnimatedProcessingOverlay extends StatefulWidget {
  final String message;
  final List<String>? messageSteps; // 단계별 메시지 (선택사항)

  const AnimatedProcessingOverlay({
    super.key,
    this.message = '처리 중...',
    this.messageSteps,
  });

  @override
  State<AnimatedProcessingOverlay> createState() => _AnimatedProcessingOverlayState();
}

class _AnimatedProcessingOverlayState extends State<AnimatedProcessingOverlay> {
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    // 메시지 단계가 있으면 주기적으로 변경
    if (widget.messageSteps != null && widget.messageSteps!.isNotEmpty) {
      _startMessageRotation();
    }
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted && widget.messageSteps != null) {
        setState(() {
          _currentStepIndex = (_currentStepIndex + 1) % widget.messageSteps!.length;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentMessage = widget.messageSteps != null && widget.messageSteps!.isNotEmpty
        ? widget.messageSteps![_currentStepIndex]
        : widget.message;

    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 두꺼운 원 하나
              const SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  strokeWidth: 6,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),

              const SizedBox(height: 24),

              // 메시지 텍스트 (애니메이션)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  currentMessage,
                  key: ValueKey<String>(currentMessage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 8),

              // 서브 텍스트
              Text(
                '잠시만 기다려주세요',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
