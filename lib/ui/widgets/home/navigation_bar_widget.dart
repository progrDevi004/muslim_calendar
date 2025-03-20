import 'package:flutter/material.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';

class HomeNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onIndexSelected;
  final AppLocalizations localizations;

  const HomeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onIndexSelected,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onIndexSelected,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.dashboard),
          label: localizations.dashboard,
        ),
        NavigationDestination(
          icon: const Icon(Icons.view_day),
          label: localizations.day,
        ),
        NavigationDestination(
          icon: const Icon(Icons.view_week),
          label: localizations.week,
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_month),
          label: localizations.month,
        ),
      ],
    );
  }
}
