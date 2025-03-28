import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({Key? key}) : super(key: key);

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> {
  bool _isLoading = false;
  List<FinancialDebt> _debts = [];
  String _searchQuery = '';
  DebtType _filterType = DebtType.all;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final financeService =
          Provider.of<FinanceService>(context, listen: false);
      await financeService.loadDebts();
      _applyFilters();
    } catch (e) {
      print('Error loading debts: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    List<FinancialDebt> debts = List.from(financeService.debts);

    // Filter by type
    if (_filterType != DebtType.all) {
      debts = debts.where((d) => d.type == _filterType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      debts = debts
          .where((d) =>
              d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.person.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              d.notes.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _debts = debts;
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
                : _debts.isEmpty
                    ? Center(
                        child: Text(financeLoc.noDebts),
                      )
                    : ListView.separated(
                        itemCount: _debts.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final debt = _debts[index];
                          return _buildDebtItem(
                              context, debt, financeService, financeLoc);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDebtDialog(context, financeService, financeLoc),
        tooltip: financeLoc.addDebt,
        child: const Icon(Icons.add),
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
              hintText: financeLoc.searchDebts,
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
                  label: financeLoc.allDebts,
                  selected: _filterType == DebtType.all,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = DebtType.all;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.youOwe,
                  selected: _filterType == DebtType.youOwe,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = DebtType.youOwe;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.theyOwe,
                  selected: _filterType == DebtType.theyOwe,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterType = DebtType.theyOwe;
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

  Widget _buildDebtItem(BuildContext context, FinancialDebt debt,
      FinanceService financeService, FinanceLocalizations financeLoc) {
    final currencyFormat = NumberFormat.currency(symbol: '€');

    IconData typeIcon;
    Color typeColor;
    String statusText;

    if (debt.type == DebtType.youOwe) {
      typeIcon = Icons.arrow_upward;
      typeColor = Colors.red;
      statusText = financeLoc.youOwe;
    } else {
      typeIcon = Icons.arrow_downward;
      typeColor = Colors.green;
      statusText = financeLoc.theyOwe;
    }

    double remainingAmount = debt.amount - debt.paidAmount;
    bool isPaid = remainingAmount <= 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isPaid ? Colors.green.withOpacity(0.2) : typeColor.withOpacity(0.2),
        child: Icon(
          isPaid ? Icons.check : typeIcon,
          color: isPaid ? Colors.green : typeColor,
        ),
      ),
      title: Text(
        debt.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: isPaid ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                debt.person,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? Colors.green.withOpacity(0.1)
                      : typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  isPaid ? financeLoc.paid : statusText,
                  style: TextStyle(
                    fontSize: 10,
                    color: isPaid ? Colors.green : typeColor,
                  ),
                ),
              ),
            ],
          ),
          if (debt.dueDate != null)
            Text(
              '${financeLoc.dueDate}: ${DateFormat('dd.MM.yyyy').format(debt.dueDate!)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            currencyFormat.format(debt.amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isPaid ? Colors.grey : typeColor,
              decoration: isPaid ? TextDecoration.lineThrough : null,
            ),
          ),
          if (debt.paidAmount > 0 && !isPaid)
            Text(
              '${financeLoc.remaining}: ${currencyFormat.format(remainingAmount)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
      onTap: () =>
          _showDebtDialog(context, financeService, financeLoc, debt: debt),
    );
  }

  void _showDebtDialog(BuildContext context, FinanceService financeService,
      FinanceLocalizations financeLoc,
      {FinancialDebt? debt}) async {
    // Vorübergehend deaktiviert, bis der DebtDialog implementiert ist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debt Dialog noch nicht implementiert'),
      ),
    );
    /* Auskommentiert bis DebtDialog implementiert ist
    await showDialog(
      context: context,
      builder: (context) => DebtDialog(
        debt: debt,
      ),
    );
    */

    // Reload debts after dialog is closed
    _loadDebts();
  }
}
