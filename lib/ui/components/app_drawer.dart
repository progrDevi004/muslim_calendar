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
import 'package:Taqvimi/ui/widgets/home/category_filter_dialog.dart';

// Services
import 'package:Taqvimi/data/services/calendar_sync_service.dart';

// Logo-Farbe für die Konsistenz der App
const Color logoColor = Color(0xFF468178);

// Enum für aktuelle Seite
enum CurrentPage {
  calendar,
  projectManagement,
  other
} //Statt Projectmanagement später ToDo Page einfügen

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
                leading: const Icon(Icons.sync_outlined),
                title: localizations.fullSync,
                subtitle: localizations.importAndExport,
                titleStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                leading: const Icon(Icons.download),
                title: localizations.importOnly,
                subtitle: localizations.importFromCalendar,
                titleStyle: const TextStyle(fontWeight: FontWeight.bold),
                onTap: () {
                  Navigator.pop(context);
                  calendarSyncService.importAppointments();
                  onReloadAppointments();
                },
              ),
              PlatformAdaptiveListTile(
                leading: const Icon(Icons.import_export_outlined),
                title: localizations.exportOnly,
                subtitle: localizations.exportToCalendar,
                titleStyle: const TextStyle(fontWeight: FontWeight.bold),
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

  // Hilfsmethode zum Erstellen von PlatformAdaptiveListTile mit korrekten Dark Mode-Farben
  Widget _buildMenuTile(
    BuildContext context, {
    required String title,
    required IconData androidIcon,
    required IconData iOSIcon,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final iconColor = logoColor;

    return PlatformAdaptiveListTile(
      title: title,
      subtitle: subtitle,
      leading: Icon(
        Platform.isIOS ? iOSIcon : androidIcon,
        color: iconColor,
      ),
      titleStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: textColor, // Explizite Textfarbe
      ),
      subtitleStyle: subtitle != null
          ? TextStyle(
              color: textColor
                  .withOpacity(0.7), // Explizite Subtitlefarbe mit Transparency
            )
          : null,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.white;

    return Drawer(
      backgroundColor: backgroundColor, // Expliziter Hintergrund für Dark Mode
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header mit Logo und App-Namen
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: logoColor,
                    radius: 25,
                    child: Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taqvimi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor, // Dynamische Textfarbe
                        ),
                      ),
                      Text(
                        'Muslim Calendar App',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(
                              0.7), // Dynamische Textfarbe mit Opacity
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Menu Items
            const Divider(),

            // Navigationseinträge mit expliziten Dark Mode-Anpassungen
            _buildMenuTile(
              context,
              title: localizations.settings,
              androidIcon: Icons.settings,
              iOSIcon: CupertinoIcons.settings,
              onTap: () => _openSettings(context),
            ),

            _buildMenuTile(
              context,
              title: localizations.categoryLabel,
              androidIcon: Icons.category,
              iOSIcon: CupertinoIcons.tag,
              onTap: () => _showCategoryFilterDialog(context),
            ),

            _buildMenuTile(
              context,
              title: localizations.synchronization,
              androidIcon: Icons.sync,
              iOSIcon: CupertinoIcons.arrow_2_circlepath,
              onTap: () => _showSyncOptionsDialog(context),
            ),

            const Divider(),
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
