import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:muslim_calendar/ui/dialogs/category_edit_dialog.dart';
import 'package:muslim_calendar/ui/pages/category_management_page.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/ui/widgets/home/create_category_widget.dart';
import 'package:provider/provider.dart';

class CategoryFilterDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final Set<int> selectedCategoryIds;
  final Function(Set<int>) onCategoriesSelected;
  final Function() onCategoriesChanged;

  const CategoryFilterDialog({
    super.key,
    required this.categories,
    required this.selectedCategoryIds,
    required this.onCategoriesSelected,
    required this.onCategoriesChanged,
  });

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.selectedCategoryIds);
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);

    return AlertDialog(
      title: Text(loc.filterCategories),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var cat in widget.categories)
              CheckboxListTile(
                title: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: cat.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(child: Text(cat.name)),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Bearbeiten',
                      onPressed: () async {
                        Navigator.of(context).pop();

                        final result = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              CategoryEditDialog(category: cat),
                        );

                        if (result == true) {
                          widget.onCategoriesChanged();
                        }
                      },
                    ),
                    if (!cat.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        onPressed: () async {
                          // Bestätigungsdialog anzeigen
                          final confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Kategorie löschen'),
                              content: Text(
                                  'Möchten Sie die Kategorie "${cat.name}" wirklich löschen?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Abbrechen'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text('Löschen',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirmDelete == true) {
                            Navigator.of(context).pop();
                            // Löschung durchführen...
                            // (Implementierung würde hier Kategorie löschen)
                            widget.onCategoriesChanged();
                          }
                        },
                      ),
                  ],
                ),
                value: _selectedIds.contains(cat.id),
                onChanged: (selected) {
                  setState(() {
                    if (selected == true) {
                      _selectedIds.add(cat.id!);
                    } else {
                      _selectedIds.remove(cat.id!);
                    }
                  });
                },
              ),
            const Divider(),
            FilledButton(
              onPressed: () async {
                await showCreateCategoryDialog(
                  context,
                  loc,
                  onCategoryCreated: () {
                    widget.onCategoriesChanged();
                  },
                );
              },
              child: Text(loc.addNewCategory),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCategoriesSelected(_selectedIds);
            Navigator.of(context).pop();
          },
          child: Text(loc.apply),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CategoryManagementPage(),
              ),
            );
            widget.onCategoriesChanged();
          },
          child: const Text('Kategorien verwalten'),
        ),
      ],
    );
  }
}
