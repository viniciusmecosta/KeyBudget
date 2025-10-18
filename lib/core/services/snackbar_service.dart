import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';

class SnackbarService {
  static void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    Color textColor,
  ) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.down,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusL),
          ),
          margin: const EdgeInsets.fromLTRB(
            AppTheme.spaceM,
            0,
            AppTheme.spaceM,
            95.0,
          ),
        ),
      );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.onError,
    );
  }

  static void showSuccess(BuildContext context, String message) {
    // _showSnackBar(
    //   context,
    //   message,
    //   Colors.green.shade600,
    //   Colors.white,
    // );
  }

  static void showInfo(BuildContext context, String message) {
    // _showSnackBar(
    //   context,
    //   message,
    //   Colors.blue.shade600,
    //   Colors.white,
    // );
  }

  static void showWarning(BuildContext context, String message) {
    // Não exibir snackbar de aviso
    // _showSnackBar(
    //   context,
    //   message,
    //   Colors.orange.shade600,
    //   Colors.white,
    // );
  }
}
