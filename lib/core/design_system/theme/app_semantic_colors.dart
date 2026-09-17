import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/colors/app_colors.dart';

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color onWarning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color info;
  final Color onInfo;
  final Color infoContainer;
  final Color onInfoContainer;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
  });

  factory AppSemanticColors.light() {
    return const AppSemanticColors(
      success: AppColors.success,
      onSuccess: Colors.white,
      successContainer: Color(0xFFE8F5E9),
      onSuccessContainer: Color(0xFF1B5E20),
      warning: AppColors.warning,
      onWarning: Colors.black,
      warningContainer: Color(0xFFFFF3E0),
      onWarningContainer: Color(0xFFE65100),
      info: AppColors.info,
      onInfo: Colors.white,
      infoContainer: Color(0xFFE3F2FD),
      onInfoContainer: Color(0xFF0D47A1),
    );
  }

  factory AppSemanticColors.dark() {
    return const AppSemanticColors(
      success: Color(0xFF81C784),
      onSuccess: Colors.black,
      successContainer: Color(0xFF1B5E20),
      onSuccessContainer: Color(0xFFA5D6A7),
      warning: Color(0xFFFFB74D),
      onWarning: Colors.black,
      warningContainer: Color(0xFFE65100),
      onWarningContainer: Color(0xFFFFCC80),
      info: Color(0xFF64B5F6),
      onInfo: Colors.black,
      infoContainer: Color(0xFF0D47A1),
      onInfoContainer: Color(0xFF90CAF9),
    );
  }

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? onWarning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? info,
    Color? onInfo,
    Color? infoContainer,
    Color? onInfoContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoContainer: infoContainer ?? this.infoContainer,
      onInfoContainer: onInfoContainer ?? this.onInfoContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      onWarningContainer: Color.lerp(onWarningContainer, other.onWarningContainer, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoContainer: Color.lerp(infoContainer, other.infoContainer, t)!,
      onInfoContainer: Color.lerp(onInfoContainer, other.onInfoContainer, t)!,
    );
  }
}
