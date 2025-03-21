import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_adaptive_theme.dart';

/// Eine plattformspezifische Card-Komponente, die auf iOS und Android unterschiedlich aussieht
class PlatformAdaptiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const PlatformAdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS;
    final double defaultRadius = PlatformAdaptiveTheme.borderRadius;

    // iOS-spezifisches Design
    if (isIOS) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          margin:
              margin ?? EdgeInsets.all(PlatformAdaptiveTheme.defaultSpacing),
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color ?? CupertinoColors.systemBackground,
            borderRadius: borderRadius ?? BorderRadius.circular(defaultRadius),
            border: Border.all(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              width: 0.5,
            ),
            boxShadow: elevation != null && elevation! > 0
                ? [
                    BoxShadow(
                      color: CupertinoColors.systemGrey5
                          .resolveFrom(context)
                          .withOpacity(0.3),
                      blurRadius: elevation! * 2,
                      offset: Offset(0, elevation! / 2),
                    )
                  ]
                : null,
          ),
          child: child,
        ),
      );
    }

    // Android-spezifisches Design (Material Design)
    return Card(
      elevation: elevation ?? 1.0,
      margin: margin ?? const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
      ),
      color: color,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    );
  }
}
