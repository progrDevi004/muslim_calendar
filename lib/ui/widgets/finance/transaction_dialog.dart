import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart';

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
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  late DateTime _selectedDate;
  late TransactionType _selectedType;

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    // Set default values or load existing transaction data
    if (widget.transaction != null) {
      _titleController.text = widget.transaction!.title;
      _amountController.text = widget.transaction!.amount.toString();
      _categoryController.text = widget.transaction!.category;
      _notesController.text = widget.transaction!.notes;
      _selectedDate = widget.transaction!.date;
      _selectedType = widget.transaction!.type;
    } else {
      _selectedDate = DateTime.now();
      _selectedType = TransactionType.expense;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
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

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final financeService =
            Provider.of<FinanceService>(context, listen: false);

        final transaction = Transaction(
          id: widget.transaction?.id,
          title: _titleController.text,
          amount: double.parse(_amountController.text),
          category: _categoryController.text,
          notes: _notesController.text,
          date: _selectedDate,
          type: _selectedType,
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
                  if (value == null || value.isEmpty) {
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return financeLoc.requiredField;
                  }
                  if (double.tryParse(value) == null) {
                    return financeLoc.invalidNumberFormat;
                  }
                  if (double.parse(value) <= 0) {
                    return financeLoc.amountGreaterThanZero;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: financeLoc.category,
                  border: const OutlineInputBorder(),
                ),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: financeLoc.notes,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.transaction != null)
          TextButton(
            onPressed: _isProcessing ? null : _deleteTransaction,
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(financeLoc.delete),
          ),
        TextButton(
          onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
          child: Text(financeLoc.cancel),
        ),
        FilledButton(
          onPressed: _isProcessing ? null : _saveTransaction,
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
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
            });
          },
        ),
      ],
    );
  }
}
