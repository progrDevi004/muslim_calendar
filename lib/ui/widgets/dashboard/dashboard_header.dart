import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DashboardHeader extends StatelessWidget {
  final String dateString;
  final String weekdayString;

  const DashboardHeader({
    Key? key,
    required this.dateString,
    required this.weekdayString,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Theme.of(context).colorScheme.primary;

    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 24,
              color: mainColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$dateString, $weekdayString',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
