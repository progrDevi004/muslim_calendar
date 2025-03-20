import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine plattformspezifische AppBar, die je nach Plattform eine Material AppBar
/// oder eine CupertinoNavigationBar anzeigt.
class PlatformAdaptiveAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final VoidCallback? onLeadingPressed;
  final bool centerTitle;
  final double? elevation;
  final TextStyle? titleTextStyle;
  final Color? iconColor;

  const PlatformAdaptiveAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.onLeadingPressed,
    this.centerTitle = true,
    this.elevation,
    this.titleTextStyle,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    if (Platform.isIOS) {
      return CupertinoNavigationBar(
        middle: Text(
          title,
          style: titleTextStyle ??
              TextStyle(
                color: theme.brightness == Brightness.dark
                    ? CupertinoColors.white
                    : CupertinoColors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: leading != null
            ? GestureDetector(
                onTap: onLeadingPressed,
                child: leading,
              )
            : null,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
        backgroundColor: backgroundColor ??
            (theme.brightness == Brightness.dark
                ? CupertinoColors.black
                : CupertinoColors.white),
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.separator,
            width: 0.0,
          ),
        ),
      );
    } else {
      return AppBar(
        title: Text(
          title,
          style: titleTextStyle ??
              theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        leading: leading != null
            ? IconButton(
                icon: leading as Widget,
                onPressed: onLeadingPressed,
              )
            : null,
        actions: actions,
        backgroundColor: backgroundColor,
        elevation: elevation ?? 0,
        centerTitle: centerTitle,
        iconTheme: iconColor != null ? IconThemeData(color: iconColor) : null,
      );
    }
  }

  @override
  Size get preferredSize {
    if (Platform.isIOS) {
      return const Size.fromHeight(44.0);
    } else {
      return const Size.fromHeight(kToolbarHeight);
    }
  }
}
