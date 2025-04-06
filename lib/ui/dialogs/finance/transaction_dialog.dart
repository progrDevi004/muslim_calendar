import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/data/repositories/finance_repository.dart' as repo;
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart' as models;

enum RecurrenceType { variable, fixed }

class TransactionDialog extends StatefulWidget {
  final FinanceService financeService;
  final FinanceLocalizations financeLoc;
  final models.Transaction? transaction;
  final DateTime selectedDate;

  const TransactionDialog({
    Key? key,
    required this.financeService,
    required this.financeLoc,
    this.transaction,
    required this.selectedDate,
  }) : super(key: key);

  @override
  _TransactionDialogState createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _customCategoryController;
  late final TextEditingController _notesController;
  late DateTime _selectedDate;
  late models.TransactionType _selectedType;
  late RecurrenceType _recurrenceType;
  late String _selectedCategory;
  bool _isCustomCategory = false;

  // Vordefinierte Kategorien für Einnahmen und Ausgaben
  final List<String> _incomeCategories = [
    'Gehalt',
    'Freelance',
    'Geschenk',
    'Rückerstattung',
    'Sonstige Einnahmen',
    'Benutzerdefiniert',
  ];

  final List<String> _expenseCategories = [
    'Lebensmittel',
    'Wohnen',
    'Transport',
    'Unterhaltung',
    'Gesundheit',
    'Kleidung',
    'Bildung',
    'Reisen',
    'Geschenke',
    'Sonstige Ausgaben',
    'Benutzerdefiniert',
  ];

  List<String> get _currentCategories =>
      _selectedType == models.TransactionType.income
          ? _incomeCategories
          : _expenseCategories;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.transaction?.title ?? '');
    _amountController = TextEditingController(
      text: widget.transaction?.amount.toString() ?? '',
    );
    _customCategoryController = TextEditingController();
    _notesController = TextEditingController(
      text: widget.transaction?.notes ?? '',
    );
    _selectedDate = widget.transaction?.date ?? widget.selectedDate;
    _selectedType = widget.transaction?.type ?? models.TransactionType.expense;

    // Kategorie initialisieren
    _selectedCategory = widget.transaction?.category ?? '';

    // Prüfen, ob es eine benutzerdefinierte Kategorie ist
    if (_selectedCategory.isNotEmpty) {
      if (!_currentCategories.contains(_selectedCategory) ||
          _selectedCategory == 'Benutzerdefiniert') {
        _isCustomCategory = true;
        _customCategoryController.text = _selectedCategory;
        _selectedCategory = 'Benutzerdefiniert';
      }
    } else {
      // Default-Kategorie wählen, wenn keine vorhanden
      _selectedCategory = _currentCategories.first;
    }

    // Wiederholungstyp initialisieren (0 = variabel, 1 = fest/wiederkehrend)
    _recurrenceType = widget.transaction?.recurrenceType == 1
        ? RecurrenceType.fixed
        : RecurrenceType.variable;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _customCategoryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Methode zum Abrufen der aktuellen Kategorie
  String _getCurrentCategory() {
    if (_isCustomCategory) {
      return _customCategoryController.text;
    } else {
      return _selectedCategory != 'Benutzerdefiniert' ? _selectedCategory : '';
    }
  }

  void _saveTransaction() {
    if (_titleController.text.isEmpty || _amountController.text.isEmpty) {
      return;
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      return;
    }

    // Bestimme die endgültige Kategorie
    final category = _getCurrentCategory();
    if (category.isEmpty) {
      // Zeige einen Fehler, wenn keine Kategorie ausgewählt wurde
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte wählen Sie eine Kategorie aus')),
      );
      return;
    }

    // Stelle sicher, dass recurrenceType immer als Integer gespeichert wird
    final int recurrenceTypeValue =
        _recurrenceType == RecurrenceType.fixed ? 1 : 0;

    if (widget.transaction == null) {
      // Neue Transaktion erstellen
      final newTransaction = models.Transaction(
        title: _titleController.text,
        amount: amount,
        category: category,
        notes: _notesController.text,
        date: _selectedDate,
        type: _selectedType,
        recurrenceType: recurrenceTypeValue,
      );
      widget.financeService.addTransaction(newTransaction);
    } else {
      // Existierende Transaktion aktualisieren
      final updatedTransaction = widget.transaction!.copyWith(
        title: _titleController.text,
        amount: amount,
        category: category,
        notes: _notesController.text,
        date: _selectedDate,
        type: _selectedType,
        recurrenceType: recurrenceTypeValue,
      );
      widget.financeService.updateTransaction(updatedTransaction);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final titleText = widget.transaction == null
        ? widget.financeLoc.addTransaction
        : widget.financeLoc.editTransaction;

    return AlertDialog(
      title: Text(titleText),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: widget.financeLoc.title,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: widget.financeLoc.amount,
                prefixText: '€ ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: widget.financeLoc.category,
              ),
              hint: Text("Kategorie wählen"),
              items: _currentCategories
                  .map((cat) => DropdownMenuItem<String>(
                        value: cat,
                        child: Text(cat),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                    _isCustomCategory = value == 'Benutzerdefiniert';
                  });
                }
              },
            ),
            const SizedBox(height: 5),
            // Benutzerdefinierte Kategorie
            if (_isCustomCategory)
              TextField(
                controller: _customCategoryController,
                decoration: InputDecoration(
                  labelText: "Benutzerdefinierte Kategorie",
                  hintText: "Eigene Kategorie eingeben",
                ),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: widget.financeLoc.notes,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(widget.financeLoc.date),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(
                    DateFormat('dd.MM.yyyy').format(_selectedDate),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(widget.financeLoc.transactionType),
            const SizedBox(height: 5),
            SegmentedButton<models.TransactionType>(
              segments: [
                ButtonSegment<models.TransactionType>(
                  value: models.TransactionType.expense,
                  label: Text(widget.financeLoc.expense),
                  icon: const Icon(Icons.arrow_downward),
                ),
                ButtonSegment<models.TransactionType>(
                  value: models.TransactionType.income,
                  label: Text(widget.financeLoc.income),
                  icon: const Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedType = selected.first;

                  // Bei Änderung des Transaktionstyps eine gültige Kategorie auswählen
                  List<String> newCategories =
                      _selectedType == models.TransactionType.income
                          ? _incomeCategories
                          : _expenseCategories;

                  // Prüfe, ob aktuelle Kategorie in der neuen Liste existiert
                  if (!newCategories.contains(_selectedCategory)) {
                    // Wenn nicht, wähle eine Standard-Kategorie aus der neuen Liste
                    _selectedCategory = newCategories.first;
                    _isCustomCategory = false;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            const Text("Wiederkehrend"),
            const SizedBox(height: 5),
            Column(
              children: [
                RadioListTile<RecurrenceType>(
                  title: const Text('Variabel (einmalig)'),
                  value: RecurrenceType.variable,
                  groupValue: _recurrenceType,
                  onChanged: (value) {
                    setState(() {
                      _recurrenceType = value!;
                    });
                  },
                ),
                RadioListTile<RecurrenceType>(
                  title: const Text('Fest (monatlich wiederkehrend)'),
                  subtitle:
                      const Text('Wird automatisch jeden Monat angezeigt'),
                  value: RecurrenceType.fixed,
                  groupValue: _recurrenceType,
                  onChanged: (value) {
                    setState(() {
                      _recurrenceType = value!;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.financeLoc.cancel),
        ),
        ElevatedButton(
          onPressed: _saveTransaction,
          child: Text(widget.financeLoc.save),
        ),
      ],
    );
  }
}
