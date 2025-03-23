import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

// Modelle & Lokalisierung
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/models/enums.dart';
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
import 'package:Taqvimi/data/services/import_settings_service.dart';

// Logo-Farbe für die Konsistenz der App
const Color logoColor = Color(0xFF468178);

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

  const AppDrawer({
    super.key,
    required this.onSettingsOpen,
    required this.onCategoriesSelected,
    required this.onReloadAppointments,
    required this.categories,
    required this.selectedCategoryIds,
    this.onCloseDrawer,
  });

  /// Öffnet die Einstellungsseite
  Future<void> _openSettings(BuildContext context) async {
    // Schließe den Drawer, falls vorhanden
    if (onCloseDrawer != null) {
      onCloseDrawer!();
    } else {
      Navigator.pop(context);
    }

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );

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

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const QiblaCompassPage()),
    );
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

        final localizations =
            Provider.of<AppLocalizations>(globalContext, listen: false);
        final scaffold = ScaffoldMessenger.of(globalContext);
        final calendarSyncService =
            Provider.of<CalendarSyncService>(globalContext, listen: false);

        final Color iconColor = logoColor;

        // Dialog-Inhalt erstellen, der für beide Plattformen passt
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vollständig synchronisieren
            PlatformAdaptiveListTile(
              leading: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.arrow_2_circlepath
                      : Icons.sync,
                  color: iconColor),
              title: localizations.fullSync,
              subtitle: localizations.importAndExport,
              titleStyle:
                  const TextStyle(fontWeight: FontWeight.bold, inherit: true),
              onTap: () async {
                Navigator.pop(globalContext);

                try {
                  // Fortschritt anzeigen
                  scaffold.showSnackBar(
                    SnackBar(
                        content: Text(localizations.syncingWithGoogleCalendar)),
                  );

                  // Vollständige Synchronisation durchführen
                  await calendarSyncService.syncGoogleCalendarNow();

                  // Nach erfolgreicher Synchronisation neu laden
                  onReloadAppointments();

                  scaffold.clearSnackBars();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(localizations.syncCompleted),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  debugPrint('Sync-Fehler: $e');
                  scaffold.clearSnackBars();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(localizations.syncSyncError(e.toString())),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),

            // Nur importieren
            PlatformAdaptiveListTile(
              leading: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.arrow_down_circle
                      : Icons.download,
                  color: iconColor),
              title: localizations.importOnly,
              subtitle: localizations.importFromGoogleCalendar,
              titleStyle:
                  const TextStyle(fontWeight: FontWeight.bold, inherit: true),
              onTap: () {
                Navigator.pop(globalContext);
                calendarSyncService.importAppointments();
                onReloadAppointments();
              },
            ),

            // Nur exportieren
            PlatformAdaptiveListTile(
              leading: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.arrow_up_circle
                      : Icons.upload,
                  color: iconColor),
              title: localizations.exportOnly,
              subtitle: localizations.exportToGoogleCalendar,
              titleStyle:
                  const TextStyle(fontWeight: FontWeight.bold, inherit: true),
              onTap: () async {
                Navigator.pop(globalContext);

                try {
                  // Fortschritt anzeigen
                  scaffold.showSnackBar(
                    SnackBar(
                        content: Text(localizations.exportingToGoogleCalendar)),
                  );

                  // Export durchführen
                  await calendarSyncService.exportAppointments();

                  scaffold.clearSnackBars();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text(localizations.syncExportCompleted ??
                          localizations.exportCompleted),
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

        // Dialog-Aktionen erstellen
        final actions = [
          PlatformAdaptiveDialog.adaptiveDialogAction(
            context: globalContext,
            text: localizations.cancel,
            onPressed: () => Navigator.pop(globalContext),
            color: logoColor,
          ),
        ];

        // Plattformspezifischen Dialog anzeigen
        PlatformAdaptiveDialog.showAdaptiveDialog(
          context: globalContext,
          title: localizations.googleCalendar,
          content: content,
          actions: actions,
        );
      });
    });
  }

  /// Zeigt einen Dialog für Import-Optionen an
  void _showImportOptionsDialog(BuildContext context) {
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

        final localizations =
            Provider.of<AppLocalizations>(globalContext, listen: false);
        final scaffold = ScaffoldMessenger.of(globalContext);
        final Color iconColor = logoColor;

        // Dialog-Inhalt erstellen, der für beide Plattformen passt
        final content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlatformAdaptiveListTile(
              title: localizations.howToHandleCategories,
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                inherit: true,
              ),
            ),

            // Bestehende Kategorien verwenden
            PlatformAdaptiveListTile(
              leading: Icon(
                  Platform.isIOS ? CupertinoIcons.tag : Icons.category_outlined,
                  color: iconColor),
              title: localizations.useExistingCategories,
              subtitle: localizations.searchForMatchingCategories,
              titleStyle:
                  const TextStyle(fontWeight: FontWeight.bold, inherit: true),
              onTap: () async {
                Navigator.pop(globalContext);

                try {
                  // Speichere zuerst die Import-Option
                  await ImportSettingsService.saveImportOption(2);
                  ScaffoldMessenger.of(globalContext).showSnackBar(
                    SnackBar(content: Text(localizations.importOptionSaved)),
                  );
                  // Nach dem Speichern der Option neu laden
                  onReloadAppointments();
                } catch (e) {
                  debugPrint('Fehler beim Speichern der Import-Option: $e');
                }
              },
            ),

            // Neue Kategorien erstellen
            PlatformAdaptiveListTile(
              leading: Icon(
                  Platform.isIOS
                      ? CupertinoIcons.add_circled
                      : Icons.add_circle_outline,
                  color: iconColor),
              title: localizations.createNewCategories,
              subtitle: localizations.forEachNewAppointment,
              titleStyle:
                  const TextStyle(fontWeight: FontWeight.bold, inherit: true),
              onTap: () async {
                Navigator.pop(globalContext);

                try {
                  // Speichere zuerst die Import-Option
                  await ImportSettingsService.saveImportOption(0);
                  ScaffoldMessenger.of(globalContext).showSnackBar(
                    SnackBar(content: Text(localizations.importOptionSaved)),
                  );
                  // Nach dem Speichern der Option neu laden
                  onReloadAppointments();
                } catch (e) {
                  debugPrint('Fehler beim Speichern der Import-Option: $e');
                }
              },
            ),
          ],
        );

        // Dialog-Aktionen erstellen
        final actions = [
          PlatformAdaptiveDialog.adaptiveDialogAction(
            context: globalContext,
            text: localizations.cancel,
            onPressed: () => Navigator.pop(globalContext),
            color: logoColor,
          ),
        ];

        // Plattformspezifischen Dialog anzeigen
        PlatformAdaptiveDialog.showAdaptiveDialog(
          context: globalContext,
          title: localizations.importOptions,
          content: content,
          actions: actions,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (Platform.isIOS) {
      // iOS-spezifischer Drawer (modifiziertes Bottom-Sheet)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(bottom: 16.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5.resolveFrom(context),
                    width: 1.0,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // App Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: logoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.calendar,
                        color: logoColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // App Name
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? 'assets/images/text_dark.png'
                            : 'assets/images/text_light.png',
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        loc.menu,
                        style: TextStyle(
                          fontSize: 14,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Close Button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(CupertinoIcons.xmark_circle_fill,
                        color: CupertinoColors.systemGrey),
                  ),
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

            // PlatformAdaptiveNavigation.buildNavigationItem(
            //   context: context,
            //   title: loc.importOptions,
            //   androidIcon: Icons.settings_applications,
            //   iOSIcon: CupertinoIcons.gear_alt,
            //   iconColor: logoColor,
            //   onTap: () => _showImportOptionsDialog(context),
            // ),
          ],
        ),
      );
    } else {
      // Android Material Design Drawer
      final Color headerColor =
          isDark ? Colors.grey.shade800 : logoColor.withOpacity(0.1);
      final Color iconColor = logoColor;

      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Header
            DrawerHeader(
              decoration: BoxDecoration(
                color: headerColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? 'assets/images/text_dark.png'
                        : 'assets/images/text_light.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loc.menu,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                  ),
                ],
              ),
            ),

            // Einstellungen
            ListTile(
              leading: Icon(Icons.settings, color: iconColor),
              title: Text(loc.settings),
              onTap: () => _openSettings(context),
            ),

            // Qibla Kompass
            ListTile(
              leading: Icon(Icons.explore, color: iconColor),
              title: Text(loc.qiblaCompass),
              onTap: () => _openQiblaCompass(context),
            ),

            // Kategorien
            ListTile(
              leading: Icon(Icons.category, color: iconColor),
              title: Text(loc.categoryLabel),
              onTap: () => _showCategoryFilterDialog(context),
            ),

            const Divider(),

            // Synchronisation
            ListTile(
              leading: Icon(Icons.sync, color: iconColor),
              title: Text(loc.synchronization),
              onTap: () => _showSyncOptionsDialog(context),
            ),

            // // Import-Optionen
            // ListTile(
            //   leading: Icon(Icons.settings_applications, color: iconColor),
            //   title: Text(loc.importOptions),
            //   onTap: () => _showImportOptionsDialog(context),
            // ),

            // Weitere Trennlinie am Ende
            const Divider(),
          ],
        ),
      );
    }
  }
}
