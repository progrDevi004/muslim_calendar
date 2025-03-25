import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:Taqvimi/models/project_model.dart';
import 'package:Taqvimi/providers/project_provider.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_app_bar.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_dialog.dart';
import 'package:Taqvimi/ui/dialogs/project_dialog.dart';
import 'package:Taqvimi/ui/components/app_drawer.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';
import 'package:Taqvimi/models/category_model.dart';

// Eigene Enum für Ansichtstypen
enum ProjectViewType { day, week, month, year }

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

    return Scaffold(
      key: _scaffoldKey,
      appBar: PlatformAdaptiveAppBar(
        title: localizations.projectManagement ?? 'Projektmanagement',
        leading: isIOS ? null : const Icon(Icons.menu),
        onLeadingPressed: isIOS ? null : _toggleDrawer,
        centerTitle: isIOS, // Auf iOS zentrieren, auf Android links
        actions: [
          // Ansicht wechseln (Woche, Monat, Jahr)
          IconButton(
            icon: Icon(
              isIOS ? CupertinoIcons.calendar : Icons.calendar_view_month,
            ),
            onPressed: _showViewTypeSelectionDialog,
          ),
        ],
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

          // Hauptinhalt: Projektliste mit Zeitachse
          return _buildProjectList(sortedProjects);
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
    );
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
                  _buildPriorityIndicator(project.priority),
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
                              '${localizations.progress ?? 'Fortschritt'}: ${project.progress}%',
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

  // Prioritätsindikator erstellen
  Widget _buildPriorityIndicator(int priority) {
    final localizations = Provider.of<AppLocalizations>(context);

    Color color;
    String label;

    switch (priority) {
      case 1:
        color = Colors.green;
        label = localizations.lowPriority ?? 'Niedrig';
        break;
      case 3:
        color = Colors.red;
        label = localizations.highPriority ?? 'Hoch';
        break;
      case 2:
      default:
        color = Colors.orange;
        label = localizations.mediumPriority ?? 'Mittel';
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

  // Format date to a readable string
  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  // Get text for remaining days until deadline
  String _getRemainingDaysText(DateTime endDate) {
    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;

    if (difference < 0) {
      return '${-difference} Tage überfällig';
    } else if (difference == 0) {
      return 'Heute fällig';
    } else if (difference == 1) {
      return '1 Tag übrig';
    } else {
      return '$difference Tage übrig';
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

  // Bestimmt die Textfarbe basierend auf der Hintergrundfarbe
  Color _getTextColorBasedOnBackground(Color? backgroundColor) {
    if (backgroundColor == null) return Colors.white;

    // Berechnet die Helligkeit der Farbe
    final double brightness = backgroundColor.computeLuminance();

    // Bei dunklen Farben weißen Text verwenden, bei hellen Farben schwarzen Text
    return brightness > 0.5 ? Colors.black : Colors.white;
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

  // Dialog zum Auswählen der Ansichtsart
  Future<void> _showViewTypeSelectionDialog() async {
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) {
          return CupertinoActionSheet(
            title: Text(localizations.viewType ?? 'Ansichtstyp'),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _viewType = ProjectViewType.day;
                  });
                  Navigator.pop(context);
                },
                child: Text(localizations.dayView ?? 'Tagesansicht'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _viewType = ProjectViewType.week;
                  });
                  Navigator.pop(context);
                },
                child: Text(localizations.weekView ?? 'Wochenansicht'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _viewType = ProjectViewType.month;
                  });
                  Navigator.pop(context);
                },
                child: Text(localizations.monthView ?? 'Monatsansicht'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  setState(() {
                    _viewType = ProjectViewType.year;
                  });
                  Navigator.pop(context);
                },
                child: Text(localizations.yearView ?? 'Jahresansicht'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDestructiveAction: true,
              child: Text(localizations.cancel ?? 'Abbrechen'),
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(localizations.viewType ?? 'Ansichtstyp'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(localizations.dayView ?? 'Tagesansicht'),
                  onTap: () {
                    setState(() {
                      _viewType = ProjectViewType.day;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(localizations.weekView ?? 'Wochenansicht'),
                  onTap: () {
                    setState(() {
                      _viewType = ProjectViewType.week;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(localizations.monthView ?? 'Monatsansicht'),
                  onTap: () {
                    setState(() {
                      _viewType = ProjectViewType.month;
                    });
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: Text(localizations.yearView ?? 'Jahresansicht'),
                  onTap: () {
                    setState(() {
                      _viewType = ProjectViewType.year;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }
}
