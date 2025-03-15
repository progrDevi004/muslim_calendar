import 'package:flutter/material.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:provider/provider.dart';

class PrayerTimeTile extends StatelessWidget {
  final Map<String, String> prayerTimesDisplay;
  final String? errorMessage;
  final bool isLoading;
  final Color accentTextColor;

  const PrayerTimeTile({
    Key? key,
    required this.prayerTimesDisplay,
    this.errorMessage,
    required this.isLoading,
    required this.accentTextColor,
  }) : super(key: key);

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
              "Netzwerkfehler",
              style: TextStyle(
                  color: Colors.red.shade400,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Gebetszeiten konnten nicht abgerufen werden",
              style: TextStyle(color: Colors.red.shade300, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (prayerTimesDisplay.isEmpty) {
      return Text('${loc.prayerTimeDashboard}\n--');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.access_alarm_outlined, color: accentTextColor),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                loc.prayerTimeDashboard,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentTextColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...prayerTimesDisplay.entries.map(
          (e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  e.key,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accentTextColor,
                  ),
                ),
                Text(
                  e.value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accentTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
