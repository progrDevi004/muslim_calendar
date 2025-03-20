import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine Helferklasse für plattformspezifische Navigationselemente
/// Bietet Funktionen für DrawerMenu (Android) und BottomSheet-Menü (iOS)
class PlatformAdaptiveNavigation {
  /// Zeigt ein Navigationsmenü an, das sich an die Plattform anpasst.
  /// Für iOS wird ein ModalBottomSheet angezeigt, für Android wird der Drawer geöffnet.
  static void showNavigationMenu({
    required BuildContext context,
    required Widget drawerContent,
    required Widget iOSMenuContent,
    bool barrierDismissible = true,
  }) {
    if (Platform.isIOS) {
      // Für iOS ein modales Bottom Sheet anzeigen
      showModalBottomSheet(
        context: context,
        barrierColor: Colors.black54.withOpacity(0.5),
        backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
        isDismissible: barrierDismissible,
        builder: (context) => iOSMenuContent,
      );
    } else {
      // Für Android den Drawer öffnen (muss im Scaffold definiert sein)
      if (Scaffold.of(context).hasDrawer) {
        Scaffold.of(context).openDrawer();
      }
    }
  }

  /// Baut ein Navigationselement, das sich an die Plattform anpasst.
  /// Für iOS wird ein angepasstes Design verwendet, für Android ein ListTile.
  static Widget buildNavigationItem({
    required BuildContext context,
    required String title,
    required IconData androidIcon,
    required IconData iOSIcon,
    required VoidCallback onTap,
    Color? iconColor,
    bool isActive = false,
  }) {
    if (Platform.isIOS) {
      final color = isActive
          ? CupertinoColors.activeBlue
          : CupertinoColors.label.resolveFrom(context);

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive
                ? CupertinoColors.systemGrey6.resolveFrom(context)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                iOSIcon,
                color: iconColor ?? color,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  color: color,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isActive)
                const Icon(
                  CupertinoIcons.check_mark,
                  color: CupertinoColors.activeBlue,
                  size: 18,
                ),
            ],
          ),
        ),
      );
    } else {
      // Android-Stil: ListTile
      return ListTile(
        leading: Icon(
          androidIcon,
          color:
              iconColor ?? (isActive ? Theme.of(context).primaryColor : null),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            color: isActive ? Theme.of(context).primaryColor : null,
          ),
        ),
        selected: isActive,
        onTap: onTap,
      );
    }
  }

  /// Baut eine Bottom-Navigation, die sich an die Plattform anpasst.
  /// Für iOS wird eine CupertinoTabBar verwendet, für Android eine BottomNavigationBar.
  static Widget buildBottomNavigation({
    required BuildContext context,
    required int currentIndex,
    required List<BottomNavigationItem> items,
    required Function(int) onTap,
    Color? activeColor,
    Color? inactiveColor,
    Color? backgroundColor,
  }) {
    if (Platform.isIOS) {
      return CupertinoTabBar(
        currentIndex: currentIndex,
        onTap: onTap,
        activeColor: activeColor ?? CupertinoColors.activeBlue,
        inactiveColor: inactiveColor ?? CupertinoColors.inactiveGray,
        backgroundColor: backgroundColor,
        items: items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.iOSIcon),
                label: item.label,
              ),
            )
            .toList(),
      );
    } else {
      return BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: activeColor,
        unselectedItemColor: inactiveColor,
        backgroundColor: backgroundColor,
        type: BottomNavigationBarType.fixed,
        items: items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Icon(item.androidIcon),
                label: item.label,
              ),
            )
            .toList(),
      );
    }
  }
}

/// Datenklasse für die Bottom-Navigation-Items
class BottomNavigationItem {
  final IconData androidIcon;
  final IconData iOSIcon;
  final String label;

  BottomNavigationItem({
    required this.androidIcon,
    required this.iOSIcon,
    required this.label,
  });
}
