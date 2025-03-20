import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Helferklasse zur Anzeige plattformspezifischer Dialoge
class PlatformAdaptiveDialog {
  /// Zeigt einen plattformspezifischen Dialog an (Material oder Cupertino)
  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool barrierDismissible = true,
  }) async {
    if (Platform.isIOS) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: content,
          actions: actions ??
              [
                CupertinoDialogAction(
                  child: const Text('Abbrechen'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
        ),
      );
    } else {
      return showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: content,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: actions,
        ),
      );
    }
  }

  /// Erstellt eine plattformspezifische Aktion für Dialoge
  static Widget adaptiveDialogAction({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    bool isDefaultAction = false,
    bool isDestructiveAction = false,
    Color? color,
  }) {
    if (Platform.isIOS) {
      return CupertinoDialogAction(
        child: Text(text),
        onPressed: onPressed,
        isDefaultAction: isDefaultAction,
        isDestructiveAction: isDestructiveAction,
      );
    } else {
      return TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
        ),
        child: Text(text),
      );
    }
  }
}
