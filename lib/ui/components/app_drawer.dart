import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// Modelle & Lokalisierung
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/models/category_model.dart';

// Komponenten
import 'package:Taqvimi/ui/components/platform_adaptive_navigation.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_list_tile.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_dialog.dart';

// Seiten für Navigation
import 'package:Taqvimi/ui/pages/settings_page.dart';
import 'package:Taqvimi/ui/pages/qibla_compass_page.dart';
import 'package:Taqvimi/ui/widgets/home/category_filter_dialog.dart';

// Services
import 'package:Taqvimi/data/services/calendar_sync_service.dart';

// Logo-Farbe für die Konsistenz der App
const Color logoColor = Color(0xFF468178);

// Enum für aktuelle Seite
enum CurrentPage { calendar, projectManagement, other }

/// Gemeinsames Menü für Dashboard und Home Page
/// Diese Komponente kann in beiden Seiten verwendet werden und bietet das gleiche Menü
class AppDrawer extends StatelessWidget {
  /// Callback für das Öffnen der Einstellungen
  final Function() onSettingsOpen;

  /// Callback für die Kategoriefilterung
  final Function(Set<int>) onCategoriesSelected;

  /// Callback zum Neuladen der Termine nach Änderungen
  final Function() onReloadAppointments;

  /// Callback zum Schließen des Dialogs vor bestimmten Aktionen
  final Function()? onCloseDrawer;

  /// Liste der Kategorien für den Filter
  final List<CategoryModel> categories;

  /// Set der bereits ausgewählten Kategorie-IDs
  final Set<int> selectedCategoryIds;

  /// Aktuelle Seite zur Steuerung der Menüpunkte
  final CurrentPage currentPage;

  const AppDrawer({
    super.key,
    required this.onSettingsOpen,
    required this.onCategoriesSelected,
    required this.onReloadAppointments,
    required this.categories,
    required this.selectedCategoryIds,
    this.onCloseDrawer,
    this.currentPage = CurrentPage.calendar,
  });

  /// Öffnet die Einstellungsseite
  Future<void> _openSettings(BuildContext context) async {
    // Schließe den Drawer, falls vorhanden
    if (onCloseDrawer != null) {
      onCloseDrawer!();
    } else {
      Navigator.pop(context);
    }

    // Speichern der Route, um keinen BuildContext über async gap zu verwenden
    final route = MaterialPageRoute(builder: (context) => const SettingsPage());

    await Navigator.of(context).push(route);

    // Callback für Settings-Update
    onSettingsOpen();
  }

  /// Öffnet den Qibla-Kompass
  Future<void> _openQiblaCompass(BuildContext context) async {
    // Schließe den Drawer, falls vorhanden
    if (onCloseDrawer != null) {
      onCloseDrawer!();
    } else {
      Navigator.pop(context);
    }

    // Speichern der Route, um keinen BuildContext über async gap zu verwenden
    final route =
        MaterialPageRoute(builder: (context) => const QiblaCompassPage());

    await Navigator.of(context).push(route);
  }

  /// Zeigt den Dialog zum Filtern nach Kategorien an
  void _showCategoryFilterDialog(BuildContext context) {
    // Schließe den Drawer, falls vorhanden
    if (onCloseDrawer != null) {
      onCloseDrawer!();
    } else {
      Navigator.pop(context);
    }

    // Zuerst den BuildContext für später speichern, da der ursprüngliche Kontext nach Navigator.pop()
    // nicht mehr gültig sein könnte
    final globalContext = Navigator.of(context).context;

    // Verzögerung hinzufügen, um sicherzustellen, dass der Drawer vollständig geschlossen ist
    Future.delayed(const Duration(milliseconds: 300), () {
      // Sicherstellen, dass der Kontext noch gültig ist
      if (!Navigator.canPop(globalContext) &&
          !Navigator.of(globalContext).mounted) return;

      // Explizit den aktuellen Fokus zurücksetzen
      FocusManager.instance.primaryFocus?.unfocus();

      // Dialog in einem separaten Future.microtask anzeigen, um die Trennung vom vorherigen Frame zu gewährleisten
      Future.microtask(() {
        if (!Navigator.of(globalContext).mounted) return;

        showDialog(
          context: globalContext,
          barrierDismissible: true,
          builder: (ctx) {
            return CategoryFilterDialog(
              categories: categories,
              selectedCategoryIds: selectedCategoryIds,
              onCategoriesSelected: (selectedIds) {
                onCategoriesSelected(selectedIds);
                // Nach der Kategorieänderung Termine neu laden
                onReloadAppointments();
              },
              onCategoriesChanged: () {
                // Nach der Kategorieänderung Termine neu laden
                onReloadAppointments();
              },
            );
          },
        );
      });
    });
  }

  /// Zeigt das Synchronisationsmenü an
  void _showSyncOptionsDialog(BuildContext context) {
    // Schließe den Drawer, falls vorhanden
    if (onCloseDrawer != null) {
      onCloseDrawer!();
    } else {
      Navigator.pop(context);
    }

    final globalContext = Navigator.of(context).context;
    final localizations =
        Provider.of<AppLocalizations>(globalContext, listen: false);
    final scaffold = ScaffoldMessenger.of(globalContext);
    final calendarSyncService =
        Provider.of<CalendarSyncService>(globalContext, listen: false);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!Navigator.canPop(globalContext) &&
          !Navigator.of(globalContext).mounted) return;
      FocusManager.instance.primaryFocus?.unfocus();

      Future.microtask(() {
        if (!Navigator.of(globalContext).mounted) return;

        if (Platform.isIOS) {
          showCupertinoModalPopup(
            context: globalContext,
            builder: (BuildContext context) => CupertinoActionSheet(
              title: Text(
                localizations.synchronization,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                CupertinoActionSheetAction(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.arrow_2_circlepath,
                          color: logoColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.fullSync,
                              style: const TextStyle(color: logoColor),
                            ),
                            Text(
                              localizations.importAndExport,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      scaffold.showSnackBar(
                        SnackBar(
                            content:
                                Text(localizations.syncingWithGoogleCalendar)),
                      );
                      await calendarSyncService.syncGoogleCalendarNow();
                      onReloadAppointments();
                      if (scaffold.mounted) {
                        scaffold.clearSnackBars();
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(localizations.syncCompleted),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Sync-Fehler: $e');
                      if (scaffold.mounted) {
                        scaffold.clearSnackBars();
                        scaffold.showSnackBar(
                          SnackBar(
                            content:
                                Text(localizations.syncSyncError(e.toString())),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                CupertinoActionSheetAction(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.arrow_down_circle,
                          color: logoColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.importOnly,
                              style: const TextStyle(color: logoColor),
                            ),
                            Text(
                              localizations.importFromCalendar,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    calendarSyncService.importAppointments();
                    onReloadAppointments();
                  },
                ),
                CupertinoActionSheetAction(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.arrow_up_circle,
                          color: logoColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizations.exportOnly,
                              style: const TextStyle(color: logoColor),
                            ),
                            Text(
                              localizations.exportToCalendar,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    try {
                      scaffold.showSnackBar(
                        SnackBar(
                            content:
                                Text(localizations.exportingToGoogleCalendar)),
                      );
                      await calendarSyncService.exportAppointments();
                      scaffold.clearSnackBars();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(localizations.syncExportCompleted),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      debugPrint('Export-Fehler: $e');
                      scaffold.clearSnackBars();
                      scaffold.showSnackBar(
                        SnackBar(
                          content:
                              Text(localizations.exportError(e.toString())),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(localizations.cancel),
              ),
            ),
          );
        } else {
          // Bestehender Android-Dialog-Code bleibt unverändert
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlatformAdaptiveListTile(
                leading: const Icon(Icons.sync, color: logoColor),
                title: localizations.fullSync,
                subtitle: localizations.importAndExport,
                titleStyle:
                    const TextStyle(fontWeight: FontWeight.bold, inherit: true),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    scaffold.showSnackBar(
                      SnackBar(
                          content:
                              Text(localizations.syncingWithGoogleCalendar)),
                    );
                    await calendarSyncService.syncGoogleCalendarNow();
                    onReloadAppointments();
                    if (scaffold.mounted) {
                      scaffold.clearSnackBars();
                      scaffold.showSnackBar(
                        SnackBar(
                          content: Text(localizations.syncCompleted),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('Sync-Fehler: $e');
                    if (scaffold.mounted) {
                      scaffold.clearSnackBars();
                      scaffold.showSnackBar(
                        SnackBar(
                          content:
                              Text(localizations.syncSyncError(e.toString())),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              PlatformAdaptiveListTile(
                leading: const Icon(Icons.download, color: logoColor),
                title: localizations.importOnly,
                subtitle: localizations.importFromCalendar,
                titleStyle:
                    const TextStyle(fontWeight: FontWeight.bold, inherit: true),
                onTap: () {
                  Navigator.pop(context);
                  calendarSyncService.importAppointments();
                  onReloadAppointments();
                },
              ),
              PlatformAdaptiveListTile(
                leading: const Icon(Icons.upload, color: logoColor),
                title: localizations.exportOnly,
                subtitle: localizations.exportToCalendar,
                titleStyle:
                    const TextStyle(fontWeight: FontWeight.bold, inherit: true),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    scaffold.showSnackBar(
                      SnackBar(
                          content:
                              Text(localizations.exportingToGoogleCalendar)),
                    );
                    await calendarSyncService.exportAppointments();
                    scaffold.clearSnackBars();
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text(localizations.syncExportCompleted),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    debugPrint('Export-Fehler: $e');
                    scaffold.clearSnackBars();
                    scaffold.showSnackBar(
                      SnackBar(
                        content: Text(localizations.exportError(e.toString())),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
            ],
          );

          final actions = [
            PlatformAdaptiveDialog.adaptiveDialogAction(
              context: globalContext,
              text: localizations.cancel,
              onPressed: () => Navigator.pop(context),
              color: logoColor,
            ),
          ];

          PlatformAdaptiveDialog.showAdaptiveDialog(
            context: globalContext,
            title: localizations.synchronization,
            content: content,
            actions: actions,
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;
    final theme = Theme.of(context);
    final loc = Provider.of<AppLocalizations>(context);

    return Drawer(
      backgroundColor: isIOS
          ? CupertinoColors.systemBackground
          : theme.drawerTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Logo und Titel
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isIOS
                    ? CupertinoColors.systemBackground
                    : theme.drawerTheme.backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color:
                        isIOS ? CupertinoColors.separator : theme.dividerColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/text_dark.png'
                        : 'assets/images/text_light.png',
                    height: 30,
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            PlatformAdaptiveNavigation.buildNavigationItem(
              context: context,
              title: loc.settings,
              androidIcon: Icons.settings,
              iOSIcon: CupertinoIcons.settings,
              iconColor: logoColor,
              onTap: () => _openSettings(context),
            ),

            PlatformAdaptiveNavigation.buildNavigationItem(
              context: context,
              title: loc.qiblaCompass,
              androidIcon: Icons.explore,
              iOSIcon: CupertinoIcons.compass,
              iconColor: logoColor,
              onTap: () => _openQiblaCompass(context),
            ),

            PlatformAdaptiveNavigation.buildNavigationItem(
              context: context,
              title: loc.categoryLabel,
              androidIcon: Icons.category,
              iOSIcon: CupertinoIcons.tag,
              iconColor: logoColor,
              onTap: () => _showCategoryFilterDialog(context),
            ),

            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),

            PlatformAdaptiveNavigation.buildNavigationItem(
              context: context,
              title: loc.synchronization,
              androidIcon: Icons.sync,
              iOSIcon: CupertinoIcons.arrow_2_circlepath,
              iconColor: logoColor,
              onTap: () => _showSyncOptionsDialog(context),
            ),

            // Kalender- oder Projektmanagement-Navigation, je nach aktueller Seite
            if (currentPage == CurrentPage.projectManagement)
              // Kalenderverwaltung anzeigen, wenn auf Projektmanagement-Seite
              _buildDrawerItem(
                context: context,
                icon: Platform.isIOS
                    ? CupertinoIcons.calendar
                    : Icons.calendar_today,
                title: loc.calendar ?? 'Kalender',
                onTap: () {
                  if (onCloseDrawer != null) {
                    onCloseDrawer!();
                  } else {
                    Navigator.pop(context);
                  }
                  Navigator.pushNamed(context, '/');
                },
              ),

            // Projektmanagement anzeigen, wenn nicht auf Projektmanagement-Seite
            _buildDrawerItem(
              context: context,
              icon: Platform.isIOS
                  ? CupertinoIcons.chart_bar
                  : Icons.stacked_bar_chart,
              title: loc.projectManagement ?? 'Projektmanagement',
              onTap: () {
                if (onCloseDrawer != null) {
                  onCloseDrawer!();
                } else {
                  Navigator.pop(context);
                }
                Navigator.pushNamed(context, '/project-management');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Function() onTap,
  }) {
    return PlatformAdaptiveNavigation.buildNavigationItem(
      context: context,
      title: title,
      androidIcon: icon,
      iOSIcon: icon,
      iconColor: logoColor,
      onTap: onTap,
    );
  }
}
