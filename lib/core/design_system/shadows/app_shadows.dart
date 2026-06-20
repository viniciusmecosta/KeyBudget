import 'package:flutter/material.dart';

class AppShadows {
  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withAlpha((255 * 0.05).round()),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withAlpha((255 * 0.08).round()),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
