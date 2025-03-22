import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:provider/provider.dart';

class PrayerTimeTile extends StatelessWidget {
  final Map<String, String> prayerTimesDisplay;
  final String? errorMessage;
  final bool isLoading;
  final Color accentTextColor;

  const PrayerTimeTile({
    super.key,
    required this.prayerTimesDisplay,
    this.errorMessage,
    required this.isLoading,
    required this.accentTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = Provider.of<AppLocalizations>(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // Plattformspezifische Icons und Stile
    final IconData clockIcon =
        Platform.isIOS ? CupertinoIcons.clock : Icons.access_alarm_outlined;

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

    final TextStyle timeTextStyle = Platform.isIOS
        ? TextStyle(
            fontSize: 12,
            color: accentTextColor,
            fontWeight: FontWeight.w500,
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
              loc.prayerTimesFetchError,
              style: TextStyle(
                  color: Colors.red.shade300, fontSize: 12, inherit: true),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (prayerTimesDisplay.isEmpty) {
      return Text('${loc.prayerTimeDashboard}\n--');
    }

    // Plattformspezifisches Spacing zwischen den Gebetszeiten
    final double verticalSpacing = Platform.isIOS ? 3.0 : 2.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(clockIcon, color: accentTextColor),
            const SizedBox(width: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                loc.prayerTimeDashboard,
                style: titleStyle,
              ),
            ),
          ],
        ),
        SizedBox(height: Platform.isIOS ? 10 : 8),
        ...prayerTimesDisplay.entries.map(
          (e) => Padding(
            padding: EdgeInsets.symmetric(vertical: verticalSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    e.key,
                    style: timeTextStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  e.value,
                  style: timeTextStyle.copyWith(
                    fontWeight:
                        Platform.isIOS ? FontWeight.w600 : FontWeight.w500,
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
