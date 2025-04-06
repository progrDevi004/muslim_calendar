import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/ui/pages/finance/finance_overview_page.dart';
import 'package:Taqvimi/ui/pages/finance/transactions_page.dart';
import 'package:Taqvimi/ui/pages/finance/debts_page.dart';
import 'package:Taqvimi/ui/pages/finance/deadlines_page.dart';
import 'package:Taqvimi/ui/pages/finance/savings_goals_page.dart';
import 'package:Taqvimi/ui/widgets/finance/transaction_dialog.dart';
// Die Dialog-Widgets werden später implementiert
// import 'package:Taqvimi/ui/widgets/finance/debt_dialog.dart';
// import 'package:Taqvimi/ui/widgets/finance/deadline_dialog.dart';
// import 'package:Taqvimi/ui/widgets/finance/savings_goal_dialog.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({Key? key}) : super(key: key);

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);

    // Daten beim Start laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FinanceService>(context, listen: false)
          .loadAllFinancialData();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = Provider.of<AppLocalizations>(context);
    final financeLoc = FinanceLocalizations(loc);
    final financeService = Provider.of<FinanceService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(financeLoc.finance),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: financeLoc.overview),
            Tab(text: financeLoc.transactions),
            Tab(text: financeLoc.debts),
            Tab(text: financeLoc.deadlines),
            Tab(text: financeLoc.savingsGoals),
          ],
        ),
        elevation: 0,
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FinanceOverviewPage(),
          TransactionsPage(),
          DebtsPage(),
          DeadlinesPage(),
          SavingsGoalsPage(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(financeLoc),
    );
  }

  Widget? _buildFloatingActionButton(FinanceLocalizations financeLoc) {
    switch (_tabController.index) {
      case 0: // Overview - now also showing a FAB for adding transactions
        return FloatingActionButton(
          onPressed: () => _showTransactionDialog(context),
          tooltip: financeLoc.addTransaction,
          child: const Icon(Icons.add),
        );
      case 1: // Transactions
        return FloatingActionButton(
          onPressed: () => _showTransactionDialog(context),
          tooltip: financeLoc.addTransaction,
          child: const Icon(Icons.add),
        );
      case 2: // Debts
        return FloatingActionButton(
          onPressed: () => _showDebtDialog(context),
          tooltip: financeLoc.addDebt,
          child: const Icon(Icons.add),
        );
      case 3: // Deadlines
        return FloatingActionButton(
          onPressed: () => _showDeadlineDialog(context),
          tooltip: financeLoc.addDeadline,
          child: const Icon(Icons.add),
        );
      case 4: // Savings Goals
        return FloatingActionButton(
          onPressed: () => _showSavingsGoalDialog(context),
          tooltip: financeLoc.addSavingsGoal,
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  void _showTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TransactionDialog(),
    );
  }

  void _showDebtDialog(BuildContext context) {
    // Vorübergehend deaktiviert, bis der DebtDialog implementiert ist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debt Dialog noch nicht implementiert'),
      ),
    );
    // showDialog(
    //   context: context,
    //   builder: (context) => const DebtDialog(),
    // );
  }

  void _showDeadlineDialog(BuildContext context) {
    // Vorübergehend deaktiviert, bis der DeadlineDialog implementiert ist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deadline Dialog noch nicht implementiert'),
      ),
    );
    // showDialog(
    //   context: context,
    //   builder: (context) => const DeadlineDialog(),
    // );
  }

  void _showSavingsGoalDialog(BuildContext context) {
    // Vorübergehend deaktiviert, bis der SavingsGoalDialog implementiert ist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Savings Goal Dialog noch nicht implementiert'),
      ),
    );
    // showDialog(
    //   context: context,
    //   builder: (context) => const SavingsGoalDialog(),
    // );
  }
}
