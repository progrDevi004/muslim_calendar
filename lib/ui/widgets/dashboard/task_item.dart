import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:Taqvimi/models/dashboard_task.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_card.dart';

class TaskItem extends StatelessWidget {
  final DashboardTask task;
  final int? hoveredTaskId;
  final Function(int) onHoverEnter;
  final Function(int) onHoverExit;
  final Function(int) onTaskTap;

  const TaskItem({
    super.key,
    required this.task,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  });

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
    super.key,
    required this.task,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = task.color;
    final textColor = _getContrastingTextColor(backgroundColor);
    final startStr = task.formattedStartTime;
    final endStr = task.formattedEndTime;

    // Plattformspezifische Anpassungen
    final double verticalMargin = Platform.isIOS ? 7 : 6;
    final double horizontalPadding = Platform.isIOS ? 14 : 16;
    final double verticalPadding = Platform.isIOS ? 14 : 16;
    final BorderRadius borderRadius =
        Platform.isIOS ? BorderRadius.circular(12) : BorderRadius.circular(16);

    final TextStyle titleStyle = Platform.isIOS
        ? TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
            inherit: true,
          )
        : TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
            inherit: true,
          );

    final TextStyle durationStyle = Platform.isIOS
        ? TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: textColor,
            inherit: true,
          )
        : TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
            inherit: true,
          );

    final TextStyle timeStyle = TextStyle(
      color: textColor.withOpacity(0.9),
      fontSize: Platform.isIOS ? 9 : 10,
      inherit: true,
    );

    final TextStyle descriptionStyle = TextStyle(
      color: textColor.withOpacity(0.9),
      fontSize: Platform.isIOS ? 13 : 14,
      inherit: true,
    );

    return MouseRegion(
      onEnter: (_) => onHoverEnter(task.appointmentId ?? 0),
      onExit: (_) => onHoverExit(task.appointmentId ?? 0),
      child: GestureDetector(
        onTap: () =>
            task.appointmentId != null ? onTaskTap(task.appointmentId!) : null,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: verticalMargin),
          padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding, vertical: verticalPadding),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
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
                      style: durationStyle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$startStr - $endStr',
                      style: timeStyle,
                    ),
                  ],
                ),
              ),
              SizedBox(width: Platform.isIOS ? 14 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: titleStyle,
                    ),
                    SizedBox(height: Platform.isIOS ? 3 : 4),
                    Text(
                      task.description,
                      style: descriptionStyle,
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
    super.key,
    required this.task,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = task.color;
    final textColor = _getContrastingTextColor(backgroundColor);
    final loc = Provider.of<AppLocalizations>(context);

    // Plattformspezifische Anpassungen
    final double verticalMargin = Platform.isIOS ? 7 : 6;
    final double padding = Platform.isIOS ? 14 : 16;
    final BorderRadius borderRadius =
        Platform.isIOS ? BorderRadius.circular(12) : BorderRadius.circular(16);

    final IconData calendarIcon =
        Platform.isIOS ? CupertinoIcons.calendar : Icons.calendar_month;

    final TextStyle titleStyle = Platform.isIOS
        ? TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: textColor,
            inherit: true,
          )
        : TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textColor,
            inherit: true,
          );

    return MouseRegion(
      onEnter: (_) => onHoverEnter(task.appointmentId ?? 0),
      onExit: (_) => onHoverExit(task.appointmentId ?? 0),
      child: GestureDetector(
        onTap: () =>
            task.appointmentId != null ? onTaskTap(task.appointmentId!) : null,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: verticalMargin),
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.9),
            borderRadius: borderRadius,
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
              Icon(
                calendarIcon,
                color: Colors.white,
                size: Platform.isIOS ? 22 : 24,
              ),
              SizedBox(width: Platform.isIOS ? 10 : 12),
              Expanded(
                child: Text(
                  '${task.title} (${loc.allDay})',
                  style: titleStyle,
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
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = task.formattedStartTime;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Plattformspezifische Anpassungen
    final double verticalMargin = Platform.isIOS ? 7 : 6;
    final EdgeInsets padding = Platform.isIOS
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
        : const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8);

    final BorderRadius borderRadius =
        Platform.isIOS ? BorderRadius.circular(12) : BorderRadius.circular(16);

    final IconData starIcon =
        Platform.isIOS ? CupertinoIcons.star_fill : Icons.star;

    final TextStyle timeStyle = TextStyle(
      fontWeight: Platform.isIOS ? FontWeight.w600 : FontWeight.bold,
      fontSize: Platform.isIOS ? 13 : 14,
      color: Colors.teal.shade700,
      inherit: true,
    );

    final TextStyle titleStyle = TextStyle(
      fontWeight: Platform.isIOS ? FontWeight.w600 : FontWeight.bold,
      fontSize: Platform.isIOS ? 15 : 16,
      color: isDark ? Colors.white : Colors.black87,
      inherit: true,
    );

    return Container(
      margin: EdgeInsets.symmetric(vertical: verticalMargin),
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.grey.shade200.withOpacity(0.2),
        borderRadius: borderRadius,
        border: Border.all(
          color: Colors.grey.shade400,
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(starIcon, color: Colors.teal),
          SizedBox(width: Platform.isIOS ? 10 : 12),
          Text(
            task.title,
            style: titleStyle,
          ),
          const Spacer(),
          Text(
            timeStr,
            style: timeStyle,
          ),
        ],
      ),
    );
  }
}

Color _getContrastingTextColor(Color bgColor) {
  return ThemeData.estimateBrightnessForColor(bgColor) == Brightness.light
      ? Colors.black
      : Colors.white;
}

String _formatDuration(int minutes) {
  if (minutes < 60) {
    return '$minutes ${minutes == 1 ? 'min' : 'mins'}';
  } else {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      return '$hours:${mins.toString().padLeft(2, '0')}h';
    }
  }
}
