import 'package:flutter/material.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/models/dashboard_task.dart';

class TaskItem extends StatelessWidget {
  final DashboardTask task;
  final int? hoveredTaskId;
  final Function(int) onHoverEnter;
  final Function(int) onHoverExit;
  final Function(int) onTaskTap;

  const TaskItem({
    Key? key,
    required this.task,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (task.isPrayerSlot) {
      return PrayerSlotItem(task: task);
    } else if (task.isAllDay) {
      return AllDayTaskItem(
        task: task,
        hoveredTaskId: hoveredTaskId,
        onHoverEnter: onHoverEnter,
        onHoverExit: onHoverExit,
        onTaskTap: onTaskTap,
      );
    } else {
      return RegularTaskItem(
        task: task,
        hoveredTaskId: hoveredTaskId,
        onHoverEnter: onHoverEnter,
        onHoverExit: onHoverExit,
        onTaskTap: onTaskTap,
      );
    }
  }
}

class RegularTaskItem extends StatelessWidget {
  final DashboardTask task;
  final int? hoveredTaskId;
  final Function(int) onHoverEnter;
  final Function(int) onHoverExit;
  final Function(int) onTaskTap;

  const RegularTaskItem({
    Key? key,
    required this.task,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = task.color;
    final textColor = _getContrastingTextColor(backgroundColor);
    final startStr = task.formattedStartTime;
    final endStr = task.formattedEndTime;

    return MouseRegion(
      onEnter: (_) => onHoverEnter(task.appointmentId ?? 0),
      onExit: (_) => onHoverExit(task.appointmentId ?? 0),
      child: InkWell(
        splashColor: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            task.appointmentId != null ? onTaskTap(task.appointmentId!) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: hoveredTaskId == task.appointmentId
                ? [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDuration(task.durationInMinutes),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startStr - $endStr',
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        color: textColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AllDayTaskItem extends StatelessWidget {
  final DashboardTask task;
  final int? hoveredTaskId;
  final Function(int) onHoverEnter;
  final Function(int) onHoverExit;
  final Function(int) onTaskTap;

  const AllDayTaskItem({
    Key? key,
    required this.task,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = task.color;
    final textColor = _getContrastingTextColor(backgroundColor);
    final loc = Provider.of<AppLocalizations>(context);

    return MouseRegion(
      onEnter: (_) => onHoverEnter(task.appointmentId ?? 0),
      onExit: (_) => onHoverExit(task.appointmentId ?? 0),
      child: InkWell(
        splashColor: backgroundColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            task.appointmentId != null ? onTaskTap(task.appointmentId!) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: hoveredTaskId == task.appointmentId
                ? [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_month,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${task.title} (${loc.allDay})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrayerSlotItem extends StatelessWidget {
  final DashboardTask task;

  const PrayerSlotItem({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeStr = task.formattedStartTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade400,
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Hilfsfunktionen
Color _getContrastingTextColor(Color background) {
  final brightness = ThemeData.estimateBrightnessForColor(background);
  return brightness == Brightness.dark ? Colors.white : Colors.black;
}

String _formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}h';
}
