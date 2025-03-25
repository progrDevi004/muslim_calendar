import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class PlatformAdaptiveScaffoldFAB {
  static Widget buildFAB({
    required BuildContext context,
    required VoidCallback onPressed,
    required IconData androidIcon,
    required IconData iOSIcon,
    Color? backgroundColor,
    Color? foregroundColor,
  }) {
    if (Platform.isIOS) {
      return Positioned(
        right: 16,
        bottom: 16,
        child: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: backgroundColor ?? CupertinoTheme.of(context).primaryColor,
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
              color: foregroundColor ?? CupertinoColors.white,
              size: 30,
            ),
          ),
        ),
      );
    } else {
      return FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
        child: Icon(
          androidIcon,
          color: foregroundColor ?? Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }
  }
}
