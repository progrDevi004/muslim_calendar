import 'package:flutter/material.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onQiblaCompassPressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onCategoryFilterPressed;
  final AppLocalizations localizations;

  const HomeAppBar({
    Key? key,
    required this.onQiblaCompassPressed,
    required this.onSettingsPressed,
    required this.onCategoryFilterPressed,
    required this.localizations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.explore),
          onPressed: onQiblaCompassPressed,
          tooltip: 'Qibla Compass',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: onSettingsPressed,
          tooltip: localizations.settings,
        ),
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: onCategoryFilterPressed,
          tooltip: localizations.filterCategories,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
