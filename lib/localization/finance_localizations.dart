import 'package:Taqvimi/localization/app_localizations.dart';

/// Helper class to provide localization for the finance module
class FinanceLocalizations {
  final AppLocalizations _appLocalizations;

  FinanceLocalizations(this._appLocalizations);

  // General
  String get finance => _getLocalizedText('Finanzen', 'Finances', 'Maliyyə');
  String get save => _getLocalizedText('Speichern', 'Save', 'Yadda saxla');
  String get cancel => _getLocalizedText('Abbrechen', 'Cancel', 'Ləğv et');
  String get delete => _getLocalizedText('Löschen', 'Delete', 'Sil');
  String get edit => _getLocalizedText('Bearbeiten', 'Edit', 'Redaktə et');
  String get title => _getLocalizedText('Titel', 'Title', 'Başlıq');
  String get amount => _getLocalizedText('Betrag', 'Amount', 'Məbləğ');
  String get date => _getLocalizedText('Datum', 'Date', 'Tarix');
  String get notes => _getLocalizedText('Notizen', 'Notes', 'Qeydlər');
  String get category =>
      _getLocalizedText('Kategorie', 'Category', 'Kateqoriya');
  String get requiredField =>
      _getLocalizedText('Pflichtfeld', 'Required field', 'Məcburi sahə');
  String get invalidNumberFormat => _getLocalizedText('Ungültiges Zahlenformat',
      'Invalid number format', 'Yanlış rəqəm formatı');
  String get amountGreaterThanZero => _getLocalizedText(
      'Betrag muss größer als 0 sein',
      'Amount must be greater than 0',
      'Məbləğ 0-dan böyük olmalıdır');

  // Finance Page
  String get overview => _getLocalizedText('Übersicht', 'Overview', 'İcmal');
  String get transactions =>
      _getLocalizedText('Transaktionen', 'Transactions', 'Əməliyyatlar');
  String get debts => _getLocalizedText('Schulden', 'Debts', 'Borclar');
  String get deadlines =>
      _getLocalizedText('Fristen', 'Deadlines', 'Son tarixlər');
  String get savingsGoals =>
      _getLocalizedText('Sparziele', 'Savings Goals', 'Yığım hədəfləri');

  // Overview Page
  String get monthlyOverview =>
      _getLocalizedText('Monatsübersicht', 'Monthly Overview', 'Aylıq icmal');
  String get totalIncome =>
      _getLocalizedText('Einnahmen gesamt', 'Total Income', 'Ümumi gəlir');
  String get totalExpenses =>
      _getLocalizedText('Ausgaben gesamt', 'Total Expenses', 'Ümumi xərc');
  String get savingsTotal =>
      _getLocalizedText('Erspartes gesamt', 'Total Savings', 'Ümumi yığım');
  String get debtPayments => _getLocalizedText(
      'Schuldenrückzahlungen', 'Debt Payments', 'Borc ödənişləri');
  String get balance => _getLocalizedText('Bilanz', 'Balance', 'Balans');

  // Transaction
  String get income => _getLocalizedText('Einkommen', 'Income', 'Gəlir');
  String get expense => _getLocalizedText('Ausgabe', 'Expense', 'Xərc');
  String get transfer =>
      _getLocalizedText('Überweisung', 'Transfer', 'Köçürmə');
  String get addTransaction => _getLocalizedText(
      'Transaktion hinzufügen', 'Add Transaction', 'Əməliyyat əlavə et');
  String get editTransaction => _getLocalizedText(
      'Transaktion bearbeiten', 'Edit Transaction', 'Əməliyyatı redaktə et');
  String get noTransactions => _getLocalizedText(
      'Keine Transaktionen', 'No Transactions', 'Əməliyyat yoxdur');
  String get transactionType => _getLocalizedText(
      'Transaktionstyp', 'Transaction Type', 'Əməliyyat növü');
  String get searchTransactions => _getLocalizedText(
      'Transaktionen durchsuchen',
      'Search Transactions',
      'Əməliyyatları axtar');
  String get allTransactions => _getLocalizedText(
      'Alle Transaktionen', 'All Transactions', 'Bütün əməliyyatlar');

  // Debt
  String get debt => _getLocalizedText('Schuld', 'Debt', 'Borc');
  String get addDebt =>
      _getLocalizedText('Schuld hinzufügen', 'Add Debt', 'Borc əlavə et');
  String get editDebt =>
      _getLocalizedText('Schuld bearbeiten', 'Edit Debt', 'Borcu redaktə et');
  String get noDebts =>
      _getLocalizedText('Keine Schulden', 'No Debts', 'Borc yoxdur');
  String get person => _getLocalizedText('Person', 'Person', 'Şəxs');
  String get paidAmount =>
      _getLocalizedText('Bezahlter Betrag', 'Paid Amount', 'Ödənilmiş məbləğ');
  String get remaining =>
      _getLocalizedText('Verbleibend', 'Remaining', 'Qalan');
  String get paid => _getLocalizedText('Bezahlt', 'Paid', 'Ödənildi');
  String get youOwe =>
      _getLocalizedText('Du schuldest', 'You Owe', 'Siz borclusunuz');
  String get theyOwe =>
      _getLocalizedText('Dir geschuldet', 'They Owe', 'Sizə borcludurlar');
  String get dueDate =>
      _getLocalizedText('Fälligkeitsdatum', 'Due Date', 'Son tarix');
  String get searchDebts => _getLocalizedText(
      'Schulden durchsuchen', 'Search Debts', 'Borcları axtar');
  String get allDebts =>
      _getLocalizedText('Alle Schulden', 'All Debts', 'Bütün borclar');

  // Deadline
  String get deadline => _getLocalizedText('Frist', 'Deadline', 'Son tarix');
  String get addDeadline => _getLocalizedText(
      'Frist hinzufügen', 'Add Deadline', 'Son tarix əlavə et');
  String get editDeadline => _getLocalizedText(
      'Frist bearbeiten', 'Edit Deadline', 'Son tarixi redaktə et');
  String get noDeadlines =>
      _getLocalizedText('Keine Fristen', 'No Deadlines', 'Son tarix yoxdur');
  String get upcoming => _getLocalizedText('Anstehend', 'Upcoming', 'Gələcək');
  String get dueToday =>
      _getLocalizedText('Heute fällig', 'Due Today', 'Bu gün');
  String get overdue => _getLocalizedText('Überfällig', 'Overdue', 'Gecikmiş');
  String get completed =>
      _getLocalizedText('Abgeschlossen', 'Completed', 'Tamamlanmış');
  String get markAsCompleted => _getLocalizedText('Als abgeschlossen markieren',
      'Mark as Completed', 'Tamamlandı kimi qeyd et');
  String get searchDeadlines => _getLocalizedText(
      'Fristen durchsuchen', 'Search Deadlines', 'Son tarixləri axtar');
  String get allDeadlines =>
      _getLocalizedText('Alle Fristen', 'All Deadlines', 'Bütün son tarixlər');

  // Savings Goal
  String get savingsGoal =>
      _getLocalizedText('Sparziel', 'Savings Goal', 'Yığım hədəfi');
  String get addSavingsGoal => _getLocalizedText(
      'Sparziel hinzufügen', 'Add Savings Goal', 'Yığım hədəfi əlavə et');
  String get editSavingsGoal => _getLocalizedText(
      'Sparziel bearbeiten', 'Edit Savings Goal', 'Yığım hədəfini redaktə et');
  String get noSavingsGoals => _getLocalizedText(
      'Keine Sparziele', 'No Savings Goals', 'Yığım hədəfi yoxdur');
  String get targetAmount =>
      _getLocalizedText('Zielbetrag', 'Target Amount', 'Hədəf məbləğ');
  String get currentAmount =>
      _getLocalizedText('Aktueller Betrag', 'Current Amount', 'Cari məbləğ');
  String get targetDate =>
      _getLocalizedText('Zieldatum', 'Target Date', 'Hədəf tarix');
  String get progress =>
      _getLocalizedText('Fortschritt', 'Progress', 'İrəliləyiş');
  String get addToGoal => _getLocalizedText(
      'Zum Ziel hinzufügen', 'Add to Goal', 'Hədəfə əlavə et');
  String get description =>
      _getLocalizedText('Beschreibung', 'Description', 'Təsvir');
  String get searchSavingsGoals => _getLocalizedText('Sparziele durchsuchen',
      'Search Savings Goals', 'Yığım hədəflərini axtar');
  String get showCompletedGoals => _getLocalizedText(
      'Abgeschlossene Ziele anzeigen',
      'Show Completed Goals',
      'Tamamlanmış hədəfləri göstər');

  // Utility-Methode zur Sprachauswahl
  String _getLocalizedText(String german, String english, String azerbaijani) {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return german;
      case AppLanguage.english:
        return english;
      // Da wir nicht wissen, ob azerbaijani in den AppLanguage existiert,
      // verwenden wir den Default-Fall
      default:
        return english;
    }
  }
}
