import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:Taqvimi/data/services/finance_service.dart';
import 'package:Taqvimi/localization/app_localizations.dart';
import 'package:Taqvimi/localization/finance_localizations.dart';
import 'package:Taqvimi/models/finance_models.dart';

class DeadlinesPage extends StatefulWidget {
  const DeadlinesPage({Key? key}) : super(key: key);

  @override
  State<DeadlinesPage> createState() => _DeadlinesPageState();
}

class _DeadlinesPageState extends State<DeadlinesPage> {
  bool _isLoading = false;
  List<FinancialDeadline> _filteredDeadlines = [];
  String _searchQuery = '';
  DeadlineStatus _filterStatus = DeadlineStatus.all;

  @override
  void initState() {
    super.initState();
    _loadDeadlines();
  }

  Future<void> _loadDeadlines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final financeService =
          Provider.of<FinanceService>(context, listen: false);
      await financeService.loadDeadlines();
      _applyFilters();
    } catch (e) {
      print('Error loading deadlines: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    final financeService = Provider.of<FinanceService>(context, listen: false);
    List<FinancialDeadline> deadlines = List.from(financeService.deadlines);

    // Filter by status
    if (_filterStatus != DeadlineStatus.all) {
      deadlines = deadlines.where((d) => d.status == _filterStatus).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      deadlines = deadlines
          .where((d) =>
              d.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (d.notes?.toLowerCase() ?? '')
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by due date (closest first)
    deadlines.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    setState(() {
      _filteredDeadlines = deadlines;
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
                : _filteredDeadlines.isEmpty
                    ? Center(
                        child: Text(financeLoc.noDeadlines),
                      )
                    : ListView.separated(
                        itemCount: _filteredDeadlines.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final deadline = _filteredDeadlines[index];
                          return _buildDeadlineItem(
                              context, deadline, financeService, financeLoc);
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
              hintText: financeLoc.searchDeadlines,
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
                  label: financeLoc.allDeadlines,
                  selected: _filterStatus == DeadlineStatus.all,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = DeadlineStatus.all;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.upcoming,
                  selected: _filterStatus == DeadlineStatus.upcoming,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = DeadlineStatus.upcoming;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.dueToday,
                  selected: _filterStatus == DeadlineStatus.dueToday,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = DeadlineStatus.dueToday;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.overdue,
                  selected: _filterStatus == DeadlineStatus.overdue,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = DeadlineStatus.overdue;
                      });
                      _applyFilters();
                    }
                  },
                ),
                const SizedBox(width: 8.0),
                _buildFilterChip(
                  context: context,
                  label: financeLoc.completed,
                  selected: _filterStatus == DeadlineStatus.completed,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _filterStatus = DeadlineStatus.completed;
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

  Widget _buildDeadlineItem(BuildContext context, FinancialDeadline deadline,
      FinanceService financeService, FinanceLocalizations financeLoc) {
    final currencyFormat = NumberFormat.currency(symbol: '€');

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (deadline.status) {
      case DeadlineStatus.upcoming:
        statusColor = Colors.blue;
        statusText = financeLoc.upcoming;
        statusIcon = Icons.access_time;
        break;
      case DeadlineStatus.dueToday:
        statusColor = Colors.orange;
        statusText = financeLoc.dueToday;
        statusIcon = Icons.today;
        break;
      case DeadlineStatus.overdue:
        statusColor = Colors.red;
        statusText = financeLoc.overdue;
        statusIcon = Icons.warning;
        break;
      case DeadlineStatus.completed:
        statusColor = Colors.green;
        statusText = financeLoc.completed;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = "Unknown";
        statusIcon = Icons.help_outline;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.2),
        child: Icon(
          statusIcon,
          color: statusColor,
        ),
      ),
      title: Text(
        deadline.title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          decoration: deadline.status == DeadlineStatus.completed
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('dd.MM.yyyy').format(deadline.dueDate),
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6.0,
              vertical: 2.0,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 10,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
      trailing: Text(
        currencyFormat.format(deadline.amount),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: deadline.status == DeadlineStatus.completed
              ? Colors.grey
              : statusColor,
          decoration: deadline.status == DeadlineStatus.completed
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
      onTap: () => _showDeadlineDialog(context, financeService, financeLoc,
          deadline: deadline),
    );
  }

  void _showDeadlineDialog(BuildContext context, FinanceService financeService,
      FinanceLocalizations financeLoc,
      {FinancialDeadline? deadline}) async {
    // Vorübergehend deaktiviert, bis der DeadlineDialog implementiert ist
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deadline Dialog noch nicht implementiert'),
      ),
    );
    /* Auskommentiert bis DeadlineDialog implementiert ist
    await showDialog(
      context: context,
      builder: (context) => DeadlineDialog(
        deadline: deadline,
      ),
    );
    */

    // Reload deadlines after dialog is closed
    _loadDeadlines();
  }
}
