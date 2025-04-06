import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart';

enum RecurrenceType { variable, fixed }

class TransactionDialog extends StatefulWidget {
  final Transaction? transaction;

  const TransactionDialog({
    Key? key,
    this.transaction,
  }) : super(key: key);

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TransactionType _selectedType;
  late RecurrenceType _recurrenceType;
  String _selectedCategory = '';
  bool _isCustomCategory = false;

  bool _isProcessing = false;

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

  List<String> get _currentCategories => _selectedType == TransactionType.income
      ? _incomeCategories
      : _expenseCategories;

  @override
  void initState() {
    super.initState();

    // Set default values or load existing transaction data
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes;
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;

      // Kategorie initialisieren
      _selectedCategory = widget.transaction!.category;

      // Prüfen, ob es eine benutzerdefinierte Kategorie ist
      if (_selectedCategory.isNotEmpty) {
        if (!_currentCategories.contains(_selectedCategory)) {
          _isCustomCategory = true;
          _customCategoryController.text = _selectedCategory;
          _selectedCategory = 'Benutzerdefiniert';
        }
      } else {
        // Default-Kategorie wählen, wenn keine vorhanden
        _selectedCategory = _currentCategories.first;
      }

      // Wiederholungstyp (0 = variabel, 1 = fest)
      _recurrenceType = widget.transaction?.recurrenceType == 1
          ? RecurrenceType.fixed
          : RecurrenceType.variable;
    } else {
      _selectedDate = DateTime.now();
      _selectedType = TransactionType.expense;
      _selectedCategory = _expenseCategories.first;
      _recurrenceType = RecurrenceType.variable;
    }
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
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

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final financeService =
            Provider.of<FinanceService>(context, listen: false);

        // Bestimme die endgültige Kategorie
        final category = _getCurrentCategory();
        if (category.isEmpty) {
          // Zeige einen Fehler, wenn keine Kategorie ausgewählt wurde
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Bitte wählen Sie eine Kategorie aus')),
          );
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        final transaction = Transaction(
          id: widget.transaction?.id,
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          category: category,
          notes: _notesController.text,
          date: _selectedDate,
          type: _selectedType,
          recurrenceType: _recurrenceType == RecurrenceType.fixed ? 1 : 0,
        );

        if (widget.transaction == null) {
          // Create new transaction
          await financeService.addTransaction(transaction);
        } else {
          // Update existing transaction
          await financeService.updateTransaction(transaction);
        }

        // Close dialog on success
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  Future<void> _deleteTransaction() async {
    if (widget.transaction == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final financeService =
            Provider.of<FinanceService>(context, listen: false);
        await financeService.deleteTransaction(widget.transaction!.id!);

        // Close dialog on success
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        // Show error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final financeLoc = FinanceLocalizations(loc);

    return AlertDialog(
      title: Text(widget.transaction == null
          ? financeLoc.addTransaction
          : financeLoc.editTransaction),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransactionTypeSelector(financeLoc),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: financeLoc.title,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return financeLoc.requiredField;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: financeLoc.amount,
                  border: const OutlineInputBorder(),
                  prefixText: '€ ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return financeLoc.requiredField;
                  }
                  try {
                    final amount = double.parse(value);
                    if (amount <= 0) {
                      return 'Betrag muss größer als 0 sein';
                    }
                  } catch (e) {
                    return 'Bitte geben Sie einen gültigen Betrag ein';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Kategorieauswahl Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: financeLoc.category,
                  border: const OutlineInputBorder(),
                ),
                items: _currentCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedCategory = newValue;
                      _isCustomCategory = newValue == 'Benutzerdefiniert';
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return financeLoc.requiredField;
                  }
                  return null;
                },
              ),

              // Benutzerdefinierte Kategorie
              if (_isCustomCategory) ...[
                const SizedBox(height: 8),
                TextFormField(
                  controller: _customCategoryController,
                  decoration: InputDecoration(
                    labelText: 'Benutzerdefinierte Kategorie',
                    hintText: 'Eigene Kategorie eingeben',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_isCustomCategory &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Bitte geben Sie eine Kategorie ein';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: financeLoc.notes,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: financeLoc.date,
                    border: const OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd.MM.yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),

              // Wiederholungstyp Auswahl
              const SizedBox(height: 16),
              Text('Wiederholungstyp',
                  style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<RecurrenceType>(
                      title: const Text('Variabel'),
                      subtitle: const Text('Einmalig'),
                      value: RecurrenceType.variable,
                      groupValue: _recurrenceType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _recurrenceType = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<RecurrenceType>(
                      title: const Text('Fest'),
                      subtitle: const Text('Jeden Monat'),
                      value: RecurrenceType.fixed,
                      groupValue: _recurrenceType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _recurrenceType = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.transaction != null)
          TextButton(
            onPressed: _isProcessing ? null : _deleteTransaction,
            child: Text(financeLoc.delete),
          ),
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text(financeLoc.cancel),
        ),
        ElevatedButton(
          onPressed: _isProcessing ? null : _saveTransaction,
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Text(financeLoc.save),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeSelector(FinanceLocalizations financeLoc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          financeLoc.transactionType,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<TransactionType>(
          segments: [
            ButtonSegment<TransactionType>(
              value: TransactionType.income,
              label: Text(financeLoc.income),
              icon: const Icon(Icons.arrow_upward),
            ),
            ButtonSegment<TransactionType>(
              value: TransactionType.expense,
              label: Text(financeLoc.expense),
              icon: const Icon(Icons.arrow_downward),
            ),
            ButtonSegment<TransactionType>(
              value: TransactionType.transfer,
              label: Text(financeLoc.transfer),
              icon: const Icon(Icons.swap_horiz),
            ),
          ],
          selected: {_selectedType},
          onSelectionChanged: (Set<TransactionType> selected) {
            setState(() {
              _selectedType = selected.first;

              // Bei Änderung des Transaktionstyps eine gültige Kategorie auswählen
              List<String> newCategories =
                  _selectedType == TransactionType.income
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
      ],
    );
  }
}
