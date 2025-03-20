import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine plattformspezifische Switch-Komponente
/// Auf Android: Material Switch
/// Auf iOS: CupertinoSwitch
class PlatformAdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? inactiveTrackColor;
  final bool autofocus;
  final String? semanticLabel;

  const PlatformAdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.inactiveTrackColor,
    this.autofocus = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = activeColor ?? theme.colorScheme.primary;

    if (Platform.isIOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        trackColor: inactiveTrackColor,
      );
    } else {
      return Switch(
        value: value,
        onChanged: onChanged,
        activeColor: color,
        inactiveTrackColor: inactiveTrackColor,
        autofocus: autofocus,
      );
    }
  }
}

/// Eine Switch-Komponente mit einer Beschriftung (wie SwitchListTile, aber plattformadaptiv)
class PlatformAdaptiveSwitchTile extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget title;
  final Widget? subtitle;
  final EdgeInsetsGeometry? contentPadding;
  final Color? activeColor;
  final bool autofocus;

  const PlatformAdaptiveSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.contentPadding,
    this.activeColor,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = activeColor ?? theme.colorScheme.primary;

    if (Platform.isIOS) {
      return Padding(
        padding: contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DefaultTextStyle(
                    style: theme.textTheme.bodyLarge!,
                    child: title,
                  ),
                  if (subtitle != null)
                    DefaultTextStyle(
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                      child: subtitle!,
                    ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: color,
            ),
          ],
        ),
      );
    } else {
      return SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: title,
        subtitle: subtitle,
        contentPadding: contentPadding,
        activeColor: color,
        autofocus: autofocus,
      );
    }
  }
}
