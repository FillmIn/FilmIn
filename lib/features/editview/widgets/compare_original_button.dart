// import 'package:flutter/material.dart';

// class CompareOriginalButton extends StatelessWidget {
//   final VoidCallback onPressStart;
//   final VoidCallback onPressEnd;

//   const CompareOriginalButton({
//     super.key,
//     required this.onPressStart,
//     required this.onPressEnd,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => onPressStart(),
//       onTapUp: (_) => onPressEnd(),
//       onTapCancel: onPressEnd,
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 8,
//         ),
//         decoration: BoxDecoration(
//           color: Colors.black.withValues(alpha: 0.7),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: const Text(
//           '원본과 비교',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 14,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//       ),
//     );
//   }
// }
