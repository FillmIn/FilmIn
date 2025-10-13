import 'package:flutter/material.dart';

/// 편집 도구의 하단 액션 바 (취소/편집/완료 버튼)
class EditActionBar extends StatelessWidget {
  final VoidCallback? onCancel;
  final VoidCallback? onApply;
  final String centerText;

  const EditActionBar({
    super.key,
    this.onCancel,
    this.onApply,
    this.centerText = '편집',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // 취소 버튼 (왼쪽)
          IconButton(
            icon: Icon(
              Icons.close,
              color: iconColor,
              size: 22,
              weight: 300,
            ),
            onPressed: onCancel,
          ),
          const Spacer(),
          // 편집 텍스트 (중앙)
          Text(
            centerText,
            style: TextStyle(
              color: iconColor,
              fontSize: 16,
              fontWeight: FontWeight.w300,
            ),
          ),
          const Spacer(),
          // 완료 버튼 (오른쪽)
          IconButton(
            icon: Icon(
              Icons.check,
              color: iconColor,
              size: 22,
              weight: 300,
            ),
            onPressed: onApply,
          ),
        ],
      ),
    );
  }
}
