import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:Taqvimi/models/project_model.dart';
import 'package:Taqvimi/models/category_model.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_form.dart';
import 'package:Taqvimi/ui/components/platform_adaptive_dialog.dart';
import 'package:provider/provider.dart';
import 'package:Taqvimi/localization/app_localizations.dart';

class ProjectDialog extends StatefulWidget {
  final ProjectModel? project;
  final List<CategoryModel> categories;
  final Function(ProjectModel) onSave;
  final Function(int)? onDelete;

  const ProjectDialog({
    Key? key,
    this.project,
    required this.categories,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  @override
  _ProjectDialogState createState() => _ProjectDialogState();
}

class _ProjectDialogState extends State<ProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _description;
  late DateTime _startDate;
  late DateTime _endDate;
  late int _priority;
  late int _progress;
  late int _categoryId;
  final bool _isIOS = Platform.isIOS;

  @override
  void initState() {
    super.initState();

    // Wenn ein Projekt übergeben wurde, Felder initialisieren
    if (widget.project != null) {
      _name = widget.project!.name;
      _description = widget.project!.description;
      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
      _priority = widget.project!.priority;
      _progress = widget.project!.progress;
      _categoryId = widget.project!.categoryId;
    } else {
      // Standardwerte für neue Projekte
      _name = '';
      _description = '';
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(const Duration(days: 7));
      _priority = 2; // Mittlere Priorität
      _progress = 0;
      _categoryId =
          widget.categories.isNotEmpty ? widget.categories.first.id! : 1;
    }
  }

  // Methode zum Speichern des Projekts
  void _saveProject() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Neues Projekt erstellen oder bestehendes aktualisieren
      final project = widget.project == null
          ? ProjectModel.newProject(
              name: _name,
              description: _description,
              startDate: _startDate,
              endDate: _endDate,
              priority: _priority,
              progress: _progress,
              categoryId: _categoryId,
            )
          : widget.project!.copyWith(
              name: _name,
              description: _description,
              startDate: _startDate,
              endDate: _endDate,
              priority: _priority,
              progress: _progress,
              categoryId: _categoryId,
            );

      widget.onSave(project);
      Navigator.of(context).pop();
    }
  }

  // Methode zum Löschen des Projekts
  void _deleteProject() {
    if (widget.project?.id != null && widget.onDelete != null) {
      widget.onDelete!(widget.project!.id!);
      Navigator.of(context).pop();
    }
  }

  // Zeigt einen Bestätigungsdialog an, bevor ein Projekt gelöscht wird
  void _showDeleteConfirmationDialog() {
    final localizations = Provider.of<AppLocalizations>(context, listen: false);

    PlatformAdaptiveDialog.showAdaptiveDialog(
      context: context,
      title: localizations.deleteConfirmation ?? 'Löschen bestätigen',
      content: Text(localizations.deleteProjectConfirmation ??
          'Möchtest du dieses Projekt wirklich löschen?'),
      actions: [
        PlatformAdaptiveDialog.adaptiveDialogAction(
          context: context,
          text: localizations.cancel ?? 'Abbrechen',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PlatformAdaptiveDialog.adaptiveDialogAction(
          context: context,
          text: localizations.delete ?? 'Löschen',
          isDestructiveAction: true,
          onPressed: () {
            Navigator.of(context).pop();
            _deleteProject();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = Provider.of<AppLocalizations>(context);
    final isEditing = widget.project != null;

    // Bestimme den Dialog-Titel
    final title = isEditing
        ? localizations.editProject ?? 'Projekt bearbeiten'
        : localizations.newProject ?? 'Neues Projekt';

    // Optimierter Dialog-Inhalt für beide Plattformen
    final dialogContent = Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Projektname
          PlatformAdaptiveForm.buildTextField(
            context: context,
            label: localizations.projectName ?? 'Projektname',
            initialValue: _name,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return localizations.fieldRequired ??
                    'Dieses Feld ist erforderlich';
              }
              return null;
            },
            onChanged: (value) => _name = value,
          ),

          const SizedBox(height: 16),

          // Projektbeschreibung
          PlatformAdaptiveForm.buildTextField(
            context: context,
            label: localizations.description ?? 'Beschreibung',
            initialValue: _description,
            maxLines: 3,
            onChanged: (value) => _description = value,
          ),

          const SizedBox(height: 16),

          // Startdatum
          PlatformAdaptiveForm.buildDatePicker(
            context: context,
            label: localizations.startDate ?? 'Startdatum',
            selectedDate: _startDate,
            onDateChanged: (date) {
              setState(() {
                _startDate = date;
                // Wenn das Enddatum vor dem Startdatum liegt, passen wir es an
                if (_endDate.isBefore(_startDate)) {
                  _endDate = _startDate.add(const Duration(days: 1));
                }
              });
            },
          ),

          const SizedBox(height: 16),

          // Enddatum
          PlatformAdaptiveForm.buildDatePicker(
            context: context,
            label: localizations.endDate ?? 'Enddatum',
            selectedDate: _endDate,
            firstDate: _startDate, // Enddatum muss nach Startdatum liegen
            onDateChanged: (date) {
              setState(() {
                _endDate = date;
              });
            },
          ),

          const SizedBox(height: 16),

          // Priorität
          PlatformAdaptiveForm.buildDropdown<int>(
            context: context,
            label: localizations.priority ?? 'Priorität',
            value: _priority,
            items: [
              DropdownMenuItem(
                value: 1,
                child: Text(localizations.lowPriority ?? 'Niedrig'),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(localizations.mediumPriority ?? 'Mittel'),
              ),
              DropdownMenuItem(
                value: 3,
                child: Text(localizations.highPriority ?? 'Hoch'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _priority = value ?? 2;
              });
            },
          ),

          const SizedBox(height: 16),

          // Fortschritt mit plattformspezifischem Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${localizations.progress ?? 'Fortschritt'}: $_progress%',
                style: _isIOS
                    ? const TextStyle(
                        fontSize: 15.0,
                        color: CupertinoColors.label,
                      )
                    : Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _isIOS
                  ? Column(
                      children: [
                        CupertinoSlider(
                          value: _progress.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          thumbColor: CupertinoColors.systemBlue,
                          activeColor: CupertinoColors.systemBlue,
                          onChanged: (value) {
                            setState(() {
                              _progress = value.toInt();
                            });
                          },
                        ),
                        // iOS-typische Beschriftung unter dem Slider
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '0%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                              Text(
                                '100%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Slider(
                          value: _progress.toDouble(),
                          min: 0,
                          max: 100,
                          divisions: 20,
                          label: '$_progress%',
                          onChanged: (value) {
                            setState(() {
                              _progress = value.toInt();
                            });
                          },
                        ),
                        // Material Design typische Beschriftung
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '0%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '100%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),

          const SizedBox(height: 16),

          // Kategorie
          if (widget.categories.isEmpty)
            // Wenn keine Kategorien verfügbar sind
            _isIOS
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.categoryLabel ?? 'Kategorie',
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Keine Kategorien verfügbar',
                          style: const TextStyle(
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      'Keine Kategorien verfügbar',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
          else
            _isIOS
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizations.categoryLabel ?? 'Kategorie',
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // iOS-spezifische Kategorieauswahl
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: () {
                          final categoryIndex = widget.categories.indexWhere(
                            (category) => category.id == _categoryId,
                          );

                          showCupertinoModalPopup(
                            context: context,
                            builder: (context) => Container(
                              height: 250,
                              padding: const EdgeInsets.only(top: 6.0),
                              color: CupertinoColors.systemBackground,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CupertinoButton(
                                        child: Text(localizations.cancel ??
                                            'Abbrechen'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                      CupertinoButton(
                                        child: Text(
                                            localizations.save ?? 'Fertig'),
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 0),
                                  Expanded(
                                    child: CupertinoPicker(
                                      scrollController:
                                          FixedExtentScrollController(
                                        initialItem: categoryIndex >= 0
                                            ? categoryIndex
                                            : 0,
                                      ),
                                      itemExtent: 40,
                                      onSelectedItemChanged: (index) {
                                        setState(() {
                                          _categoryId =
                                              widget.categories[index].id!;
                                        });
                                      },
                                      children:
                                          widget.categories.map((category) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: category.color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(category.name),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: widget.categories
                                        .firstWhere(
                                          (category) =>
                                              category.id == _categoryId,
                                          orElse: () => widget.categories.first,
                                        )
                                        .color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.categories
                                      .firstWhere(
                                        (category) =>
                                            category.id == _categoryId,
                                        orElse: () => widget.categories.first,
                                      )
                                      .name,
                                  style: const TextStyle(
                                    color: CupertinoColors.label,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              CupertinoIcons.chevron_down,
                              size: 16,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : PlatformAdaptiveForm.buildDropdown<int>(
                    context: context,
                    label: localizations.categoryLabel ?? 'Kategorie',
                    value: _categoryId,
                    items: widget.categories.map((category) {
                      return DropdownMenuItem(
                        value: category.id!,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: category.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(category.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _categoryId = value ?? 1;
                      });
                    },
                  ),
        ],
      ),
    );

    // Aktionen für den Dialog
    final List<Widget> dialogActions = [
      if (isEditing && widget.onDelete != null)
        PlatformAdaptiveDialog.adaptiveDialogAction(
          context: context,
          text: localizations.delete ?? 'Löschen',
          isDestructiveAction: true,
          onPressed: _showDeleteConfirmationDialog,
        ),
      PlatformAdaptiveDialog.adaptiveDialogAction(
        context: context,
        text: localizations.cancel ?? 'Abbrechen',
        onPressed: () => Navigator.of(context).pop(),
      ),
      PlatformAdaptiveDialog.adaptiveDialogAction(
        context: context,
        text: localizations.save ?? 'Speichern',
        onPressed: _saveProject,
      ),
    ];

    // Plattformspezifischen Dialog zurückgeben
    if (_isIOS) {
      // iOS-spezifischer Dialog mit besserer Scrolling-Unterstützung
      return Dialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        backgroundColor: CupertinoColors.systemBackground,
        child: Container(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titel im iOS-Stil
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17.0,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Scrollbarer Inhalt
              Flexible(
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(), // iOS-typische Scroll-Physik
                  child: dialogContent,
                ),
              ),
              const SizedBox(height: 16.0),
              // iOS-Stil Aktionsbuttons
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: CupertinoColors.separator.resolveFrom(context),
                      width: 0.5,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: dialogActions.map((action) {
                    // Spezielle Gestaltung für iOS-Buttons
                    if (action is CupertinoButton) {
                      return Expanded(
                        child: action,
                      );
                    } else if (action is TextButton) {
                      // Anpassen der TextButtons für iOS-Stil
                      return Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: action.onPressed,
                          child: action.child ?? const Text(''),
                        ),
                      );
                    }
                    return Expanded(child: action);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Material Design Dialog für Android
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: dialogContent,
        ),
        actions: dialogActions,
      );
    }
  }
}
