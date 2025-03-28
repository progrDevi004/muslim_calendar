import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/data/repositories/finance_repository.dart' as repo;
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart' as models;

class TransactionDialog extends StatefulWidget {
  final models.Transaction? transaction;

  const TransactionDialog({
    Key? key,
    this.transaction,
  }) : super(key: key);

  @override
  State<TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<TransactionDialog> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  models.TransactionType _transactionType = models.TransactionType.expense;
  repo.RecurrenceType _recurrenceType = repo.RecurrenceType.none;
  String? _category;
  Color? _categoryColor;

  @override
  void initState() {
    super.initState();

    // Wenn eine bestehende Transaktion übergeben wurde, Felder initialisieren
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _descriptionController.text = widget.transaction!.notes;
      _amountController.text = widget.transaction!.amount.toString();
      _selectedDate = widget.transaction!.date;
      _transactionType = widget.transaction!.type;
      _category = widget.transaction!.category;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
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

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(
        _amountController.text.trim().replaceAll(',', '.'),
      );

      final financeService =
          Provider.of<FinanceService>(context, listen: false);

      if (widget.transaction == null) {
        // Neue Transaktion erstellen
        final transaction = models.Transaction(
          title: _titleController.text.trim(),
          notes: _descriptionController.text.trim(),
          amount: amount,
          date: _selectedDate,
          type: _transactionType,
          category: _category ?? "",
        );

        financeService.addTransaction(transaction);
      } else {
        // Bestehende Transaktion aktualisieren
        final transaction = widget.transaction!.copyWith(
          title: _titleController.text.trim(),
          notes: _descriptionController.text.trim(),
          amount: amount,
          date: _selectedDate,
          type: _transactionType,
          category: _category,
        );

        financeService.updateTransaction(transaction);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final financeLoc = FinanceLocalizations(loc);

    return AlertDialog(
      title: Text(
        widget.transaction == null
            ? financeLoc.addTransaction
            : financeLoc.editTransaction,
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel
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

              // Beschreibung
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: financeLoc.description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Betrag
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: financeLoc.amount,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.euro),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return financeLoc.requiredField;
                  }
                  try {
                    double.parse(value.replaceAll(',', '.'));
                    return null;
                  } catch (e) {
                    return "Ungültige Nummer";
                  }
                },
              ),
              const SizedBox(height: 16),

              // Datum
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: financeLoc.date,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    controller: TextEditingController(
                      text: DateFormat('dd.MM.yyyy').format(_selectedDate),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Transaktionstyp
              Text(
                financeLoc.transactionType,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<models.TransactionType>(
                      title: Text(financeLoc.income),
                      value: models.TransactionType.income,
                      groupValue: _transactionType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _transactionType = value;
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<models.TransactionType>(
                      title: Text(financeLoc.expense),
                      value: models.TransactionType.expense,
                      groupValue: _transactionType,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _transactionType = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Hier könnte noch eine Kategorie-Auswahl hinzugefügt werden
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(financeLoc.cancel),
        ),
        ElevatedButton(
          onPressed: _saveTransaction,
          child: Text(financeLoc.save),
        ),
      ],
    );
  }
}
