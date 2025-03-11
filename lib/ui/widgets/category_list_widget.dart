import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:muslim_calendar/ui/dialogs/category_edit_dialog.dart';
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';
import 'package:provider/provider.dart';

class CategoryListWidget extends StatefulWidget {
  final Function()? onCategoriesChanged;

  const CategoryListWidget({
    Key? key,
    this.onCategoriesChanged,
  }) : super(key: key);

  @override
  _CategoryListWidgetState createState() => _CategoryListWidgetState();
}

class _CategoryListWidgetState extends State<CategoryListWidget> {
  final CategoryRepository _repository = CategoryRepository();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  late CalendarSyncService _calendarSyncService;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // CalendarSyncService registrieren
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: true);

    // Listener hinzufügen, um auf Änderungen zu reagieren
    _calendarSyncService.addListener(_onCategoriesChanged);
  }

  @override
  void dispose() {
    // Listener entfernen
    _calendarSyncService.removeListener(_onCategoriesChanged);
    super.dispose();
  }

  // Wird aufgerufen, wenn sich Kategorien ändern
  void _onCategoriesChanged() {
    debugPrint(
        "🔄 CategoryListWidget: Kategorien wurden geändert, lade neu...");
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = await _repository.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Kategorien: $e')),
      );
    }
  }

  Future<void> _showEditDialog(CategoryModel category) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => CategoryEditDialog(category: category),
    );

    if (result == true) {
      // Kategorie wurde aktualisiert, lade die Liste neu
      _loadCategories();

      // Informiere den übergeordneten Widget über die Änderung
      if (widget.onCategoriesChanged != null) {
        widget.onCategoriesChanged!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategorie wurde aktualisiert')),
      );
    }
  }

  Future<void> _showDeleteConfirmation(CategoryModel category) async {
    if (category.id == 1 || category.id == 2 || category.id == 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Standardkategorien können nicht gelöscht werden')),
      );
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategorie löschen'),
        content: Text(
            'Möchtest du die Kategorie "${category.name}" wirklich löschen?\n'
            'Alle Termine dieser Kategorie werden zur Standardkategorie verschoben.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _repository.deleteCategory(category.id!);
        _loadCategories();

        // Informiere den übergeordneten Widget über die Änderung
        if (widget.onCategoriesChanged != null) {
          widget.onCategoriesChanged!();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategorie wurde gelöscht')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_categories.isEmpty) {
      return const Center(
        child: Text('Keine Kategorien vorhanden'),
      );
    }

    return ListView.builder(
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        final bool isStandardCategory =
            category.id == 1 || category.id == 2 || category.id == 3;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: category.color,
            child: Text(
              category.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: ThemeData.estimateBrightnessForColor(category.color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
            ),
          ),
          title: Text(category.name),
          subtitle: isStandardCategory
              ? const Text('Standardkategorie',
                  style: TextStyle(fontStyle: FontStyle.italic))
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showEditDialog(category),
                tooltip: 'Bearbeiten',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: isStandardCategory
                    ? null // Deaktiviert für Standardkategorien
                    : () => _showDeleteConfirmation(category),
                tooltip: isStandardCategory
                    ? 'Standardkategorien können nicht gelöscht werden'
                    : 'Löschen',
                color: isStandardCategory ? Colors.grey : Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }
}
