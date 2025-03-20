import 'package:flutter/material.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
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

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.red.shade400, size: 28),
            const SizedBox(height: 8),
            Text(
              loc.networkError,
              style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              loc.weatherFetchError,
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
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
            Icon(Icons.wb_sunny_outlined, color: accentTextColor),
            const SizedBox(width: 8),
            Text(
              loc.weather,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentTextColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          temperature ?? '--',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: accentTextColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          symbol ?? '',
          style: TextStyle(
            fontSize: 28,
            color: accentTextColor,
          ),
        ),
        const Spacer(),
        Text(
          location ?? '--',
          style: theme.textTheme.bodySmall?.copyWith(
            color: accentTextColor,
          ),
        ),
      ],
    );
  }
}
