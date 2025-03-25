import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:Taqvimi/models/project_model.dart';
import 'package:Taqvimi/providers/project_provider.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_app_bar.dart';
import 'package:Taqvimi/ui/dialogs/project_dialog.dart';
import 'package:Taqvimi/ui/components/app_drawer.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';
import 'package:Taqvimi/models/category_model.dart';

// Eigene Enum für Ansichtstypen
enum ProjectViewType { dashboard, day, week, month, year }

class ProjectManagementPage extends StatefulWidget {
  static const String routeName = '/project-management';

  const ProjectManagementPage({Key? key}) : super(key: key);

  @override
  _ProjectManagementPageState createState() => _ProjectManagementPageState();
}

class _ProjectManagementPageState extends State<ProjectManagementPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CategoryRepository _categoryRepository = CategoryRepository();

  ProjectViewType _viewType = ProjectViewType.month;
  List<CategoryModel> _categories = [];
  Set<int> _selectedCategoryIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    // Stellen Sie sicher, dass der Provider Daten geladen hat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectProvider>(context, listen: false).loadProjects();
    });
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _categories = await _categoryRepository.getAllCategories();
      // Standardmäßig alle Kategorien auswählen
      _selectedCategoryIds = _categories.map((c) => c.id!).toSet();
    } catch (e) {
      debugPrint('Fehler beim Laden der Kategorien: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helfer-Methode zum Öffnen/Schließen des Drawers
  void _toggleDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.of(context).pop();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context);
    final isIOS = Platform.isIOS;
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      appBar: PlatformAdaptiveAppBar(
        title: localizations.projectManagement ?? 'Projektmanagement',
        leading: isIOS ? null : const Icon(Icons.menu),
        onLeadingPressed: isIOS ? null : _toggleDrawer,
        centerTitle: isIOS, // Auf iOS zentrieren, auf Android links
      ),
      drawer: AppDrawer(
        onSettingsOpen: () => setState(() {}),
        onCategoriesSelected: (selectedIds) {
          setState(() {
            _selectedCategoryIds = selectedIds;
          });
        },
        onReloadAppointments: () {},
        categories: _categories,
        selectedCategoryIds: _selectedCategoryIds,
        onCloseDrawer: () => Navigator.pop(context),
        currentPage: CurrentPage.projectManagement,
      ),
      body: Consumer<ProjectProvider>(
        builder: (context, projectProvider, child) {
          if (projectProvider.isLoading || _isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (projectProvider.error != null) {
            return Center(
              child: Text(
                'Fehler: ${projectProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          final projects = projectProvider.projects;

          if (projects.isEmpty) {
            return Center(
              child: Text(
                localizations.noProjects ?? 'Keine Projekte gefunden',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            );
          }

          // Projekte sortieren nach Startdatum
          final sortedProjects = List<ProjectModel>.from(projects)
            ..sort((a, b) => a.startDate.compareTo(b.startDate));

          // Hauptinhalt: Projektliste mit Zeitachse je nach ausgewählter Ansicht
          return _buildProjectListByViewType(sortedProjects);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProjectDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(
          isIOS ? CupertinoIcons.add : Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: isIOS
            ? CupertinoTabBar(
                currentIndex: _viewType.index,
                activeColor: theme.primaryColor,
                onTap: (index) {
                  setState(() {
                    _viewType = ProjectViewType.values[index];
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.graph_square),
                    label: localizations.dashboard ?? 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.calendar_today),
                    label: localizations.dayView ?? 'Tag',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.calendar_badge_plus),
                    label: localizations.weekView ?? 'Woche',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.calendar),
                    label: localizations.monthView ?? 'Monat',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(CupertinoIcons.calendar_circle),
                    label: localizations.yearView ?? 'Jahr',
                  ),
                ],
              )
            : BottomNavigationBar(
                currentIndex: _viewType.index,
                selectedItemColor: theme.primaryColor,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                elevation: 8,
                onTap: (index) {
                  setState(() {
                    _viewType = ProjectViewType.values[index];
                  });
                },
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.dashboard),
                    label: localizations.dashboard ?? 'Dashboard',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.view_day),
                    label: localizations.dayView ?? 'Tag',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.view_week),
                    label: localizations.weekView ?? 'Woche',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_view_month),
                    label: localizations.monthView ?? 'Monat',
                  ),
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.calendar_today),
                    label: localizations.yearView ?? 'Jahr',
                  ),
                ],
              ),
      ),
    );
  }

  // Baut die Projektliste basierend auf dem ausgewählten ViewType
  Widget _buildProjectListByViewType(List<ProjectModel> projects) {
    switch (_viewType) {
      case ProjectViewType.dashboard:
        return _buildDashboard(projects);
      case ProjectViewType.day:
        return _buildDayView(projects);
      case ProjectViewType.week:
        return _buildWeekView(projects);
      case ProjectViewType.month:
        return _buildMonthView(projects);
      case ProjectViewType.year:
        return _buildYearView(projects);
      default:
        return _buildDashboard(projects); // Standardansicht: Dashboard
    }
  }

  // Dashboard mit Projektübersicht
  Widget _buildDashboard(List<ProjectModel> projects) {
    final localizations = Provider.of<AppLocalizations>(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    // Projekte nach Status gruppieren
    final overdueProjekte = projects
        .where((p) => p.endDate.isBefore(now) && p.progress < 100)
        .toList();
    final aktiveProjekte = projects
        .where((p) => !p.endDate.isBefore(now) && p.progress < 100)
        .toList();
    final abgeschlosseneProjekte =
        projects.where((p) => p.progress == 100).toList();

    // Berechne Projekte nach Priorität
    final hohePrioritaet = projects.where((p) => p.priority == 3).length;
    final mittlerePrioritaet = projects.where((p) => p.priority == 2).length;
    final niedriegePrioritaet = projects.where((p) => p.priority == 1).length;

    // Projekte nach Fälligkeit gruppieren
    final heuteFaellig = projects
        .where((p) => isSameDay(p.endDate, now) && p.progress < 100)
        .length;
    final dieseWocheFaellig = projects
        .where((p) =>
            !isSameDay(p.endDate, now) &&
            p.endDate.isAfter(now) &&
            p.endDate.difference(now).inDays <= 7 &&
            p.progress < 100)
        .length;

    // Projekte nach Kategorien gruppieren für den Chart
    final Map<String, int> projektNachKategorie = {};
    for (var projekt in projects) {
      final kategorieName = projekt.category?.name ?? 'Unbekannt';
      if (projektNachKategorie.containsKey(kategorieName)) {
        projektNachKategorie[kategorieName] =
            projektNachKategorie[kategorieName]! + 1;
      } else {
        projektNachKategorie[kategorieName] = 1;
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Projektstatus-Karten
          Row(
            children: [
              _buildStatusCard(
                title: localizations.activeProjects,
                count: aktiveProjekte.length,
                icon: Icons.play_circle_outline,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatusCard(
                title: localizations.completedProjects,
                count: abgeschlosseneProjekte.length,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildStatusCard(
                title: localizations.overdueProjects,
                count: overdueProjekte.length,
                icon: Icons.warning_amber_outlined,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              _buildStatusCard(
                title: localizations.upcomingDeadlines,
                count: heuteFaellig + dieseWocheFaellig,
                icon: Icons.schedule,
                color: Colors.orange,
              ),
            ],
          ),

          // Fortschrittsanzeige
          const SizedBox(height: 24),
          Text(
            localizations.projectProgress,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildProgressBar(
                    label: localizations.completedProjects,
                    color: Colors.green,
                    value: abgeschlosseneProjekte.length / projects.length,
                    text:
                        '${abgeschlosseneProjekte.length} / ${projects.length}',
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    label: localizations.activeProjects,
                    color: Colors.blue,
                    value: aktiveProjekte.length / projects.length,
                    text: '${aktiveProjekte.length} / ${projects.length}',
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    label: localizations.overdueProjects,
                    color: Colors.red,
                    value: overdueProjekte.length / projects.length,
                    text: '${overdueProjekte.length} / ${projects.length}',
                  ),
                ],
              ),
            ),
          ),

          // Prioritätsverteilung
          const SizedBox(height: 24),
          Text(
            localizations.priorityDistribution,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPriorityIndicator(
                    label: localizations.highPriority,
                    count: hohePrioritaet,
                    color: Colors.red,
                  ),
                  _buildPriorityIndicator(
                    label: localizations.mediumPriority,
                    count: mittlerePrioritaet,
                    color: Colors.orange,
                  ),
                  _buildPriorityIndicator(
                    label: localizations.lowPriority,
                    count: niedriegePrioritaet,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),

          // Listen für überfällige und heutige Projekte
          const SizedBox(height: 24),
          Text(
            localizations.noOverdueProjects,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          overdueProjekte.isEmpty
              ? Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text(
                        localizations.noOverdueProjects,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                )
              : Card(
                  elevation: 2,
                  child: ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount:
                        overdueProjekte.length > 3 ? 3 : overdueProjekte.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final project = overdueProjekte[index];
                      return ListTile(
                        leading: Icon(Icons.warning, color: Colors.red),
                        title: Text(project.name),
                        subtitle: Text(
                            '${_formatDate(project.endDate)} • ${project.progress}%'),
                        trailing: project.priority == 3
                            ? Chip(
                                label: Text(
                                  localizations.highPriority,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                                backgroundColor: Colors.red,
                                padding: EdgeInsets.zero,
                              )
                            : null,
                        onTap: () => _showProjectDetailsDialog(project),
                      );
                    },
                  ),
                ),

          if (overdueProjekte.length > 3) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // Hier könnten wir zu einer gefilterten Ansicht wechseln
                  setState(() {
                    _selectedDate = DateTime.now();
                    _viewType = ProjectViewType.day;
                  });
                },
                child: Text(
                  localizations.showAll,
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),
          Text(
            localizations.upcomingDeadlines,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Kommende Projekte
          Builder(builder: (context) {
            final demnaechstFaelligeProjekte = aktiveProjekte
                .where((p) => p.endDate.difference(now).inDays <= 7)
                .toList()
              ..sort((a, b) => a.endDate.compareTo(b.endDate));

            return demnaechstFaelligeProjekte.isEmpty
                ? Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Text(
                          localizations.noUpcomingDeadlines,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  )
                : Card(
                    elevation: 2,
                    child: ListView.separated(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: demnaechstFaelligeProjekte.length > 3
                          ? 3
                          : demnaechstFaelligeProjekte.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final project = demnaechstFaelligeProjekte[index];
                        final daysLeft = project.endDate.difference(now).inDays;

                        return ListTile(
                          leading: Icon(
                            Icons.event,
                            color: daysLeft == 0
                                ? Colors.red
                                : daysLeft <= 3
                                    ? Colors.orange
                                    : Colors.blue,
                          ),
                          title: Text(project.name),
                          subtitle: Text(
                              '${_formatDate(project.endDate)} • ${project.progress}%'),
                          trailing: Text(
                            daysLeft == 0
                                ? localizations.dueToday
                                : daysLeft == 1
                                    ? localizations.dueTomorrow
                                    : localizations.daysLeft,
                            style: TextStyle(
                              color: daysLeft == 0
                                  ? Colors.red
                                  : daysLeft <= 3
                                      ? Colors.orange
                                      : Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onTap: () => _showProjectDetailsDialog(project),
                        );
                      },
                    ),
                  );
          }),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Status-Karte für Dashboard
  Widget _buildStatusCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                count.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Fortschrittsbalken für Dashboard
  Widget _buildProgressBar({
    required String label,
    required Color color,
    required double value,
    required String text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w500)),
            Text(text, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value.isNaN ? 0 : value,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
          minHeight: 8,
        ),
      ],
    );
  }

  // Prioritäts-Indikator für Dashboard
  Widget _buildPriorityIndicator({
    required String label,
    required int count,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  // Prioritäts-Badge für Projektkarten
  Widget _buildPriorityBadge(int priority) {
    final localizations = Provider.of<AppLocalizations>(context);

    Color color;
    String label;

    switch (priority) {
      case 1:
        color = Colors.green;
        label = localizations.lowPriority;
        break;
      case 3:
        color = Colors.red;
        label = localizations.highPriority;
        break;
      case 2:
      default:
        color = Colors.orange;
        label = localizations.mediumPriority;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Tagesansicht
  Widget _buildDayView(List<ProjectModel> projects) {
    // Standard-Tag ist heute
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final localizations = Provider.of<AppLocalizations>(context);

    // Zustandsvariable für den ausgewählten Tag
    final DateTime selectedDate = _selectedDate ?? today;

    // Filtere Projekte, die am ausgewählten Tag aktiv sind
    final filteredProjects = projects.where((project) {
      return (project.startDate.isBefore(selectedDate) ||
              isSameDay(project.startDate, selectedDate)) &&
          (project.endDate.isAfter(selectedDate) ||
              isSameDay(project.endDate, selectedDate));
    }).toList();

    return Column(
      children: [
        // Navigation für Tagesauswahl
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _selectedDate =
                        selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  _formatDateWithWeekday(selectedDate),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _selectedDate = selectedDate.add(const Duration(days: 1));
                  });
                },
              ),
            ],
          ),
        ),

        // Tages-Timeline
        Expanded(
          child: filteredProjects.isEmpty
              ? Center(
                  child: Text(
                    localizations.noProjectsForThisDay,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = filteredProjects[index];
                    return _buildProjectCard(project);
                  },
                ),
        ),
      ],
    );
  }

  // Wochenansicht
  Widget _buildWeekView(List<ProjectModel> projects) {
    // Standard-Woche ist aktuelle Woche
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Berechne Wochenbeginn (Montag) und Wochenende (Sonntag) der aktuellen Woche
    final DateTime startOfWeek =
        _selectedWeekStart ?? today.subtract(Duration(days: today.weekday - 1));
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    // Filtere Projekte, die in der ausgewählten Woche aktiv sind
    final filteredProjects = projects.where((project) {
      return (project.startDate.isBefore(endOfWeek) ||
              isSameDay(project.startDate, endOfWeek)) &&
          (project.endDate.isAfter(startOfWeek) ||
              isSameDay(project.endDate, startOfWeek));
    }).toList();

    return Column(
      children: [
        // Navigation für Wochenauswahl
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _selectedWeekStart =
                        startOfWeek.subtract(const Duration(days: 7));
                  });
                },
              ),
              TextButton(
                onPressed: () {
                  // Bei Klick auf aktuelle Woche zurücksetzen
                  setState(() {
                    _selectedWeekStart =
                        today.subtract(Duration(days: today.weekday - 1));
                  });
                },
                child: Text(
                  '${_formatDate(startOfWeek)} - ${_formatDate(endOfWeek)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _selectedWeekStart =
                        startOfWeek.add(const Duration(days: 7));
                  });
                },
              ),
            ],
          ),
        ),

        // Wochen-Übersicht
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: List.generate(7, (index) {
              final day = startOfWeek.add(Duration(days: index));
              final isToday = isSameDay(day, today);

              // Zähle Projekte für diesen Tag
              final projectsForDay = projects
                  .where((project) =>
                      (project.startDate.isBefore(day) ||
                          isSameDay(project.startDate, day)) &&
                      (project.endDate.isAfter(day) ||
                          isSameDay(project.endDate, day)))
                  .toList();

              // Gruppiere nach Kategorien für die Farbdarstellung
              final Map<Color, int> projectsByCategory = {};
              for (final project in projectsForDay) {
                final color =
                    project.category?.color ?? Theme.of(context).primaryColor;
                if (projectsByCategory.containsKey(color)) {
                  projectsByCategory[color] = projectsByCategory[color]! + 1;
                } else {
                  projectsByCategory[color] = 1;
                }
              }

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = day;
                      _viewType =
                          ProjectViewType.day; // Wechsel zur Tagesansicht
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.0),
                    decoration: BoxDecoration(
                      color: isToday
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getDayOfWeekShort(day),
                          style: TextStyle(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                          ),
                        ),
                        Text(
                          day.day.toString(),
                          style: TextStyle(
                            fontWeight:
                                isToday ? FontWeight.bold : FontWeight.normal,
                            fontSize: 16,
                            color:
                                isToday ? Theme.of(context).primaryColor : null,
                          ),
                        ),
                        // Projekt-Indikatoren (farbige Punkte nach Kategorie)
                        if (projectsByCategory.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            height: 8,
                            child: projectsByCategory.length <= 3
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children:
                                        projectsByCategory.entries.map((entry) {
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 1),
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: entry.key,
                                          shape: BoxShape.circle,
                                        ),
                                      );
                                    }).toList(),
                                  )
                                : Container(
                                    width: 30,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${projectsForDay.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 8.0),

        // Wochenliste der Projekte
        Expanded(
          child: filteredProjects.isEmpty
              ? Center(
                  child: Text(
                    'Keine Projekte für diese Woche',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = filteredProjects[index];
                    return _buildProjectCard(project);
                  },
                ),
        ),
      ],
    );
  }

  // Monatsansicht
  Widget _buildMonthView(List<ProjectModel> projects) {
    // Standard-Monat ist aktueller Monat
    final DateTime now = DateTime.now();
    final localizations = Provider.of<AppLocalizations>(context);
    final DateTime today = DateTime(now.year, now.month, now.day);

    // Wähle den ersten Tag des ausgewählten Monats
    final DateTime firstDayOfMonth =
        _selectedMonth ?? DateTime(now.year, now.month, 1);
    final int daysInMonth =
        DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0).day;

    // Filtere Projekte, die im ausgewählten Monat aktiv sind
    final DateTime lastDayOfMonth =
        DateTime(firstDayOfMonth.year, firstDayOfMonth.month, daysInMonth);
    final filteredProjects = projects.where((project) {
      return (project.startDate.isBefore(lastDayOfMonth) ||
              isSameDay(project.startDate, lastDayOfMonth)) &&
          (project.endDate.isAfter(firstDayOfMonth) ||
              isSameDay(project.endDate, firstDayOfMonth));
    }).toList();

    return Column(
      children: [
        // Navigation für Monatsauswahl
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                        firstDayOfMonth.year, firstDayOfMonth.month - 1, 1);
                  });
                },
              ),
              TextButton(
                onPressed: () => _selectMonth(context),
                child: Text(
                  _getMonthYearString(firstDayOfMonth),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _selectedMonth = DateTime(
                        firstDayOfMonth.year, firstDayOfMonth.month + 1, 1);
                  });
                },
              ),
            ],
          ),
        ),

        // Monatsübersicht
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              // Wochentags-Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So']
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 8.0),

              // Kalendertage
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: _getMonthViewItemCount(firstDayOfMonth),
                itemBuilder: (context, index) {
                  // Berechne den ersten anzuzeigenden Tag (erster Wochentag des Monats)
                  final firstDayWeekday =
                      DateTime(firstDayOfMonth.year, firstDayOfMonth.month, 1)
                          .weekday;
                  final dayOffset = firstDayWeekday - 1; // -1 weil Montag = 1

                  final displayedDay = index - dayOffset + 1;

                  if (displayedDay < 1 || displayedDay > daysInMonth) {
                    // Leere Zelle für Tage außerhalb des Monats
                    return Container();
                  }

                  final date = DateTime(firstDayOfMonth.year,
                      firstDayOfMonth.month, displayedDay);
                  final isToday = isSameDay(date, today);

                  // Prüfe, ob an diesem Tag Projekte aktiv sind
                  final projectsForDate = projects.where((project) =>
                      (project.startDate.isBefore(date) ||
                          isSameDay(project.startDate, date)) &&
                      (project.endDate.isAfter(date) ||
                          isSameDay(project.endDate, date)));

                  // Gruppiere nach Kategorien für die Farbdarstellung
                  final Map<Color, int> projectsByCategory = {};
                  for (final project in projectsForDate) {
                    final color = project.category?.color ??
                        Theme.of(context).primaryColor;
                    if (projectsByCategory.containsKey(color)) {
                      projectsByCategory[color] =
                          projectsByCategory[color]! + 1;
                    } else {
                      projectsByCategory[color] = 1;
                    }
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDate = date;
                        _viewType =
                            ProjectViewType.day; // Wechsel zur Tagesansicht
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Theme.of(context).primaryColor.withOpacity(0.2)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday
                              ? Theme.of(context).primaryColor
                              : projectsForDate.isNotEmpty
                                  ? Colors.grey[400]!
                                  : Colors.grey[200]!,
                          width: projectsForDate.isNotEmpty ? 1.0 : 0.5,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              displayedDay.toString(),
                              style: TextStyle(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? Theme.of(context).primaryColor
                                    : null,
                              ),
                            ),
                          ),
                          // Projekt-Indikatoren basierend auf der Kategorie
                          if (projectsByCategory.isNotEmpty)
                            Positioned(
                              right: 2,
                              top: 2,
                              child: projectsByCategory.length <= 3
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: projectsByCategory.entries
                                          .map((entry) {
                                        return Container(
                                          margin:
                                              const EdgeInsets.only(left: 1),
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: entry.key,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }).toList(),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${projectsForDate.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 8.0),

        // Monatsliste der Projekte
        Expanded(
          child: filteredProjects.isEmpty
              ? Center(
                  child: Text(
                    localizations.noProjectsForThisMonth,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredProjects.length,
                  itemBuilder: (context, index) {
                    final project = filteredProjects[index];
                    return _buildProjectCard(project);
                  },
                ),
        ),
      ],
    );
  }

  // Jahresansicht
  Widget _buildYearView(List<ProjectModel> projects) {
    // Standard-Jahr ist aktuelles Jahr
    final DateTime now = DateTime.now();
    final int selectedYear = _selectedYear ?? now.year;
    final localizations = Provider.of<AppLocalizations>(context);
    final List<String> months = localizations.months;

    // Filtere Projekte für das ausgewählte Jahr
    final filteredProjects = projects.where((project) {
      return (project.startDate.year == selectedYear ||
              project.endDate.year == selectedYear) ||
          (project.startDate.year < selectedYear &&
              project.endDate.year > selectedYear);
    }).toList();

    return Column(
      children: [
        // Navigation für Jahresauswahl
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {
                  setState(() {
                    _selectedYear = selectedYear - 1;
                  });
                },
              ),
              TextButton(
                onPressed: () => _selectYear(context),
                child: Text(
                  selectedYear.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                onPressed: () {
                  setState(() {
                    _selectedYear = selectedYear + 1;
                  });
                },
              ),
            ],
          ),
        ),

        // Monatsübersicht für das Jahr
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final startOfMonth = DateTime(selectedYear, month, 1);
              final endOfMonth = DateTime(selectedYear, month + 1, 0);

              // Prüfe, ob in diesem Monat Projekte aktiv sind
              final projectsInMonth = projects
                  .where((project) =>
                      (project.startDate.isBefore(endOfMonth) ||
                          isSameDay(project.startDate, endOfMonth)) &&
                      (project.endDate.isAfter(startOfMonth) ||
                          isSameDay(project.endDate, startOfMonth)))
                  .toList();

              final isCurrentMonth =
                  now.year == selectedYear && now.month == month;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedMonth = startOfMonth;
                    _viewType =
                        ProjectViewType.month; // Wechsel zur Monatsansicht
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isCurrentMonth
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentMonth
                          ? Theme.of(context).primaryColor
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        months[index],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCurrentMonth
                              ? Theme.of(context).primaryColor
                              : Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${projectsInMonth.length} ${localizations.projects}',
                        style: TextStyle(
                          fontSize: 12,
                          color: projectsInMonth.isEmpty
                              ? Colors.grey[500]
                              : Colors.grey[700],
                        ),
                      ),
                      if (projectsInMonth.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          height: 6,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Projekte im gesamten Jahr
        Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.projectsForThisYear} $selectedYear',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 160,
                child: filteredProjects.isEmpty
                    ? Center(
                        child: Text(
                          localizations.noProjectsForThisYear,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: filteredProjects.length,
                        itemBuilder: (context, index) {
                          final project = filteredProjects[index];
                          return _buildCompactProjectCard(project);
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Kompakte Projektkarte für die Jahresansicht
  Widget _buildCompactProjectCard(ProjectModel project) {
    final category = project.category;
    final Color projectColor =
        category?.color ?? Theme.of(context).primaryColor;

    return GestureDetector(
      onTap: () => _showProjectDetailsDialog(project),
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 10.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: projectColor.withOpacity(0.5)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: projectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_formatDate(project.startDate)} - ${_formatDate(project.endDate)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: project.progress / 100,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(projectColor),
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 4),
              Text(
                '${project.progress}% ${_getRemainingDaysText(project.endDate)}',
                style: TextStyle(
                  fontSize: 11,
                  color: _getDeadlineColor(project.endDate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hilfsmethoden für die Ansichten
  DateTime? _selectedDate;
  DateTime? _selectedWeekStart;
  DateTime? _selectedMonth;
  int? _selectedYear;

  // Datumauswahl-Dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime initialDate = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Monatsauswahl-Dialog
  Future<void> _selectMonth(BuildContext context) async {
    final DateTime initialDate = _selectedMonth ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month, 1);
      });
    }
  }

  // Jahresauswahl-Dialog
  Future<void> _selectYear(BuildContext context) async {
    final int currentYear = DateTime.now().year;
    final localizations = Provider.of<AppLocalizations>(context);
    final List<int> years =
        List.generate(20, (index) => currentYear - 10 + index);

    // Platform-spezifischer Dialog für Jahresauswahl
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return Container(
            height: 200,
            color: CupertinoColors.systemBackground.resolveFrom(context),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: Text(localizations.cancel),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    CupertinoButton(
                      child: Text(localizations.ok),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: CupertinoPicker(
                    itemExtent: 32,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedYear = years[index];
                      });
                    },
                    children: years
                        .map((year) => Center(child: Text(year.toString())))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(localizations.selectYear),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: years.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(years[index].toString()),
                    onTap: () {
                      setState(() {
                        _selectedYear = years[index];
                      });
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
          );
        },
      );
    }
  }

  // Hilfsmethode für formatiertes Datum mit Wochentag
  String _formatDateWithWeekday(DateTime date) {
    final localizations = Provider.of<AppLocalizations>(context);
    final List<String> weekdays = localizations.weekdays;
    final String weekday =
        weekdays[date.weekday - 1]; // -1 da weekday 1-7 liefert
    return '$weekday, ${date.day}.${date.month}.${date.year}';
  }

  // Hilfsmethode für Monat und Jahr als String
  String _getMonthYearString(DateTime date) {
    final localizations = Provider.of<AppLocalizations>(context);
    final List<String> months = localizations.months;
    return '${months[date.month - 1]} ${date.year}';
  }

  // Kurzform des Wochentags
  String _getDayOfWeekShort(DateTime date) {
    final localizations = Provider.of<AppLocalizations>(context);
    final List<String> weekdays = localizations.weekdays;
    return weekdays[date.weekday - 1]; // -1 da weekday 1-7 liefert
  }

  // Berechnet die Anzahl der Elemente für die Monatsansicht
  int _getMonthViewItemCount(DateTime firstDayOfMonth) {
    // Anzahl der Tage im Monat
    final int daysInMonth =
        DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 0).day;
    // Wochentag des ersten Tags im Monat (1 = Montag, 7 = Sonntag)
    final int firstDayWeekday =
        DateTime(firstDayOfMonth.year, firstDayOfMonth.month, 1).weekday;

    // Berechne die benötigte Anzahl von Zeilen (Wochen)
    final int totalDays = firstDayWeekday - 1 + daysInMonth;
    final int rowsNeeded = (totalDays / 7).ceil();

    // Gesamtzahl der Elemente (7 Tage pro Woche)
    return rowsNeeded * 7;
  }

  // Überprüft, ob zwei Daten den gleichen Tag repräsentieren
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Eine Liste von Projektkarten anzeigen
  Widget _buildProjectList(List<ProjectModel> projects) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final project = projects[index];
        return _buildProjectCard(project);
      },
    );
  }

  // Eine Projektkarte erstellen
  Widget _buildProjectCard(ProjectModel project) {
    final localizations = Provider.of<AppLocalizations>(context);
    final category = project.category;
    final Color projectColor =
        category?.color ?? Theme.of(context).primaryColor;

    // Datumsformatierung
    final startDateStr = _formatDate(project.startDate);
    final endDateStr = _formatDate(project.endDate);

    // Berechnung der Projektdauer (für Fortschrittsbalken)
    final now = DateTime.now();
    final totalDuration = project.endDate.difference(project.startDate).inDays;
    final passedDuration = now.difference(project.startDate).inDays;

    // Zeit-Fortschritt (0.0 bis 1.0)
    double timeProgress = 0.0;
    if (totalDuration > 0) {
      timeProgress = passedDuration / totalDuration;
      timeProgress = timeProgress.clamp(0.0, 1.0); // Begrenzen auf 0-1
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: projectColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showProjectDetailsDialog(project),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Projekttitel und Prioritätsindikator
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: projectColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(project.priority),
                ],
              ),

              // Beschreibung, falls vorhanden
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Zeitraum
              Row(
                children: [
                  Icon(
                    CupertinoIcons.calendar,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$startDateStr - $endDateStr',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Fortschritt
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${localizations.progress}: ${project.progress}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _getRemainingDaysText(project.endDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getDeadlineColor(project.endDate),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: project.progress / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            projectColor,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format date to a readable string
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  // Get text for remaining days until deadline
  String _getRemainingDaysText(DateTime endDate) {
    final now = DateTime.now();
    final localizations = Provider.of<AppLocalizations>(context);
    final difference = endDate.difference(now).inDays;

    if (difference < 0) {
      return '${-difference} ${localizations.daysOverdue}';
    } else if (difference == 0) {
      return localizations.dueToday;
    } else if (difference == 1) {
      return localizations.oneDayLeft;
    } else {
      return '$difference ${localizations.daysLeft}';
    }
  }

  // Get color based on deadline proximity
  Color _getDeadlineColor(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red;
    } else if (difference <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  // Dialog zum Hinzufügen eines neuen Projekts
  Future<void> _showAddProjectDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProjectDialog(
          categories: _categories,
          onSave: (ProjectModel project) async {
            final provider =
                Provider.of<ProjectProvider>(context, listen: false);
            await provider.addProject(project);
          },
        );
      },
    );
  }

  // Dialog zum Anzeigen der Projektdetails
  Future<void> _showProjectDetailsDialog(ProjectModel project) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ProjectDialog(
          project: project,
          categories: _categories,
          onSave: (ProjectModel updatedProject) async {
            final provider =
                Provider.of<ProjectProvider>(context, listen: false);
            await provider.updateProject(updatedProject);
          },
          onDelete: project.id != null
              ? (int id) async {
                  final provider =
                      Provider.of<ProjectProvider>(context, listen: false);
                  await provider.deleteProject(id);
                }
              : null,
        );
      },
    );
  }
}
