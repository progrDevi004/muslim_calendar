import 'package:flutter/material.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

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
    return AppBar(
      centerTitle: false,
      title: const Text(
        'Muslim Calendar',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
      ),
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
