import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_navigation.dart';

class HomeNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexSelected;
  final AppLocalizations localizations;

  const HomeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onIndexSelected,
    required this.localizations,
  });

  @override
  Widget build(BuildContext context) {
    // Definiere die Navigationselemente mit plattformspezifischen Icons
    final List<BottomNavigationItem> items = [
      BottomNavigationItem(
        androidIcon: Icons.dashboard,
        iOSIcon: CupertinoIcons.home,
        label: localizations.dashboard,
      ),
      BottomNavigationItem(
        androidIcon: Icons.view_day,
        iOSIcon: CupertinoIcons.calendar_today,
        label: localizations.day,
      ),
      BottomNavigationItem(
        androidIcon: Icons.view_week,
        iOSIcon: CupertinoIcons.calendar,
        label: localizations.week,
      ),
      BottomNavigationItem(
        androidIcon: Icons.view_module,
        iOSIcon: CupertinoIcons.calendar_badge_plus,
        label: localizations.month,
      ),
    ];

    // Nutze die plattformadaptive Navigationsleiste
    return PlatformAdaptiveNavigation.buildBottomNavigation(
      context: context,
      currentIndex: selectedIndex,
      items: items,
      onTap: onIndexSelected,
      activeColor: const Color(0xFF468178), // Logo-Farbe
    );
  }
}
