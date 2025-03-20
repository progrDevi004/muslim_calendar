import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine plattformspezifische Alternative zum FloatingActionButton
/// Auf Android: Standard-FloatingActionButton
/// Auf iOS: Ein CupertinoButton am unteren Bildschirmrand in iOS-Style
class PlatformAdaptiveFAB extends StatelessWidget {
  final IconData androidIcon;
  final IconData iOSIcon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? semanticLabel;

  const PlatformAdaptiveFAB({
    super.key,
    required this.androidIcon,
    required this.iOSIcon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Standard-Farben festlegen, falls keine angegeben wurden
    final Color bgColor = backgroundColor ?? theme.colorScheme.primary;
    final Color fgColor = foregroundColor ?? theme.colorScheme.onPrimary;

    if (Platform.isIOS) {
      // iOS: CupertinoButton mit Container für runden Kreis
      return Positioned(
        right: 16,
        bottom: 16,
        child: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onPressed,
            child: Icon(
              iOSIcon,
              color: fgColor,
              semanticLabel: semanticLabel,
            ),
          ),
        ),
      );
    } else {
      // Android: Standard Material FloatingActionButton
      return FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        child: Icon(
          androidIcon,
          semanticLabel: semanticLabel,
        ),
      );
    }
  }
}

/// Eine Version des FAB, die innerhalb eines Scaffold verwendet werden kann
class PlatformAdaptiveScaffoldFAB {
  final IconData androidIcon;
  final IconData iOSIcon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? semanticLabel;

  const PlatformAdaptiveScaffoldFAB({
    required this.androidIcon,
    required this.iOSIcon,
    required this.onPressed,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
    this.semanticLabel,
  });

  /// Gibt den FloatingActionButton für Android zurück
  Widget? get android => FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: Icon(
          androidIcon,
          semanticLabel: semanticLabel,
        ),
      );

  /// Gibt den iOS-spezifischen Button zurück
  Widget get ios => Container();

  /// Baut das plattformspezifische FAB
  static Widget? buildFAB({
    required IconData androidIcon,
    required IconData iOSIcon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
    Color? foregroundColor,
    String? semanticLabel,
  }) {
    if (Platform.isIOS) {
      // Für iOS geben wir null zurück, weil wir den Button separat hinzufügen werden
      return null;
    } else {
      // Für Android geben wir den standard FloatingActionButton zurück
      return FloatingActionButton(
        onPressed: onPressed,
        tooltip: tooltip,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: Icon(
          androidIcon,
          semanticLabel: semanticLabel,
        ),
      );
    }
  }
}
