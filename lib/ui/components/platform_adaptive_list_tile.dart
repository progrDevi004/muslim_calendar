import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Helferklasse für plattformübergreifende ListTile-Implementierungen
class PlatformAdaptiveListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool enabled;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  const PlatformAdaptiveListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.enabled = true,
    this.titleStyle,
    this.subtitleStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return _buildIOSListTile(context);
    } else {
      return _buildMaterialListTile(context);
    }
  }

  Widget _buildIOSListTile(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 16.0),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: titleStyle ??
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: enabled
                              ? null
                              : CupertinoColors.inactiveGray
                                  .resolveFrom(context),
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4.0),
                    Text(
                      subtitle!,
                      style: subtitleStyle ??
                          theme.textTheme.bodySmall?.copyWith(
                            color: enabled
                                ? CupertinoColors.secondaryLabel
                                    .resolveFrom(context)
                                : CupertinoColors.inactiveGray
                                    .resolveFrom(context),
                          ),
                    ),
                  ],
                ],
              ),
            ),
            if (onTap != null && enabled)
              const Icon(
                CupertinoIcons.forward,
                size: 18.0,
                color: CupertinoColors.systemGrey,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialListTile(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: titleStyle,
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: subtitleStyle,
            )
          : null,
      onTap: onTap,
      enabled: enabled,
    );
  }
}
