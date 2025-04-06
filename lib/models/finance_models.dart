import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Enum for transaction types
enum TransactionType {
  income,
  expense,
  transfer,
  all, // Used for filtering
}

/// Enum for debt types
enum DebtType {
  youOwe,
  theyOwe,
  all, // Used for filtering
}

/// Enum for deadline status
enum DeadlineStatus {
  upcoming,
  dueToday,
  overdue,
  completed,
  all, // Used for filtering
}

/// Model class for a financial transaction
class Transaction {
  final String? id;
  final String title;
  final double amount;
  final String category;
  final String notes;
  final DateTime date;
  final TransactionType type;
  final int recurrenceType; // 0 = none, 1 = fixed

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    this.notes = '',
    required this.date,
    required this.type,
    this.recurrenceType = 0,
  });

  /// Convert transaction to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'notes': notes,
      'date': date.millisecondsSinceEpoch,
      'type': type.index,
      'recurrenceType': recurrenceType,
    };
  }

  /// Create transaction from JSON
  factory Transaction.fromJson(Map<String, dynamic> json) {
    // Datumsverarbeitung - verarbeite sowohl Timestamp als auch ISO-String
    DateTime parsedDate;
    if (json['date'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(json['date']);
    } else if (json['date'] is String) {
      try {
        parsedDate = DateTime.parse(json['date']);
      } catch (e) {
        // Fallback auf aktuelles Datum bei Parsing-Fehler
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    // RecurrenceType verarbeiten - verarbeite sowohl String als auch int
    int recurrenceTypeValue = 0;
    if (json['recurrenceType'] != null) {
      if (json['recurrenceType'] is int) {
        recurrenceTypeValue = json['recurrenceType'];
      } else if (json['recurrenceType'] is String) {
        recurrenceTypeValue =
            int.tryParse(json['recurrenceType'] as String) ?? 0;
      }
    }

    return Transaction(
      id: json['id'],
      title: json['title'],
      amount: json['amount'] is int
          ? (json['amount'] as int).toDouble()
          : json['amount'],
      category: json['category'] ?? '',
      notes: json['notes'] ?? '',
      date: parsedDate,
      type: TransactionType.values[
          json['type'] is String ? int.parse(json['type']) : json['type']],
      recurrenceType: recurrenceTypeValue,
    );
  }

  /// Create a copy with modified fields
  Transaction copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? notes,
    DateTime? date,
    TransactionType? type,
    int? recurrenceType,
  }) {
    return Transaction(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      type: type ?? this.type,
      recurrenceType: recurrenceType ?? this.recurrenceType,
    );
  }
}

/// Model class for a debt
class FinancialDebt {
  final String? id;
  final String title;
  final String person;
  final double amount;
  final double paidAmount;
  final String notes;
  final DateTime? dueDate;
  final DebtType type;

  FinancialDebt({
    String? id,
    required this.title,
    required this.person,
    required this.amount,
    this.paidAmount = 0.0,
    this.notes = '',
    this.dueDate,
    required this.type,
  }) : id = id ?? const Uuid().v4();

  /// Convert debt to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'person': person,
      'amount': amount,
      'paidAmount': paidAmount,
      'notes': notes,
      'dueDate': dueDate?.toIso8601String(),
      'type': type.index,
    };
  }

  /// Create debt from JSON
  factory FinancialDebt.fromJson(Map<String, dynamic> json) {
    return FinancialDebt(
      id: json['id'],
      title: json['title'],
      person: json['person'],
      amount: json['amount'],
      paidAmount: json['paidAmount'] ?? 0.0,
      notes: json['notes'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      type: DebtType.values[json['type']],
    );
  }

  /// Create a copy with modified fields
  FinancialDebt copyWith({
    String? id,
    String? title,
    String? person,
    double? amount,
    double? paidAmount,
    String? notes,
    DateTime? dueDate,
    bool clearDueDate = false,
    DebtType? type,
  }) {
    return FinancialDebt(
      id: id ?? this.id,
      title: title ?? this.title,
      person: person ?? this.person,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      notes: notes ?? this.notes,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      type: type ?? this.type,
    );
  }
}

/// Model class for a financial deadline
class FinancialDeadline {
  final String? id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String? notes;
  final DeadlineStatus status;

  FinancialDeadline({
    String? id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.notes,
    DeadlineStatus? status,
  })  : id = id ?? const Uuid().v4(),
        status = status ?? _calculateStatus(dueDate);

  /// Calculate the status based on due date
  static DeadlineStatus _calculateStatus(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (dueDay.isBefore(today)) {
      return DeadlineStatus.overdue;
    } else if (dueDay.isAtSameMomentAs(today)) {
      return DeadlineStatus.dueToday;
    } else {
      return DeadlineStatus.upcoming;
    }
  }

  /// Convert deadline to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'notes': notes,
      'status': status.index,
    };
  }

  /// Create deadline from JSON
  factory FinancialDeadline.fromJson(Map<String, dynamic> json) {
    return FinancialDeadline(
      id: json['id'],
      title: json['title'],
      amount: json['amount'],
      dueDate: DateTime.parse(json['dueDate']),
      notes: json['notes'],
      status: DeadlineStatus.values[json['status']],
    );
  }

  /// Create a copy with modified fields
  FinancialDeadline copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? notes,
    bool clearNotes = false,
    DeadlineStatus? status,
  }) {
    return FinancialDeadline(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      notes: clearNotes ? null : (notes ?? this.notes),
      status: status ?? this.status,
    );
  }
}

/// Model class for a savings goal
class SavingsGoal {
  final String? id;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;

  SavingsGoal({
    String? id,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
  }) : id = id ?? const Uuid().v4();

  /// Convert savings goal to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'targetDate': targetDate?.toIso8601String(),
    };
  }

  /// Create savings goal from JSON
  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      targetAmount: json['targetAmount'],
      currentAmount: json['currentAmount'] ?? 0.0,
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
    );
  }

  /// Create a copy with modified fields
  SavingsGoal copyWith({
    String? id,
    String? title,
    String? description,
    bool clearDescription = false,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: clearTargetDate ? null : (targetDate ?? this.targetDate),
    );
  }
}
