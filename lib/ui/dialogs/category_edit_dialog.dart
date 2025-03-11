import 'package:flutter/material.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';
import 'package:provider/provider.dart';

class CategoryEditDialog extends StatefulWidget {
  final CategoryModel category;

  const CategoryEditDialog({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  _CategoryEditDialogState createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  late TextEditingController _nameController;
  late Color _selectedColor;
  final CategoryRepository _categoryRepository = CategoryRepository();
  late CalendarSyncService _calendarSyncService;
  bool _isStandardCategory = false;
  bool _isLoading = false;
  CategoryModel? _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
    _nameController = TextEditingController(text: _currentCategory!.name);
    _selectedColor = _currentCategory!.color;

    // Prüfen, ob es sich um eine Standardkategorie handelt
    _isStandardCategory = _currentCategory!.id == 1 ||
        _currentCategory!.id == 2 ||
        _currentCategory!.id == 3;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider für CalendarSyncService holen
    _calendarSyncService =
        Provider.of<CalendarSyncService>(context, listen: true);

    // Wenn sich der CalendarSyncService ändert (z.B. durch neue Kategorien),
    // lade die aktuelle Kategorie neu
    _refreshCurrentCategory();
  }

  /// Aktualisiert die Kategoriedaten aus dem Repository
  Future<void> _refreshCurrentCategory() async {
    if (_currentCategory?.id == null) return;

    try {
      final updatedCategory =
          await _categoryRepository.getCategory(_currentCategory!.id!);
      if (updatedCategory != null && mounted) {
        setState(() {
          _currentCategory = updatedCategory;
          // Nur Name aktualisieren, wenn er nicht manuell geändert wurde
          if (_nameController.text == widget.category.name) {
            _nameController.text = updatedCategory.name;
          }
          _selectedColor = updatedCategory.color;
        });
      }
    } catch (e) {
      debugPrint("Fehler beim Aktualisieren der Kategorie: $e");
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategoriename darf nicht leer sein')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCategory = CategoryModel(
        id: _currentCategory!.id,
        name: _nameController.text.trim(),
        color: _selectedColor,
        isDefault: _currentCategory!.isDefault,
      );

      await _categoryRepository.updateCategory(updatedCategory);

      // Nach dem Speichern den CalendarSyncService benachrichtigen
      _calendarSyncService.notifyCategoryChanges();

      if (mounted) {
        Navigator.of(context).pop(true); // true = Kategorie wurde aktualisiert
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Speichern: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Farbe wählen'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
              Navigator.of(context).pop();
            },
            availableColors: const [
              Colors.red,
              Colors.pink,
              Colors.purple,
              Colors.deepPurple,
              Colors.indigo,
              Colors.blue,
              Colors.lightBlue,
              Colors.cyan,
              Colors.teal,
              Colors.green,
              Colors.lightGreen,
              Colors.lime,
              Colors.yellow,
              Colors.amber,
              Colors.orange,
              Colors.deepOrange,
              Colors.brown,
              Colors.grey,
              Colors.blueGrey,
              Colors.black,
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isStandardCategory
          ? 'Standardkategorie bearbeiten'
          : 'Kategorie bearbeiten'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isStandardCategory)
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  'Hinweis: Bei Standardkategorien kann nur die Farbe geändert werden.',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              ),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Kategoriename',
                border: OutlineInputBorder(),
              ),
              enabled:
                  !_isStandardCategory, // Deaktivieren für Standardkategorien
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Farbe:'),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _openColorPicker,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCategory,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Speichern'),
        ),
      ],
    );
  }
}
