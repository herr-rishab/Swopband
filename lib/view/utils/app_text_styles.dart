import 'package:flutter/material.dart';

class AppTextStyles {
  static const String fontFamily = 'Outfit';

  static const TextStyle small = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    fontFamily: fontFamily,
    letterSpacing: -0.2, // 2% tighter spacing
  );

  static const TextStyle medium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: -0.2, // 2% tighter spacing
  );

  static const TextStyle large = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: -0.2, // 2% tighter spacing
  );

  static const TextStyle extraLarge = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
    letterSpacing: -0.2, // 2% tighter spacing
  );
}
