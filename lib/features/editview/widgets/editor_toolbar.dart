import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'editor_asset_paths.dart';

enum EditorTool { none, brightness, effect, filter, crop }

class EditorToolbar extends StatelessWidget {
  final EditorTool selectedTool;
  final Function(EditorTool) onToolSelected;

  const EditorToolbar({
    super.key,
    required this.selectedTool,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              svgPath: editorGroupAssetPath(
                isDarkMode: isDark,
                groupNumber: 1,
              ),
              label: '밝기',
              selected: selectedTool == EditorTool.brightness,
              onTap: () => onToolSelected(EditorTool.brightness),
            ),
            _ToolButton(
              svgPath: editorGroupAssetPath(
                isDarkMode: isDark,
                groupNumber: 2,
              ),
              label: '효과',
              selected: selectedTool == EditorTool.effect,
              onTap: () => onToolSelected(EditorTool.effect),
            ),
            _ToolButton(
              svgPath: editorGroupAssetPath(
                isDarkMode: isDark,
                groupNumber: 3,
              ),
              label: '필터',
              selected: selectedTool == EditorTool.filter,
              onTap: () => onToolSelected(EditorTool.filter),
            ),
            _ToolButton(
              svgPath: editorGroupAssetPath(
                isDarkMode: isDark,
                groupNumber: 4,
              ),
              label: '자르기',
              selected: selectedTool == EditorTool.crop,
              onTap: () => onToolSelected(EditorTool.crop),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String svgPath;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.svgPath,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: SvgPicture.asset(
              svgPath,
              width: 40,
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
