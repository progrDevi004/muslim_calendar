import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'platform_adaptive_theme.dart';

/// Ein plattformadaptiver Switch, der auf iOS einen CupertinoSwitch und auf Android einen Switch zeigt.
class PlatformAdaptiveSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final Color? trackColor;
  final String? label;
  final Widget? icon;
  final bool useListTile;

  const PlatformAdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.trackColor,
    this.label,
    this.icon,
    this.useListTile = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIOS = Platform.isIOS;

    // Switch-Widget selbst erstellen
    Widget switchWidget;

    if (isIOS) {
      // iOS-spezifischer Switch
      switchWidget = CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? PlatformAdaptiveTheme.seedColor,
        trackColor: trackColor,
      );
    } else {
      // Android-spezifischer Switch
      switchWidget = Switch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor ?? PlatformAdaptiveTheme.seedColor,
        activeTrackColor: activeColor != null
            ? activeColor!.withOpacity(0.5)
            : PlatformAdaptiveTheme.seedColor.withOpacity(0.5),
        inactiveTrackColor: trackColor,
      );
    }

    // Wenn kein Label benötigt wird, nur den Switch zurückgeben
    if (!useListTile || (label == null && icon == null)) {
      return switchWidget;
    }

    // Mit ListTile für ein komplettes Element mit Label und Icon
    if (isIOS) {
      // iOS-spezifisches ListTile mit CupertinoSwitch
      return Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.systemGrey5.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: PlatformAdaptiveTheme.defaultSpacing,
          vertical: PlatformAdaptiveTheme.defaultSpacing * 0.75,
        ),
        child: Row(
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: icon!,
              ),
            if (label != null)
              Expanded(
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            switchWidget,
          ],
        ),
      );
    } else {
      // Android-spezifisches SwitchListTile
      return SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: label != null ? Text(label!) : null,
        secondary: icon,
        activeColor: activeColor ?? PlatformAdaptiveTheme.seedColor,
        activeTrackColor: activeColor != null
            ? activeColor!.withOpacity(0.5)
            : PlatformAdaptiveTheme.seedColor.withOpacity(0.5),
        inactiveTrackColor: trackColor,
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
