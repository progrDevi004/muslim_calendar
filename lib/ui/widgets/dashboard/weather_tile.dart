import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:provider/provider.dart';

class WeatherTile extends StatelessWidget {
  final String? temperature;
  final String? location;
  final String? symbol;
  final String? errorMessage;
  final bool isLoading;
  final Color accentTextColor;

  const WeatherTile({
    super.key,
    this.temperature,
    this.location,
    this.symbol,
    this.errorMessage,
    required this.isLoading,
    required this.accentTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = Provider.of<AppLocalizations>(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Plattformspezifische Stile und Werte
    final IconData weatherIcon =
        Platform.isIOS ? CupertinoIcons.sun_max : Icons.wb_sunny_outlined;

    final IconData errorIcon =
        Platform.isIOS ? CupertinoIcons.wifi_slash : Icons.wifi_off;

    final TextStyle titleStyle = Platform.isIOS
        ? TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: accentTextColor,
            inherit: true,
          )
        : theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentTextColor,
              inherit: true,
            ) ??
            TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: accentTextColor,
              inherit: true,
            );

    final TextStyle temperatureStyle = Platform.isIOS
        ? TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 28,
            color: accentTextColor,
            inherit: true,
          )
        : theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: accentTextColor,
              inherit: true,
            ) ??
            TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: accentTextColor,
              inherit: true,
            );

    final TextStyle locationStyle = Platform.isIOS
        ? TextStyle(
            fontSize: 12,
            color: accentTextColor.withOpacity(0.8),
            inherit: true,
          )
        : theme.textTheme.bodySmall?.copyWith(
              color: accentTextColor,
              inherit: true,
            ) ??
            TextStyle(
              fontSize: 12,
              color: accentTextColor,
              inherit: true,
            );

    if (isLoading) {
      return Center(
        child: Platform.isIOS
            ? const CupertinoActivityIndicator()
            : const CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      final Color errorColor = Colors.red.shade400;

      return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(errorIcon, color: errorColor, size: 28),
            const SizedBox(height: 8),
            Text(
              loc.networkError,
              style: TextStyle(
                  color: errorColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  inherit: true),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              loc.weatherFetchError,
              style: TextStyle(
                  color: Colors.red.shade300, fontSize: 12, inherit: true),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(weatherIcon, color: accentTextColor),
            const SizedBox(width: 8),
            Text(
              loc.weather,
              style: titleStyle,
            ),
          ],
        ),
        SizedBox(height: Platform.isIOS ? 8 : 6),
        Text(
          temperature ?? '--',
          style: temperatureStyle,
        ),
        const SizedBox(height: 4),
        Text(
          symbol ?? '',
          style: TextStyle(
            fontSize: Platform.isIOS ? 30 : 28,
            color: accentTextColor,
            inherit: true,
          ),
        ),
        const Spacer(),
        Text(
          location ?? '--',
          style: locationStyle,
        ),
      ],
    );
  }
}
