import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_app_bar.dart';
import 'package:provider/provider.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onQiblaCompassPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onCategoryFilterPressed;
  final VoidCallback onSyncPressed;
  final VoidCallback onMenuPressed;
  final AppLocalizations localizations;

  const HomeAppBar({
    super.key,
    required this.onQiblaCompassPressed,
    required this.onSettingsPressed,
    required this.onCategoryFilterPressed,
    required this.onSyncPressed,
    required this.onMenuPressed,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    // Plattformspezifische Icons für die Aktionen
    final Widget menuIcon = Icon(
      Platform.isIOS ? CupertinoIcons.line_horizontal_3 : Icons.menu,
    );

    // Plattformspezifische Actions
    final List<Widget> actions = Platform.isIOS
        ? [
            // Auf iOS zeigen wir nur ein Mehr-Menü an
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onMenuPressed,
              child: const Icon(CupertinoIcons.ellipsis),
            ),
          ]
        : []; // Auf Android nutzen wir den Drawer, daher keine Actions

    return PlatformAdaptiveAppBar(
      title: Provider.of<AppLocalizations>(context)
          .appTitle, // Festen Titel verwenden, da unser Schlüssel nicht existiert
      leading: GestureDetector(
        onTap: onMenuPressed,
        child: menuIcon,
      ),
      actions: actions,
      centerTitle:
          Platform.isIOS, // Auf iOS zentrieren, auf Android links ausrichten
      onLeadingPressed: onMenuPressed,
    );
  }

  @override
  Size get preferredSize => Platform.isIOS
      ? const Size.fromHeight(44.0) // iOS height
      : const Size.fromHeight(kToolbarHeight); // Android height
}
