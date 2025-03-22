import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/models/dashboard_task.dart';
import 'package:Taqvimi/ui/widgets/dashboard/task_item.dart';
import 'package:provider/provider.dart';

class TaskList extends StatelessWidget {
  final List<DashboardTask> tasks;
  final bool isLoading;
  final int? hoveredTaskId;
  final Function(int) onHoverEnter;
  final Function(int) onHoverExit;
  final Function(int) onTaskTap;

  const TaskList({
    super.key,
    required this.tasks,
    required this.isLoading,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final Color mainColor = Theme.of(context).colorScheme.primary;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Plattformspezifische Icons und Stile
    final IconData taskIcon =
        Platform.isIOS ? CupertinoIcons.checkmark_circle : Icons.task_alt;

    final TextStyle headerStyle = Platform.isIOS
        ? TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
            inherit: true,
          )
        : Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  inherit: true,
                ) ??
            const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              inherit: true,
            );

    final TextStyle emptyMessageStyle = Platform.isIOS
        ? TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            fontStyle: FontStyle.italic,
            fontSize: 14,
            inherit: true,
          )
        : TextStyle(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
            inherit: true,
          );

    // Header für die Aufgabenliste
    final header = Row(
      children: [
        Icon(taskIcon, color: mainColor),
        const SizedBox(width: 8),
        Text(
          loc.upcomingTasksLabel,
          style: headerStyle,
        ),
      ],
    );

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: Platform.isIOS ? 20 : 16),
          Center(
            child: Platform.isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (tasks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          SizedBox(height: Platform.isIOS ? 20 : 16),
          Center(
            child: Text(
              loc.noAppointmentsToday,
              style: emptyMessageStyle,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        SizedBox(height: Platform.isIOS ? 10 : 8),
        ...tasks.map((task) => TaskItem(
              task: task,
              hoveredTaskId: hoveredTaskId,
              onHoverEnter: onHoverEnter,
              onHoverExit: onHoverExit,
              onTaskTap: onTaskTap,
            )),
      ],
    );
  }
}
