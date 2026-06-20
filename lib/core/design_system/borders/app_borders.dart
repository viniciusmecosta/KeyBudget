import 'package:flutter/material.dart';

class AppBorders {
  // Radius
  static const double radiusXS = 4.0;
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusXXL = 32.0;

  static const Radius circularXS = Radius.circular(radiusXS);
  static const Radius circularS = Radius.circular(radiusS);
  static const Radius circularM = Radius.circular(radiusM);
  static const Radius circularL = Radius.circular(radiusL);
  static const Radius circularXL = Radius.circular(radiusXL);
  static const Radius circularXXL = Radius.circular(radiusXXL);

  static final BorderRadius borderRadiusS = BorderRadius.circular(radiusS);
  static final BorderRadius borderRadiusM = BorderRadius.circular(radiusM);
  static final BorderRadius borderRadiusL = BorderRadius.circular(radiusL);
  static final BorderRadius borderRadiusXL = BorderRadius.circular(radiusXL);
  static final BorderRadius borderRadiusXXL = BorderRadius.circular(radiusXXL);

  static final BorderRadius borderRadiusMD = BorderRadius.circular(10.0); // Alias or intermediate if needed

  // Vertical
  static final BorderRadius borderRadiusVerticalM = BorderRadius.vertical(top: circularM);
  static final BorderRadius borderRadiusVerticalL = BorderRadius.vertical(top: circularL);
  static final BorderRadius borderRadiusVerticalXL = BorderRadius.vertical(top: circularXL);
}
