import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart' as models;
import 'package:Taqvimi/data/repositories/finance_repository.dart' as repo;

class SavingsGoalsPage extends StatefulWidget {
  const SavingsGoalsPage({Key? key}) : super(key: key);

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  bool _isLoading = false;
  List<repo.SavingsGoal> _filteredGoals = [];
  String _searchQuery = '';
  bool _showCompletedGoals = true;

  @override
  void initState() {
    super.initState();
    _loadSavingsGoals();
  }

  Future<void> _loadSavingsGoals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final financeService =
          Provider.of<FinanceService>(context, listen: false);
      await financeService.loadSavingsGoals();
      _applyFilters();
    } catch (e) {
      print('Error loading savings goals: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    List<repo.SavingsGoal> goals = List.from(financeService.savingsGoals);

    // Filter by completion status
    if (!_showCompletedGoals) {
      goals = goals.where((g) => g.currentAmount < g.targetAmount).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      goals = goals
          .where(
              (g) => g.title.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by progress (least complete first)
    goals.sort((a, b) {
      double aProgress = a.currentAmount / a.targetAmount;
      double bProgress = b.currentAmount / b.targetAmount;
      return aProgress.compareTo(bProgress);
    });

    setState(() {
      _filteredGoals = goals;
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
                : _filteredGoals.isEmpty
                    ? Center(
                        child: Text(financeLoc.noSavingsGoals),
                      )
                    : ListView.builder(
                        itemCount: _filteredGoals.length,
                        padding: const EdgeInsets.all(16.0),
                        itemBuilder: (context, index) {
                          final goal = _filteredGoals[index];
                          return _buildSavingsGoalCard(
                              context, goal, financeService, financeLoc);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _showSavingsGoalDialog(context, financeService, financeLoc),
        tooltip: financeLoc.addSavingsGoal,
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
              hintText: financeLoc.searchSavingsGoals,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(
                child: FilterChip(
                  label: Text(financeLoc.showCompletedGoals),
                  selected: _showCompletedGoals,
                  onSelected: (selected) {
                    setState(() {
                      _showCompletedGoals = selected;
                    });
                    _applyFilters();
                  },
                  selectedColor:
                      Theme.of(context).primaryColor.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsGoalCard(BuildContext context, repo.SavingsGoal goal,
      FinanceService financeService, FinanceLocalizations financeLoc) {
    final currencyFormat = NumberFormat.currency(symbol: '€');
    final progress = goal.currentAmount / goal.targetAmount;
    final isCompleted = progress >= 1.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSavingsGoalDialog(context, financeService, financeLoc,
            goal: goal),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.withOpacity(0.1)
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      isCompleted
                          ? financeLoc.completed
                          : "${(progress * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 12,
                        color: isCompleted
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              LinearPercentIndicator(
                lineHeight: 10.0,
                percent: progress > 1.0 ? 1.0 : progress,
                backgroundColor: Colors.grey.withOpacity(0.2),
                progressColor:
                    isCompleted ? Colors.green : Theme.of(context).primaryColor,
                barRadius: const Radius.circular(8.0),
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(goal.currentAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  Text(
                    currencyFormat.format(goal.targetAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSavingsGoalDialog(BuildContext context,
      FinanceService financeService, FinanceLocalizations financeLoc,
      {repo.SavingsGoal? goal}) async {
    // Vorübergehende Lösung: Zeige eine Benachrichtigung statt eines nicht implementierten Dialogs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Savings Goal Dialog noch nicht implementiert'),
      ),
    );

    // Reload savings goals after dialog is closed
    _loadSavingsGoals();
  }
}
