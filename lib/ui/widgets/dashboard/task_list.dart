import 'package:flutter/material.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/models/dashboard_task.dart';
import 'package:muslim_calendar/ui/widgets/dashboard/task_item.dart';
import 'package:provider/provider.dart';

class TaskList extends StatelessWidget {
  final List<DashboardTask> tasks;
  final bool isLoading;
  final int? hoveredTaskId;
  final Function(int) onHoverEnter;
  final Function(int) onHoverExit;
  final Function(int) onTaskTap;

  const TaskList({
    Key? key,
    required this.tasks,
    required this.isLoading,
    this.hoveredTaskId,
    required this.onHoverEnter,
    required this.onHoverExit,
    required this.onTaskTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final Color mainColor = Theme.of(context).colorScheme.primary;

    // Header für die Aufgabenliste
    final header = Row(
      children: [
        Icon(Icons.task_alt, color: mainColor),
        const SizedBox(width: 8),
        Text(
          loc.upcomingTasksLabel,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (tasks.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 16),
          Center(
            child: Text(
              loc.noAppointmentsToday,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 8),
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
