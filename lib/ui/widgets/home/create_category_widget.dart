import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/models/category_model.dart';
import 'package:Taqvimi/data/repositories/category_repository.dart';

class CreateCategoryWidget extends StatefulWidget {
  final Function() onCategoryCreated;
  final AppLocalizations localizations;

  const CreateCategoryWidget({
    super.key,
    required this.onCategoryCreated,
    required this.localizations,
  });

  @override
  State<CreateCategoryWidget> createState() => _CreateCategoryWidgetState();
}

class _CreateCategoryWidgetState extends State<CreateCategoryWidget> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = Colors.blue;
  final CategoryRepository _categoryRepo = CategoryRepository();

  // Vorschlag verschiedener Farben zur Auswahl
  final List<Color> _colorOptions = [
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
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createCategory() async {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final newCategory = CategoryModel.newCategory(
        name: name,
        color: _selectedColor,
      );
      await _categoryRepo.insertCategory(newCategory);
      widget.onCategoryCreated();
      Navigator.of(context).pop();

      // Zeige Bestätigung an
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kategorie "$name" erstellt'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.localizations.addNewCategory),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: widget.localizations.titleLabel,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Farbe auswählen:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            width: double.maxFinite,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _colorOptions.length,
              itemBuilder: (context, index) {
                final color = _colorOptions[index];
                final isSelected = color.value == _selectedColor.value;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedColor = color;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4)
                            ]
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.localizations.cancel),
        ),
        FilledButton(
          onPressed: _createCategory,
          child: Text(widget.localizations.save),
        ),
      ],
    );
  }
}

// Hilfsmethode zum Anzeigen des Dialogs
Future<void> showCreateCategoryDialog(
    BuildContext context, AppLocalizations localizations,
    {required Function() onCategoryCreated}) {
  return showDialog(
    context: context,
    builder: (ctx) => CreateCategoryWidget(
      onCategoryCreated: onCategoryCreated,
      localizations: localizations,
    ),
  );
}
