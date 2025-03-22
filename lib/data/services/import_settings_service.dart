import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_dialog.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_list_tile.dart';

class ImportSettingsService {
  // Logo-Farbe für die Konsistenz der App
  static const Color logoColor = Color(0xFF468178);

  static const String _importOptionKey = 'google_calendar_import_option';

  /// Speichert die ausgewählte Import-Option
  /// 0: Standardkategorie verwenden
  /// 1: Google-Farben als Kategorien verwenden
  /// 2: Automatisches Mapping nach Kalendername (Kategorien von Google Kalender übernehmen)
  static Future<void> saveImportOption(int option) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_importOptionKey, option);
  }

  /// Lädt die gespeicherte Import-Option
  /// Standardwert ist 0 (Standardkategorie verwenden)
  static Future<int> getImportOption() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_importOptionKey) ?? 0;
  }

  /// Zeigt einen einheitlichen Dialog für Import-Optionen an
  /// Wird sowohl von HomePage als auch von SettingsPage verwendet
  static void showImportOptionsDialog(BuildContext context,
      {VoidCallback? onOptionSelected}) {
    debugPrint(
        "📂 ImportSettingsService: showImportOptionsDialog aufgerufen, Callback vorhanden: ${onOptionSelected != null}");
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    // Dialog-Inhalt erstellen, der für beide Plattformen passt
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlatformAdaptiveListTile(
          title: localizations.howToHandleCategories,
          titleStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        // Bestehende Kategorien verwenden
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS ? CupertinoIcons.tag : Icons.category_outlined,
            color: logoColor,
          ),
          title: localizations.useGoogleCalendarCategories,
          subtitle: localizations.searchForMatchingCategories,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () async {
            Navigator.pop(context);
            // Option 2 = Kalendernamen als Kategorien verwenden
            await ImportSettingsService.saveImportOption(2);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.importOptionSaved)),
              );
              debugPrint(
                  "🛠️ Import-Option gespeichert: 2 (Kategorien von Google Kalender übernehmen)");

              // Callback aufrufen, wenn vorhanden
              if (onOptionSelected != null) {
                debugPrint(
                    "📲 ImportSettingsService: onOptionSelected Callback wird aufgerufen");
                onOptionSelected();
              } else {
                debugPrint(
                    "⚠️ ImportSettingsService: Kein onOptionSelected Callback vorhanden");
              }
            }
          },
        ),

        // Neue Kategorien erstellen
        PlatformAdaptiveListTile(
          leading: Icon(
            Platform.isIOS
                ? CupertinoIcons.add_circled
                : Icons.add_circle_outline,
            color: logoColor,
          ),
          title: localizations.useDefaultCategory,
          subtitle: localizations.importedAppointmentsToDefaultCategory,
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
          onTap: () async {
            Navigator.pop(context);
            // Option 0 = Standardkategorie verwenden
            await ImportSettingsService.saveImportOption(0);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(localizations.importOptionSaved)),
              );
              debugPrint(
                  "🛠️ Import-Option gespeichert: 0 (Standardkategorie verwenden)");

              // Callback aufrufen, wenn vorhanden
              if (onOptionSelected != null) {
                debugPrint(
                    "📲 ImportSettingsService: onOptionSelected Callback wird aufgerufen");
                onOptionSelected();
              } else {
                debugPrint(
                    "⚠️ ImportSettingsService: Kein onOptionSelected Callback vorhanden");
              }
            }
          },
        ),
      ],
    );

    // Dialog-Aktionen erstellen
    final actions = [
      PlatformAdaptiveDialog.adaptiveDialogAction(
        context: context,
        text: localizations.cancel,
        onPressed: () => Navigator.pop(context),
        color: logoColor,
      ),
    ];

    // Plattformspezifischen Dialog anzeigen
    PlatformAdaptiveDialog.showAdaptiveDialog(
      context: context,
      title: localizations.importOptions,
      content: content,
      actions: actions,
    );
  }
}
