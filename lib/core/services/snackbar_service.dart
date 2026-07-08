import 'package:flutter/material.dart';
import 'package:key_budget/app/config/app_theme.dart';

class SnackbarService {
  static const Duration _defaultDuration = Duration(seconds: 3);

  static void showSnackbar(BuildContext context,
      String message, {
        String? title,
        Color? backgroundColor,
        Color? textColor,
        SnackBarAction? action,
        Duration? duration,
      }) {
    final messenger = ScaffoldMessenger.of(context);
    final displayDuration = duration ?? _defaultDuration;

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          action: action,
          duration: displayDuration,
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
          backgroundColor ?? Theme
              .of(context)
              .colorScheme
              .primary,
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

    Future.delayed(displayDuration, () {
      try {
        messenger.hideCurrentSnackBar();
      } catch (_) {}
    });
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

  static void showSuccess(BuildContext context,
      String message, {
        String? title,
        SnackBarAction? action,
        Duration? duration,
      }) {
    showSnackbar(
      context,
      message,
      title: title,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      action: action,
      duration: duration,
    );
  }

  static void showUndoSnackbar(BuildContext context, {
    required String message,
    required VoidCallback onUndo,
  }) {
    showSuccess(
      context,
      message,
      duration: const Duration(seconds: 3),
      action: SnackBarAction(
        label: 'Desfazer',
        textColor: Colors.white,
        onPressed: onUndo,
      ),
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