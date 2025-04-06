import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart' as models;
import 'package:Taqvimi/ui/dialogs/finance/transaction_dialog.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({Key? key}) : super(key: key);

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  bool _isLoading = false;
  List<models.Transaction> _filteredTransactions = [];
  String _searchQuery = '';
  models.TransactionType _filterType = models.TransactionType.all;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final financeService =
          Provider.of<FinanceService>(context, listen: false);
      await financeService.loadTransactionsForMonth();
      _applyFilters();
    } catch (e) {
      print('Error loading transactions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    List<models.Transaction> transactions = financeService.transactions;

    // Filter by type
    if (_filterType != models.TransactionType.all) {
      transactions = transactions.where((t) => t.type == _filterType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      transactions = transactions
          .where((t) =>
              t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              t.notes.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredTransactions = transactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeService = Provider.of<FinanceService>(context);
    final loc = Provider.of<AppLocalizations>(context);
    final financeLoc = FinanceLocalizations(loc);

    return Scaffold(
      body: Column(
        children: [
          _buildSearchAndFilters(context, financeLoc),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Text(financeLoc.noTransactions),
                      )
                    : ListView.separated(
                        itemCount: _filteredTransactions.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final transaction = _filteredTransactions[index];
                          return _buildTransactionItem(
                              context, transaction, financeService, financeLoc);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
      BuildContext context, FinanceLocalizations financeLoc) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: financeLoc.searchTransactions,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
          ),
          const SizedBox(height: 8.0),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip(
                  context: context,
                  label: financeLoc.allTransactions,
                  selected: _filterType == models.TransactionType.all,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = models.TransactionType.all;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.income,
                  selected: _filterType == models.TransactionType.income,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = models.TransactionType.income;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.expense,
                  selected: _filterType == models.TransactionType.expense,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = models.TransactionType.expense;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.transfer,
                  selected: _filterType == models.TransactionType.transfer,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = models.TransactionType.transfer;
                      });
                      _applyFilters();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool selected,
    required Function(bool) onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildTransactionItem(
      BuildContext context,
      models.Transaction transaction,
      FinanceService financeService,
      FinanceLocalizations financeLoc) {
    final currencyFormat = NumberFormat.currency(symbol: '€');

    IconData typeIcon;
    Color typeColor;

    switch (transaction.type) {
      case models.TransactionType.income:
        typeIcon = Icons.arrow_upward;
        typeColor = Colors.green;
        break;
      case models.TransactionType.expense:
        typeIcon = Icons.arrow_downward;
        typeColor = Colors.red;
        break;
      case models.TransactionType.transfer:
        typeIcon = Icons.swap_horiz;
        typeColor = Colors.blue;
        break;
      default:
        typeIcon = Icons.help_outline;
        typeColor = Colors.grey;
    }

    // Indikator für wiederkehrende Transaktionen
    final bool isRecurring = transaction.recurrenceType == 1; // 1 = fixed

    return Dismissible(
      key: Key(transaction.id ?? 'unknown'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        if (isRecurring) {
          // Bei wiederkehrenden Transaktionen nachfragen, ob alle oder nur diese gelöscht werden soll
          return await _showDeleteConfirmationDialog(
              context, transaction, financeService, financeLoc);
        } else {
          // Normale Bestätigung für nicht-wiederkehrende Transaktionen
          return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(financeLoc.delete),
              content: Text('${financeLoc.delete} "${transaction.title}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(financeLoc.cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(financeLoc.delete),
                ),
              ],
            ),
          );
        }
      },
      onDismissed: (direction) {
        // Transaktion wird durch _showDeleteConfirmationDialog gelöscht
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withOpacity(0.2),
          child: Icon(
            typeIcon,
            color: typeColor,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                transaction.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isRecurring)
              Tooltip(
                message: "Feste monatliche Transaktion",
                child: Icon(
                  Icons.repeat,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd.MM.yyyy').format(transaction.date),
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            if (transaction.category.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4.0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  transaction.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
        trailing: Text(
          currencyFormat.format(transaction.amount),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: typeColor,
          ),
        ),
        onTap: () => _showTransactionDialog(context, financeService, financeLoc,
            transaction: transaction),
      ),
    );
  }

  Future<bool> _showDeleteConfirmationDialog(
      BuildContext context,
      models.Transaction transaction,
      FinanceService financeService,
      FinanceLocalizations financeLoc) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(financeLoc.delete),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${financeLoc.delete} "${transaction.title}"?'),
            const SizedBox(height: 16),
            const Text(
                "Dies ist eine wiederkehrende Transaktion. Was möchten Sie löschen?"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: Text(financeLoc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('single'),
            child: const Text("Nur diese"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('all'),
            child: const Text("Alle Wiederholungen"),
          ),
        ],
      ),
    );

    if (result == 'single') {
      // Nur diese eine Transaktion löschen
      await financeService.deleteTransaction(transaction.id!);
      return true;
    } else if (result == 'all') {
      // Alle wiederkehrenden Transaktionen löschen
      await financeService.deleteRecurringTransaction(transaction);
      return true;
    }

    return false;
  }

  void _showTransactionDialog(BuildContext context,
      FinanceService financeService, FinanceLocalizations financeLoc,
      {models.Transaction? transaction}) async {
    await showDialog(
      context: context,
      builder: (context) => TransactionDialog(
        financeService: financeService,
        financeLoc: financeLoc,
        transaction: transaction,
        selectedDate: DateTime.now(),
      ),
    );

    // Reload transactions after dialog is closed
    _loadTransactions();
  }
}
