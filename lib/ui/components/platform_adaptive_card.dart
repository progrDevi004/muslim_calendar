import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine plattformspezifische Card-Komponente
/// Auf Android: Material Card
/// Auf iOS: Container mit abgerundeten Ecken und Schatten im iOS-Stil
class PlatformAdaptiveCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool semanticContainer;

  const PlatformAdaptiveCard({
    super.key,
    required this.child,
    this.color,
    this.margin,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.semanticContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Standardwerte festlegen
    final Color cardColor = color ?? theme.cardColor;
    final BorderRadius radius = borderRadius ?? BorderRadius.circular(12.0);
    final double cardElevation = elevation ?? 1.0;

    if (Platform.isIOS) {
      // iOS-Stil mit Container
      return Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: cardElevation * 3,
              offset: Offset(0, cardElevation),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        child: child,
      );
    } else {
      // Android-Stil mit Material Card
      return Card(
        color: cardColor,
        margin: margin,
        elevation: cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
        ),
        semanticContainer: semanticContainer,
        child: padding != null
            ? Padding(
                padding: padding as EdgeInsets,
                child: child,
              )
            : child,
      );
    }
  }
}
