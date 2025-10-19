import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';

class SnackbarService {
  static void showSnackbar(
    BuildContext context,
    String message, {
    String? title,
    Color? backgroundColor,
    Color? textColor,
  }) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null)
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textColor ?? Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor ?? Theme.of(context).colorScheme.onError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          backgroundColor:
              backgroundColor ?? Theme.of(context).colorScheme.primary,
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

  static void showError(BuildContext context, String message, {String? title}) {
    showSnackbar(
      context,
      message,
      title: title,
      backgroundColor: Theme.of(context).colorScheme.error,
      textColor: Theme.of(context).colorScheme.onError,
    );
  }

  static void showSuccess(BuildContext context, String message,
      {String? title}) {
    showSnackbar(
      context,
      message,
      title: title,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
    );
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    showSnackbar(
      context,
      message,
      title: title,
      backgroundColor: Colors.blue.shade600,
      textColor: Colors.white,
    );
  }

  static void showWarning(BuildContext context, String message,
      {String? title}) {
    showSnackbar(
      context,
      message,
      title: title,
      backgroundColor: Colors.orange.shade600,
      textColor: Colors.white,
    );
  }
}
