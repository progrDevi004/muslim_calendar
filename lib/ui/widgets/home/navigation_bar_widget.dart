import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_navigation.dart';
import 'package:Taqvimi/ui/pages/appointment_creation_page.dart';

class HomeNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexSelected;
  final AppLocalizations localizations;
  final VoidCallback? onAppointmentAdded;

  const HomeNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onIndexSelected,
    required this.localizations,
    this.onAppointmentAdded,
  });

  @override
  Widget build(BuildContext context) {
    // Für iOS verwenden wir eine benutzerdefinierte TabBar mit einem mittigen "+"-Button
    if (Platform.isIOS) {
      return _buildIOSTabBar(context);
    }

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

    // Nutze die plattformadaptive Navigationsleiste (nur für Android)
    return PlatformAdaptiveNavigation.buildBottomNavigation(
      context: context,
      currentIndex: selectedIndex,
      items: items,
      onTap: onIndexSelected,
      activeColor: const Color(0xFF468178), // Logo-Farbe
    );
  }

  // iOS-spezifische TabBar mit einem mittigen "+"-Button
  Widget _buildIOSTabBar(BuildContext context) {
    const Color logoColor = Color(0xFF468178);

    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(color: CupertinoColors.separator),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Dashboard
          _buildIOSTabItem(
            context,
            CupertinoIcons.home,
            localizations.dashboard,
            0,
            selectedIndex == 0,
          ),

          // Day
          _buildIOSTabItem(
            context,
            CupertinoIcons.calendar_today,
            localizations.day,
            1,
            selectedIndex == 1,
          ),

          // Mittiger "+"-Button
          _buildAddButton(context),

          // Week
          _buildIOSTabItem(
            context,
            CupertinoIcons.calendar,
            localizations.week,
            2,
            selectedIndex == 2,
          ),

          // Month
          _buildIOSTabItem(
            context,
            CupertinoIcons.calendar_badge_plus,
            localizations.month,
            3,
            selectedIndex == 3,
          ),
        ],
      ),
    );
  }

  // Einzelner Tab-Item für iOS
  Widget _buildIOSTabItem(BuildContext context, IconData icon, String label,
      int index, bool isSelected) {
    const Color logoColor = Color(0xFF468178);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onIndexSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? logoColor : CupertinoColors.inactiveGray,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? logoColor : CupertinoColors.inactiveGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mittiger "+"-Button für iOS
  Widget _buildAddButton(BuildContext context) {
    const Color logoColor = Color(0xFF468178);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const AppointmentCreationPage(),
          ),
        );

        // Wenn ein Termin hinzugefügt wurde, rufen wir den Callback auf
        if (result == true && onAppointmentAdded != null) {
          onAppointmentAdded!();
        }
      },
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Einfaches, größeres Plus-Icon im nativen iOS-Stil
          Icon(
            CupertinoIcons.add,
            color: logoColor,
            size: 30,
          ),

          // Optional: Text unter dem Icon (wie bei anderen Tab Items)
          SizedBox(height: 4),
          Text(
            "Neu",
            style: TextStyle(
              fontSize: 11,
              color: logoColor,
            ),
          ),
        ],
      ),
    );
  }
}
