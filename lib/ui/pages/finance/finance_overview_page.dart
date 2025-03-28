import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart';

class FinanceOverviewPage extends StatefulWidget {
  const FinanceOverviewPage({Key? key}) : super(key: key);

  @override
  State<FinanceOverviewPage> createState() => _FinanceOverviewPageState();
}

class _FinanceOverviewPageState extends State<FinanceOverviewPage> {
  bool _isLoading = false;
  Map<String, double> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final financeService =
          Provider.of<FinanceService>(context, listen: false);
      final monthlyData = await financeService.getMonthlyOverview();

      setState(() {
        _monthlyData = monthlyData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading financial data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final financeService = Provider.of<FinanceService>(context);
    final loc = Provider.of<AppLocalizations>(context);
    final financeLoc = FinanceLocalizations(loc);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMonthSelector(context, financeService, financeLoc),
                    const SizedBox(height: 24),
                    _buildMonthlyOverview(context, financeLoc),
                    const SizedBox(height: 24),
                    _buildUpcomingDeadlines(
                        context, financeService, financeLoc),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context,
      FinanceService financeService, FinanceLocalizations financeLoc) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                final previousMonth = DateTime(
                  financeService.selectedMonth.year,
                  financeService.selectedMonth.month - 1,
                );
                financeService.changeMonth(previousMonth);
                _loadData();
              },
            ),
            GestureDetector(
              onTap: () => _showMonthPicker(context, financeService),
              child: Text(
                DateFormat('MMMM yyyy').format(financeService.selectedMonth),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () {
                final nextMonth = DateTime(
                  financeService.selectedMonth.year,
                  financeService.selectedMonth.month + 1,
                );
                financeService.changeMonth(nextMonth);
                _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyOverview(
      BuildContext context, FinanceLocalizations financeLoc) {
    final income = _monthlyData['income'] ?? 0.0;
    final expense = _monthlyData['expense'] ?? 0.0;
    final savings = _monthlyData['savings'] ?? 0.0;
    final debtPayments = _monthlyData['debtPayments'] ?? 0.0;
    final balance = income - expense - savings;

    final currencyFormat = NumberFormat.currency(symbol: '€');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              financeLoc.monthlyOverview,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildOverviewItem(
              context: context,
              icon: Icons.arrow_upward,
              title: financeLoc.totalIncome,
              amount: income,
              positive: true,
            ),
            const Divider(),
            _buildOverviewItem(
              context: context,
              icon: Icons.arrow_downward,
              title: financeLoc.totalExpenses,
              amount: expense,
              positive: false,
            ),
            const Divider(),
            _buildOverviewItem(
              context: context,
              icon: Icons.savings,
              title: financeLoc.savingsTotal,
              amount: savings,
              positive: false,
            ),
            const Divider(),
            _buildOverviewItem(
              context: context,
              icon: Icons.account_balance,
              title: financeLoc.debtPayments,
              amount: debtPayments,
              positive: false,
            ),
            const Divider(),
            _buildOverviewItem(
              context: context,
              icon: Icons.account_balance_wallet,
              title: financeLoc.balance,
              amount: balance,
              positive: balance >= 0,
              larger: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double amount,
    required bool positive,
    bool larger = false,
  }) {
    final currencyFormat = NumberFormat.currency(symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: positive ? Colors.green : Colors.red,
            size: larger ? 28 : 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: larger ? 16 : 14,
                fontWeight: larger ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: larger ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: positive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines(BuildContext context,
      FinanceService financeService, FinanceLocalizations financeLoc) {
    final deadlines = financeService.deadlines
        .where((d) => d.status != DeadlineStatus.completed)
        .toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              financeLoc.deadlines,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            deadlines.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(financeLoc.noDeadlines),
                    ),
                  )
                : Column(
                    children: deadlines
                        .take(5)
                        .map(
                          (deadline) =>
                              _buildDeadlineItem(deadline, context, financeLoc),
                        )
                        .toList(),
                  ),
            if (deadlines.length > 5)
              TextButton(
                onPressed: () {
                  // Wechsle zum Deadlines-Tab (Annahme: es ist der Index 3)
                  DefaultTabController.of(context)?.animateTo(3);
                },
                child: Text(
                  'Alle anzeigen (${deadlines.length})',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineItem(FinancialDeadline deadline, BuildContext context,
      FinanceLocalizations financeLoc) {
    final currencyFormat = NumberFormat.currency(symbol: '€');

    Color statusColor;
    String statusText;

    switch (deadline.status) {
      case DeadlineStatus.upcoming:
        statusColor = Colors.blue;
        statusText = financeLoc.upcoming;
        break;
      case DeadlineStatus.dueToday:
        statusColor = Colors.orange;
        statusText = financeLoc.dueToday;
        break;
      case DeadlineStatus.overdue:
        statusColor = Colors.red;
        statusText = financeLoc.overdue;
        break;
      case DeadlineStatus.completed:
        statusColor = Colors.green;
        statusText = financeLoc.completed;
        break;
      default:
        statusColor = Colors.grey;
        statusText = "Unknown";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deadline.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('dd.MM.yyyy').format(deadline.dueDate),
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFormat.format(deadline.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMonthPicker(
      BuildContext context, FinanceService financeService) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: financeService.selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      final selectedMonth = DateTime(picked.year, picked.month);
      financeService.changeMonth(selectedMonth);
      _loadData();
    }
  }
}
