import 'dart:convert';
import 'package:Taqvimi/data/repositories/finance_repository.dart' as repo;
import 'package:Taqvimi/models/finance_models.dart' as models;
import 'package:flutter/material.dart';
import 'package:Taqvimi/data/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FinanceService extends ChangeNotifier {
  final repo.FinanceRepository _repository = repo.FinanceRepository();
  final NotificationService _notificationService;

  // Storage keys
  static const _transactionsKey = 'finance_transactions';
  static const _debtsKey = 'finance_debts';
  static const _deadlinesKey = 'finance_deadlines';
  static const _savingsGoalsKey = 'finance_savings_goals';
  static const _selectedMonthKey = 'finance_selected_month';

  // Aktuelle Daten
  List<models.Transaction> _transactions = [];
  List<repo.Debt> _debts = [];
  List<models.FinancialDeadline> _deadlines = [];
  List<repo.SavingsGoal> _savingsGoals = [];
  DateTime _selectedMonth = DateTime.now();

  // Getter
  List<models.Transaction> get transactions => _transactions;
  List<repo.Debt> get debts => _debts;
  List<models.FinancialDeadline> get deadlines => _deadlines;
  List<repo.SavingsGoal> get savingsGoals => _savingsGoals;
  DateTime get selectedMonth => _selectedMonth;

  FinanceService(this._notificationService);

  // Initialization
  Future<void> init() async {
    await loadTransactionsForMonth();
    await loadDebts();
    await loadDeadlines();
    await loadSavingsGoals();
    await _loadSelectedMonth();

    // Update deadlines status
    _updateDeadlinesStatus();
  }

  // Monat ändern
  void changeMonth(DateTime month) {
    _selectedMonth = month;
    loadTransactionsForMonth();
    _saveSelectedMonth();
    notifyListeners();
  }

  // Lade Daten für den aktuellen Monat
  Future<void> loadTransactionsForMonth() async {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

    _transactions = await _repository.getTransactions(
      startDate: startOfMonth,
      endDate: endOfMonth,
    );

    // Feste Transaktionen hinzufügen
    final fixedTransactions = await _repository.getFixedTransactions();

    for (var fixed in fixedTransactions) {
      // Erstelle eine Kopie für den aktuellen Monat
      final monthlyTransaction = models.Transaction(
        title: fixed.title,
        amount: fixed.amount,
        category: fixed.category,
        notes: fixed.notes,
        date: DateTime(
          _selectedMonth.year,
          _selectedMonth.month,
          fixed.date.day >
                  DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day
              ? DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day
              : fixed.date.day,
        ),
        type: fixed.type,
      );

      // Nur hinzufügen, wenn nicht bereits vorhanden
      if (!_transactions.any((t) =>
          t.title == monthlyTransaction.title &&
          t.amount == monthlyTransaction.amount &&
          t.type == monthlyTransaction.type)) {
        _transactions.add(monthlyTransaction);
      }
    }

    notifyListeners();
  }

  // Lade alle anderen Finanzdaten
  Future<void> loadAllFinancialData() async {
    await loadTransactionsForMonth();
    await loadDebts();
    await loadDeadlines();
    await loadSavingsGoals();
    notifyListeners();
  }

  // Transaktionen verwalten
  Future<void> addTransaction(models.Transaction transaction) async {
    await _repository.addTransaction(transaction);
    await loadTransactionsForMonth();
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    await _repository.updateTransaction(transaction);
    await loadTransactionsForMonth();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactionsForMonth();
  }

  // Schulden verwalten
  Future<void> loadDebts() async {
    _debts = await _repository.getDebts();
    notifyListeners();
  }

  Future<void> addDebt(repo.Debt debt) async {
    await _repository.addDebt(debt);
    await loadDebts();
  }

  Future<void> updateDebt(repo.Debt debt) async {
    await _repository.updateDebt(debt);
    await loadDebts();
  }

  Future<void> deleteDebt(String id) async {
    await _repository.deleteDebt(id);
    await loadDebts();
  }

  Future<void> addDebtPayment(repo.DebtPayment payment) async {
    await _repository.addDebtPayment(payment);
    await loadDebts();
  }

  // Fristen verwalten
  Future<void> loadDeadlines() async {
    _deadlines = await _repository.getDeadlines();

    // Status für jede Frist aktualisieren
    for (int i = 0; i < _deadlines.length; i++) {
      // Statt calculateStatus() verwenden wir eine einfache Logik basierend auf dem Datum
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDate = DateTime(_deadlines[i].dueDate.year,
          _deadlines[i].dueDate.month, _deadlines[i].dueDate.day);

      models.DeadlineStatus updatedStatus;
      if (dueDate.isBefore(today)) {
        updatedStatus = models.DeadlineStatus.overdue;
      } else if (dueDate.isAtSameMomentAs(today)) {
        updatedStatus = models.DeadlineStatus.dueToday;
      } else {
        updatedStatus = models.DeadlineStatus.upcoming;
      }

      if (updatedStatus != _deadlines[i].status) {
        final updatedDeadline = models.FinancialDeadline(
          id: _deadlines[i].id,
          title: _deadlines[i].title,
          amount: _deadlines[i].amount,
          dueDate: _deadlines[i].dueDate,
          status: updatedStatus,
        );

        _deadlines[i] = updatedDeadline;
        await _repository.updateDeadline(updatedDeadline);

        // Benachrichtigungen für überfällige Zahlungen
        if (updatedStatus == models.DeadlineStatus.overdue) {
          _scheduleDeadlineNotification(updatedDeadline);
        }
      }
    }

    notifyListeners();
  }

  // Benachrichtigung planen
  Future<void> addDeadline(models.FinancialDeadline deadline) async {
    await _repository.addDeadline(deadline);

    // Benachrichtigung planen (ohne reminderEnabled-Check)
    _scheduleDeadlineNotification(deadline);

    await loadDeadlines();
  }

  Future<void> updateDeadline(models.FinancialDeadline deadline) async {
    await _repository.updateDeadline(deadline);
    await loadDeadlines();
  }

  Future<void> markDeadlineAsCompleted(String id) async {
    final deadline = _deadlines.firstWhere((d) => d.id == id);
    final updatedDeadline = models.FinancialDeadline(
      id: deadline.id,
      title: deadline.title,
      dueDate: deadline.dueDate,
      amount: deadline.amount,
      status: models.DeadlineStatus.completed,
    );

    await _repository.updateDeadline(updatedDeadline);
    await loadDeadlines();
  }

  Future<void> deleteDeadline(String id) async {
    await _repository.deleteDeadline(id);
    await loadDeadlines();
  }

  // Sparziele verwalten
  Future<void> loadSavingsGoals() async {
    _savingsGoals = await _repository.getSavingsGoals();
    notifyListeners();
  }

  Future<void> addSavingsGoal(repo.SavingsGoal goal) async {
    await _repository.addSavingsGoal(goal);
    await loadSavingsGoals();
  }

  Future<void> updateSavingsGoal(repo.SavingsGoal goal) async {
    await _repository.updateSavingsGoal(goal);
    await loadSavingsGoals();
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _repository.deleteSavingsGoal(id);
    await loadSavingsGoals();
  }

  // Benachrichtigungen planen
  void _scheduleDeadlineNotification(models.FinancialDeadline deadline) {
    final now = DateTime.now();

    // Nur für zukünftige oder heutige Fristen
    if (deadline.dueDate.isAfter(now) ||
        (deadline.dueDate.day == now.day &&
            deadline.dueDate.month == now.month &&
            deadline.dueDate.year == now.year)) {
      _notificationService.scheduleNotification(
        appointmentId: deadline.id.hashCode,
        title: 'Zahlungserinnerung',
        body: '${deadline.title} (${deadline.amount} €) ist heute fällig!',
        dateTime: DateTime(
          deadline.dueDate.year,
          deadline.dueDate.month,
          deadline.dueDate.day,
          9, 0, // 9 Uhr morgens
        ),
      );
    }
  }

  // Monatliche Übersicht abrufen
  Future<Map<String, double>> getMonthlyOverview() async {
    return await _repository.getMonthlyOverview(_selectedMonth);
  }

  // Load selected month
  Future<void> _loadSelectedMonth() async {
    final prefs = await SharedPreferences.getInstance();
    final monthStr = prefs.getString(_selectedMonthKey);

    if (monthStr != null) {
      try {
        _selectedMonth = DateTime.parse(monthStr);
      } catch (e) {
        // Use current month if parse fails
        _selectedMonth = DateTime(
          DateTime.now().year,
          DateTime.now().month,
        );
      }
    }
  }

  // Save selected month
  Future<void> _saveSelectedMonth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMonthKey, _selectedMonth.toIso8601String());
  }

  // Update deadlines status based on current date
  void _updateDeadlinesStatus() {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (var i = 0; i < _deadlines.length; i++) {
      final deadline = _deadlines[i];

      // Skip completed deadlines
      if (deadline.status == models.DeadlineStatus.completed) {
        continue;
      }

      final dueDate = DateTime(
        deadline.dueDate.year,
        deadline.dueDate.month,
        deadline.dueDate.day,
      );

      models.DeadlineStatus newStatus;

      if (dueDate.isBefore(todayDate)) {
        newStatus = models.DeadlineStatus.overdue;
      } else if (dueDate.isAtSameMomentAs(todayDate)) {
        newStatus = models.DeadlineStatus.dueToday;
      } else {
        newStatus = models.DeadlineStatus.upcoming;
      }

      if (newStatus != deadline.status) {
        _deadlines[i] = deadline.copyWith(status: newStatus);
      }
    }
  }
}
