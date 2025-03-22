import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:muslim_calendar/ui/dialogs/category_edit_dialog.dart';
import 'package:muslim_calendar/localization/app_localizations.dart';
import 'package:muslim_calendar/ui/widgets/home/create_category_widget.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';

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
                    Expanded(
                      child: Text(
                        cat.name,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          tooltip: loc.edit,
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
                        const SizedBox(width: 8),
                        if (!cat.isDefault)
                          IconButton(
                            icon: const Icon(Icons.delete, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              // Bestätigungsdialog anzeigen
                              final confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(loc.deleteCategory),
                                  content: Text(
                                      loc.getDeleteCategoryConfirmation(
                                          loc.currentLanguage, cat.name)),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                      child: Text(loc.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                      child: Text(loc.delete,
                                          style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmDelete == true) {
                                Navigator.of(context).pop();
                                // Löschung durchführen...
                                await Provider.of<CategoryRepository>(context,
                                        listen: false)
                                    .deleteCategory(cat.id!);
                                widget.onCategoriesChanged();
                              }
                            },
                          ),
                      ],
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
            setState(() {
              widget.onCategoriesSelected(_selectedIds);
            });
            Navigator.of(context).pop();
          },
          child: Text(loc.apply),
        ),
      ],
    );
  }
}
