import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine Helferklasse für plattformspezifische Theme-Anpassungen
class PlatformAdaptiveTheme {
  static const Color seedColor = Color(0xFF468178);

  // Plattformspezifische Abstände
  static double get defaultSpacing => Platform.isIOS ? 12.0 : 8.0;

  // Plattformspezifische Abrundungen
  static double get borderRadius => Platform.isIOS ? 16.0 : 8.0;

  // Plattformspezifische Schriftarten
  static String get fontFamily => Platform.isIOS ? '.SF Pro Text' : 'Roboto';

  /// Erstellt ein Light Theme mit plattformspezifischen Anpassungen
  static ThemeData getLightTheme(BuildContext context) {
    final bool isIOS = Platform.isIOS;

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isIOS ? CupertinoColors.systemBackground : Colors.white,
        foregroundColor: isIOS ? CupertinoColors.label : Colors.black87,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: isIOS ? CupertinoColors.label : Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: isIOS ? 17 : 20,
        ),
        iconTheme: IconThemeData(
          color: isIOS ? CupertinoColors.activeBlue : Colors.black87,
        ),
      ),
      scaffoldBackgroundColor:
          isIOS ? CupertinoColors.systemBackground : Colors.white,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
        filled: true,
        fillColor: isIOS
            ? CupertinoColors.systemGrey6.resolveFrom(context)
            : const Color.fromARGB(255, 245, 245, 245),
        contentPadding: EdgeInsets.symmetric(
          horizontal: defaultSpacing * 1.5,
          vertical: defaultSpacing,
        ),
      ),
      cardTheme: CardTheme(
        elevation: isIOS ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: isIOS
              ? BorderSide(
                  color: CupertinoColors.systemGrey5.resolveFrom(context),
                  width: 0.5)
              : BorderSide.none,
        ),
        color: isIOS ? CupertinoColors.systemBackground : Colors.white,
        margin: EdgeInsets.all(defaultSpacing),
      ),
      dialogTheme: DialogTheme(
        elevation: isIOS ? 0 : 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 1.5),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor;
          }
          return isIOS ? CupertinoColors.white : Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor.withOpacity(0.5);
          }
          return isIOS
              ? CupertinoColors.systemGrey5.resolveFrom(context)
              : Colors.grey.withOpacity(0.3);
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.selected)) {
            return seedColor;
          }
          return isIOS ? CupertinoColors.systemGrey4 : Colors.grey;
        }),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? 4 : 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: seedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isIOS
                  ? borderRadius * 3
                  : borderRadius, // iOS verwendet rundere Buttons
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: defaultSpacing * 3,
            vertical: defaultSpacing * 1.5,
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: seedColor,
          side: BorderSide(color: seedColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              isIOS ? borderRadius * 3 : borderRadius,
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: defaultSpacing * 3,
            vertical: defaultSpacing * 1.25,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? borderRadius * 2 : 16),
        ),
        elevation: isIOS ? 1 : 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor:
            isIOS ? CupertinoColors.systemBackground : Colors.white,
        indicatorColor: seedColor.withOpacity(isIOS ? 0.05 : 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        elevation: 0,
        height: isIOS ? 64 : 80,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : isIOS
                    ? CupertinoColors.systemGrey.resolveFrom(context)
                    : Colors.black54,
            size: isIOS ? 22 : 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : isIOS
                    ? CupertinoColors.systemGrey.resolveFrom(context)
                    : Colors.black54,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w500
                : FontWeight.normal,
            fontSize: isIOS ? 11 : 12,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isIOS ? CupertinoColors.systemBackground : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isIOS ? 20 : 16),
          ),
        ),
        elevation: isIOS ? 0 : 8,
      ),
      dividerTheme: DividerThemeData(
        thickness: isIOS ? 0.5 : 1.0,
        space: isIOS ? 0.5 : 1.0,
        color: isIOS
            ? CupertinoColors.systemGrey5.resolveFrom(context)
            : Colors.grey.withOpacity(0.2),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: defaultSpacing * 1.5,
            vertical: defaultSpacing,
          ),
        ),
      ),
    );
  }

  /// Erstellt ein Dark Theme mit plattformspezifischen Anpassungen
  static ThemeData getDarkTheme(BuildContext context) {
    final bool isIOS = Platform.isIOS;

    return ThemeData.dark().copyWith(
      useMaterial3: true,
      textTheme: TextTheme(
        bodyMedium: TextStyle(fontFamily: fontFamily),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor:
            isIOS ? CupertinoColors.systemBackground.darkColor : Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: isIOS ? 17 : 20,
        ),
      ),
      scaffoldBackgroundColor:
          isIOS ? CupertinoColors.systemBackground.darkColor : Colors.black,
      cardTheme: CardTheme(
        elevation: isIOS ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: isIOS
              ? BorderSide(
                  color: CupertinoColors.systemGrey5.darkColor, width: 0.5)
              : BorderSide.none,
        ),
        color: isIOS ? CupertinoColors.systemGrey6.darkColor : Colors.grey[900],
        margin: EdgeInsets.all(defaultSpacing),
      ),
      dialogTheme: DialogTheme(
        elevation: isIOS ? 0 : 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius * 1.5),
        ),
        backgroundColor: isIOS
            ? CupertinoColors.systemBackground.darkColor
            : Colors.grey[900],
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isIOS
            ? CupertinoColors.systemBackground.darkColor
            : Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(isIOS ? 20 : 16),
          ),
        ),
        elevation: isIOS ? 0 : 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        ),
        filled: true,
        fillColor:
            isIOS ? CupertinoColors.systemGrey6.darkColor : Colors.grey[800],
        contentPadding: EdgeInsets.symmetric(
          horizontal: defaultSpacing * 1.5,
          vertical: defaultSpacing,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isIOS ? borderRadius * 2 : 16),
        ),
        elevation: isIOS ? 1 : 4,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isIOS
            ? CupertinoColors.systemBackground.darkColor
            : Colors.grey[900],
        indicatorColor: seedColor.withOpacity(0.2),
        elevation: 0,
        height: isIOS ? 64 : 80,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.white70,
            size: isIOS ? 22 : 24,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? seedColor
                : Colors.white70,
            fontWeight: FontWeight.w500,
            fontSize: isIOS ? 11 : 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: seedColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: defaultSpacing * 1.5,
            vertical: defaultSpacing,
          ),
        ),
      ),
    );
  }
}
