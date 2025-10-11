import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'editor_asset_paths.dart';

class EditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;
  final VoidCallback onSave;

  const EditorAppBar({
    super.key,
    required this.onCompareStart,
    required this.onCompareEnd,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.black : Colors.white;
    final compareIconPath = editorGroupAssetPath(
      isDarkMode: isDark,
      groupNumber: 5,
    );
    final iconColor = isDark ? Colors.white : Colors.black;

    return AppBar(
      backgroundColor: bgColor,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: GestureDetector(
        onTapDown: (_) => onCompareStart(),
        onTapUp: (_) => onCompareEnd(),
        onTapCancel: onCompareEnd,
        child: SvgPicture.asset(
          compareIconPath,
          width: 20,
          height: 29,
          colorFilter: ColorFilter.mode(
            iconColor,
            BlendMode.srcIn,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.file_download_outlined, color: iconColor),
          onPressed: onSave,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
