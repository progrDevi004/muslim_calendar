import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:muslim_calendar/ui/components/platform_adaptive_card.dart';

class DashboardHeader extends StatelessWidget {
  final String dateString;
  final String weekdayString;

  const DashboardHeader({
    super.key,
    required this.dateString,
    required this.weekdayString,
  });

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Theme.of(context).colorScheme.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Plattformspezifische Icons
    final IconData calendarIcon = Platform.isIOS
        ? CupertinoIcons.calendar
        : Icons.calendar_today_outlined;

    // Plattformspezifische Textgrößen und Stile
    final TextStyle dateStyle = Platform.isIOS
        ? TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
            inherit: true,
          )
        : Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  inherit: true,
                ) ??
            const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 20, inherit: true);

    // Plattformspezifisches Padding
    final EdgeInsets padding = Platform.isIOS
        ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0)
        : const EdgeInsets.all(8.0);

    return PlatformAdaptiveCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding,
      elevation: Platform.isIOS ? 0.5 : 1.0,
      borderRadius: Platform.isIOS
          ? BorderRadius.circular(10.0)
          : BorderRadius.circular(8.0),
      child: Row(
        children: [
          Icon(
            calendarIcon,
            size: Platform.isIOS ? 22 : 24,
            color: mainColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$dateString, $weekdayString',
              style: dateStyle,
            ),
          ),
        ],
      ),
    );
  }
}
