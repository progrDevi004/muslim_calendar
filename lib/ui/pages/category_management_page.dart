import 'package:flutter/material.dart';
import 'package:muslim_calendar/ui/widgets/category_list_widget.dart';
import 'package:muslim_calendar/data/repositories/category_repository.dart';
import 'package:muslim_calendar/models/category_model.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:muslim_calendar/data/services/calendar_sync_service.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  _CategoryManagementPageState createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  bool _refreshKey = false;

  void _refreshCategories() {
    setState(() {
      _refreshKey = !_refreshKey;
    });
  }

  Future<void> _showAddCategoryDialog() async {
    final TextEditingController nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Neue Kategorie'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Kategoriename',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Farbe:'),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Farbe wählen'),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: selectedColor,
                                    onColorChanged: (color) {
                                      setState(() => selectedColor = color);
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
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Abbrechen'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedColor,
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
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Bitte gib einen Namen ein'),
                        ),
                      );
                      return;
                    }

                    final category = CategoryModel.newCategory(
                      name: name,
                      color: selectedColor,
                    );

                    try {
                      await CategoryRepository().insertCategory(category);

                      // CalendarSyncService über Kategorieänderung informieren
                      if (mounted) {
                        Provider.of<CalendarSyncService>(context, listen: false)
                            .notifyCategoryChanges();
                      }

                      Navigator.of(context).pop(true);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fehler beim Erstellen: $e'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      _refreshCategories();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategorie wurde erstellt')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorien verwalten'),
      ),
      body: Column(
        children: [
          Expanded(
            child: CategoryListWidget(
              key: ValueKey(_refreshKey),
              onCategoriesChanged: _refreshCategories,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        tooltip: 'Kategorie hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }
}
