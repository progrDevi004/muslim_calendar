import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine Helferklasse für plattformadaptive Bottom Sheets
class PlatformAdaptiveBottomSheet {
  /// Zeigt ein einfaches Bottom Sheet an, das sich an die Plattform anpasst
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget title,
    required List<Widget> actions,
    required Widget content,
    bool isDismissible = true,
    bool isScrollControlled = false,
    Color? backgroundColor,
  }) {
    if (Platform.isIOS) {
      // iOS-spezifische Darstellung
      return showCupertinoModalPopup<T>(
        context: context,
        barrierDismissible: isDismissible,
        builder: (context) => _buildIOSBottomSheet(
          context: context,
          title: title,
          actions: actions,
          content: content,
          backgroundColor: backgroundColor,
        ),
      );
    } else {
      // Android-spezifische Darstellung
      return showModalBottomSheet<T>(
        context: context,
        isDismissible: isDismissible,
        isScrollControlled: isScrollControlled,
        backgroundColor: backgroundColor ?? Theme.of(context).cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        builder: (context) => _buildAndroidBottomSheet(
          context: context,
          title: title,
          actions: actions,
          content: content,
        ),
      );
    }
  }

  /// Baut ein iOS-typisches Bottom Sheet
  static Widget _buildIOSBottomSheet({
    required BuildContext context,
    required Widget title,
    required List<Widget> actions,
    required Widget content,
    Color? backgroundColor,
  }) {
    return CupertinoActionSheet(
      title: title,
      message: content,
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        child: const Text('Abbrechen'),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  /// Baut ein Android-typisches Bottom Sheet
  static Widget _buildAndroidBottomSheet({
    required BuildContext context,
    required Widget title,
    required List<Widget> actions,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Griff-Element für bessere User Experience
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // Titel
          DefaultTextStyle(
            style: Theme.of(context).textTheme.titleLarge ?? const TextStyle(),
            child: title,
          ),
          const SizedBox(height: 12),
          // Inhalt
          content,
          const SizedBox(height: 16),
          // Aktionen
          ...actions,
        ],
      ),
    );
  }

  /// Erstellt einen plattformadaptiven Action-Button für Bottom Sheets
  static Widget buildAction({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    bool isDestructiveAction = false,
    bool isDefaultAction = false,
    IconData? icon,
  }) {
    if (Platform.isIOS) {
      return CupertinoActionSheetAction(
        isDestructiveAction: isDestructiveAction,
        isDefaultAction: isDefaultAction,
        onPressed: onPressed,
        child: Text(label),
      );
    } else {
      return ListTile(
        leading: icon != null ? Icon(icon) : null,
        title: Text(
          label,
          style: TextStyle(
            color: isDestructiveAction
                ? Colors.red
                : isDefaultAction
                    ? Theme.of(context).primaryColor
                    : null,
            fontWeight: isDefaultAction ? FontWeight.bold : null,
          ),
        ),
        onTap: onPressed,
      );
    }
  }

  /// Zeigt ein plattformadaptives Menü-Sheet an
  static Future<T?> showMenu<T>({
    required BuildContext context,
    required String title,
    required List<SheetMenuItem> items,
    bool isDismissible = true,
  }) {
    if (Platform.isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        barrierDismissible: isDismissible,
        builder: (context) => CupertinoActionSheet(
          title: Text(title),
          actions:
              items.map((item) => _buildIOSMenuItem(context, item)).toList(),
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } else {
      return showModalBottomSheet<T>(
        context: context,
        isDismissible: isDismissible,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Griff-Element
            Center(
              child: Container(
                height: 4,
                width: 40,
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            // Titel
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            // Menüelemente
            ...items
                .map((item) => _buildAndroidMenuItem(context, item))
                .toList(),
            // Abstand am Ende
            const SizedBox(height: 8),
          ],
        ),
      );
    }
  }

  /// Erstellt ein iOS-Menüelement
  static Widget _buildIOSMenuItem(BuildContext context, SheetMenuItem item) {
    return CupertinoActionSheetAction(
      onPressed: () {
        Navigator.of(context).pop(item.value);
        item.onTap?.call();
      },
      isDestructiveAction: item.isDestructive,
      isDefaultAction: item.isDefault,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (item.iOSIcon != null) Icon(item.iOSIcon, size: 20),
          if (item.iOSIcon != null) const SizedBox(width: 8),
          Text(item.label),
        ],
      ),
    );
  }

  /// Erstellt ein Android-Menüelement
  static Widget _buildAndroidMenuItem(
      BuildContext context, SheetMenuItem item) {
    return ListTile(
      leading: item.androidIcon != null ? Icon(item.androidIcon) : null,
      title: Text(
        item.label,
        style: TextStyle(
          color: item.isDestructive
              ? Colors.red
              : item.isDefault
                  ? Theme.of(context).primaryColor
                  : null,
          fontWeight: item.isDefault ? FontWeight.bold : null,
        ),
      ),
      onTap: () {
        Navigator.of(context).pop(item.value);
        item.onTap?.call();
      },
    );
  }
}

/// Datenklasse für Menüelemente in Bottom Sheets
class SheetMenuItem<T> {
  final String label;
  final T value;
  final bool isDestructive;
  final bool isDefault;
  final IconData? androidIcon;
  final IconData? iOSIcon;
  final VoidCallback? onTap;

  SheetMenuItem({
    required this.label,
    required this.value,
    this.isDestructive = false,
    this.isDefault = false,
    this.androidIcon,
    this.iOSIcon,
    this.onTap,
  });
}
