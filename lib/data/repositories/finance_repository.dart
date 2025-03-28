import 'package:sqflite/sqflite.dart';
import 'package:Taqvimi/data/database_helper.dart';
import 'package:Taqvimi/models/finance_models.dart' as models;

// Zusätzliche Enums für die Repository-Funktionalität
enum RecurrenceType { none, fixed, all }

enum DebtStatus { outstanding, partiallyPaid, fullyPaid }

class DebtPayment {
  final String id;
  final String debtId;
  final double amount;
  final DateTime date;
  final String? note;

  DebtPayment({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.date,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'debtId': debtId,
      'amount': amount,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  factory DebtPayment.fromMap(Map<String, dynamic> map) {
    return DebtPayment(
      id: map['id'],
      debtId: map['debtId'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      note: map['note'],
    );
  }
}

class Debt {
  final String id;
  final String title;
  final double totalAmount;
  final double paidAmount;
  final List<DebtPayment> payments;

  Debt({
    required this.id,
    required this.title,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.payments = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
    };
  }

  factory Debt.fromMap(Map<String, dynamic> map) {
    return Debt(
      id: map['id'],
      title: map['title'],
      totalAmount: map['totalAmount'],
      paidAmount: map['paidAmount'] ?? 0.0,
    );
  }
}

class SavingsGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
    };
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      title: map['title'],
      targetAmount: map['targetAmount'],
      currentAmount: map['currentAmount'] ?? 0.0,
    );
  }
}

class FinanceRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // Tabellennamen
  static const String transactionTable = 'financial_transactions';
  static const String debtTable = 'debts';
  static const String debtPaymentTable = 'debt_payments';
  static const String deadlineTable = 'financial_deadlines';
  static const String savingsTable = 'savings_goals';

  // Initialisiere Tabellen
  Future<void> initTables(Database db) async {
    // Transaktionen
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $transactionTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type INTEGER NOT NULL,
        recurrenceType INTEGER NOT NULL,
        category TEXT,
        categoryColor INTEGER
      )
    ''');

    // Schulden
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $debtTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL DEFAULT 0.0,
        creationDate TEXT NOT NULL,
        dueDate TEXT,
        status INTEGER NOT NULL
      )
    ''');

    // Schuldenzahlungen
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $debtPaymentTable (
        id TEXT PRIMARY KEY,
        debtId TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (debtId) REFERENCES $debtTable (id) ON DELETE CASCADE
      )
    ''');

    // Fristen
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $deadlineTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT NOT NULL,
        amount REAL NOT NULL,
        status INTEGER NOT NULL,
        reminderEnabled INTEGER NOT NULL DEFAULT 1,
        completedDate TEXT
      )
    ''');

    // Sparziele
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $savingsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        monthlyAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0.0,
        targetAmount REAL,
        creationDate TEXT NOT NULL,
        targetDate TEXT
      )
    ''');
  }

  // Transaktionsmethoden
  Future<List<models.Transaction>> getTransactions(
      {DateTime? startDate, DateTime? endDate}) async {
    final db = await _databaseHelper.database;
    String query = 'SELECT * FROM $transactionTable';
    List<Object?> args = [];

    if (startDate != null || endDate != null) {
      query += ' WHERE';
      if (startDate != null) {
        query += ' date >= ?';
        args.add(startDate.toIso8601String());
      }
      if (endDate != null) {
        if (startDate != null) query += ' AND';
        query += ' date <= ?';
        args.add(endDate.toIso8601String());
      }
    }

    query += ' ORDER BY date DESC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);
    return List.generate(maps.length, (i) {
      return models.Transaction.fromJson(maps[i]);
    });
  }

  Future<List<models.Transaction>> getFixedTransactions() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      transactionTable,
      where: 'recurrenceType = ?',
      whereArgs: [RecurrenceType.fixed.index],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return models.Transaction.fromJson(maps[i]);
    });
  }

  Future<void> addTransaction(models.Transaction transaction) async {
    final db = await _databaseHelper.database;
    await db.insert(
      transactionTable,
      transaction.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTransaction(models.Transaction transaction) async {
    final db = await _databaseHelper.database;
    await db.update(
      transactionTable,
      transaction.toJson(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      transactionTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Schuldenmethoden
  Future<List<Debt>> getDebts() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      debtTable,
      orderBy: 'creationDate DESC',
    );

    List<Debt> debts = [];
    for (var map in maps) {
      Debt debt = Debt.fromMap(map);
      // Zahlungen laden
      debt.payments.addAll(await getDebtPayments(debt.id));
      debts.add(debt);
    }

    return debts;
  }

  Future<List<DebtPayment>> getDebtPayments(String debtId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      debtPaymentTable,
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) {
      return DebtPayment.fromMap(maps[i]);
    });
  }

  Future<void> addDebt(Debt debt) async {
    final db = await _databaseHelper.database;
    await db.insert(
      debtTable,
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDebt(Debt debt) async {
    final db = await _databaseHelper.database;
    await db.update(
      debtTable,
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  Future<void> deleteDebt(String id) async {
    final db = await _databaseHelper.database;
    // Zuerst alle Zahlungen löschen
    await db.delete(
      debtPaymentTable,
      where: 'debtId = ?',
      whereArgs: [id],
    );
    // Dann die Schuld löschen
    await db.delete(
      debtTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addDebtPayment(DebtPayment payment) async {
    final db = await _databaseHelper.database;

    // Zahlungsbetrag zur Gesamtzahlung hinzufügen
    Debt? debt;
    final debtMaps = await db.query(
      debtTable,
      where: 'id = ?',
      whereArgs: [payment.debtId],
    );

    if (debtMaps.isNotEmpty) {
      debt = Debt.fromMap(debtMaps.first);
      final newPaidAmount = debt.paidAmount + payment.amount;

      // Status aktualisieren
      DebtStatus newStatus = DebtStatus.outstanding;
      if (newPaidAmount >= debt.totalAmount) {
        newStatus = DebtStatus.fullyPaid;
      } else if (newPaidAmount > 0) {
        newStatus = DebtStatus.partiallyPaid;
      }

      // Schuld aktualisieren
      await db.update(
        debtTable,
        {
          'paidAmount': newPaidAmount,
          'status': newStatus.index,
        },
        where: 'id = ?',
        whereArgs: [payment.debtId],
      );
    }

    // Zahlung speichern
    await db.insert(
      debtPaymentTable,
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Fristenmethoden
  Future<List<models.FinancialDeadline>> getDeadlines(
      {bool includeCompleted = false}) async {
    final db = await _databaseHelper.database;
    String query = 'SELECT * FROM $deadlineTable';

    if (!includeCompleted) {
      query += ' WHERE status != ${models.DeadlineStatus.completed.index}';
    }

    query += ' ORDER BY dueDate ASC';

    final List<Map<String, dynamic>> maps = await db.rawQuery(query);
    return List.generate(maps.length, (i) {
      return models.FinancialDeadline.fromJson(maps[i]);
    });
  }

  Future<void> addDeadline(models.FinancialDeadline deadline) async {
    final db = await _databaseHelper.database;
    await db.insert(
      deadlineTable,
      deadline.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateDeadline(models.FinancialDeadline deadline) async {
    final db = await _databaseHelper.database;
    await db.update(
      deadlineTable,
      deadline.toJson(),
      where: 'id = ?',
      whereArgs: [deadline.id],
    );
  }

  Future<void> deleteDeadline(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      deadlineTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sparzielmethoden
  Future<List<SavingsGoal>> getSavingsGoals() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      savingsTable,
      orderBy: 'creationDate DESC',
    );
    return List.generate(maps.length, (i) {
      return SavingsGoal.fromMap(maps[i]);
    });
  }

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    final db = await _databaseHelper.database;
    await db.insert(
      savingsTable,
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    final db = await _databaseHelper.database;
    await db.update(
      savingsTable,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<void> deleteSavingsGoal(String id) async {
    final db = await _databaseHelper.database;
    await db.delete(
      savingsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Monatliche Übersicht
  Future<Map<String, double>> getMonthlyOverview(DateTime month) async {
    final db = await _databaseHelper.database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    // Einnahmen
    final incomeResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM $transactionTable 
      WHERE type = ? AND date BETWEEN ? AND ?
      ''', [
      models.TransactionType.income.index,
      startDate.toIso8601String(),
      endDate.toIso8601String()
    ]);

    // Ausgaben
    final expenseResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM $transactionTable 
      WHERE type = ? AND date BETWEEN ? AND ?
      ''', [
      models.TransactionType.expense.index,
      startDate.toIso8601String(),
      endDate.toIso8601String()
    ]);

    // Sparziele
    final savingsResult = await db.rawQuery('''
      SELECT SUM(monthlyAmount) as total FROM $savingsTable
      ''');

    // Schulden
    final debtPaymentsResult = await db.rawQuery('''
      SELECT SUM(amount) as total FROM $debtPaymentTable 
      WHERE date BETWEEN ? AND ?
      ''', [startDate.toIso8601String(), endDate.toIso8601String()]);

    return {
      'income': incomeResult.first['total'] as double? ?? 0.0,
      'expense': expenseResult.first['total'] as double? ?? 0.0,
      'savings': savingsResult.first['total'] as double? ?? 0.0,
      'debtPayments': debtPaymentsResult.first['total'] as double? ?? 0.0,
    };
  }
}
