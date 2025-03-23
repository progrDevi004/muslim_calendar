import 'package:flutter/material.dart';
import 'package:Taqvimi/models/category_model.dart';
import 'package:Taqvimi/ui/dialogs/category_edit_dialog.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/ui/widgets/home/create_category_widget.dart';
import 'package:provider/provider.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';

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
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(
          maxHeight: 600,
          maxWidth: 400,
        ),
        child: Scaffold(
          appBar: AppBar(
            title: Text(loc.filterCategories),
            centerTitle: false,
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  loc.cancel,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  // Sicherheitshalber nochmal aufrufen, falls es während des Dialogs weitere Änderungen gab
                  widget.onCategoriesSelected(_selectedIds);
                  Navigator.of(context).pop();
                },
                child: Text(
                  loc.apply,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.separated(
                  itemCount: widget.categories.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final cat = widget.categories[index];
                    return Material(
                      color: theme.colorScheme.surface,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedIds.contains(cat.id)) {
                              _selectedIds.remove(cat.id!);
                            } else {
                              _selectedIds.add(cat.id!);
                            }
                            // Sofort die Änderung weitergeben
                            widget.onCategoriesSelected(_selectedIds);
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              // Farbiger Punkt
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: cat.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Kategorienname
                              Expanded(
                                child: Text(
                                  cat.name,
                                  style: theme.textTheme.bodyLarge,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // Bearbeiten-Symbol
                              IconButton(
                                icon: const Icon(Icons.edit),
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
                              // Löschen-Symbol (nur für nicht-Standard-Kategorien)
                              if (!cat.isDefault)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () async {
                                    // Bestätigungsdialog anzeigen
                                    final confirmDelete =
                                        await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: Text(loc.deleteCategory),
                                        content: Text(
                                          loc.getDeleteCategoryConfirmation(
                                            loc.currentLanguage,
                                            cat.name,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(false),
                                            child: Text(loc.cancel),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(ctx).pop(true),
                                            child: Text(
                                              loc.delete,
                                              style: const TextStyle(
                                                  color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmDelete == true) {
                                      Navigator.of(context).pop();
                                      // Löschung durchführen...
                                      await Provider.of<CategoryRepository>(
                                        context,
                                        listen: false,
                                      ).deleteCategory(cat.id!);
                                      widget.onCategoriesChanged();
                                    }
                                  },
                                ),
                              // Häkchen für ausgewählte Kategorien
                              Icon(
                                Icons.check,
                                color: _selectedIds.contains(cat.id)
                                    ? theme.colorScheme.primary
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // "Neue Kategorie" Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006C58),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                    onPressed: () async {
                      await showCreateCategoryDialog(
                        context,
                        loc,
                        onCategoryCreated: () {
                          widget.onCategoriesChanged();
                        },
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add),
                        const SizedBox(width: 8),
                        Text(loc.addNewCategory),
                      ],
                    ),
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
