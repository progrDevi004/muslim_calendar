import 'package:Taqvimi/localization/app_localizations.dart';

/// Helper class to provide localization for the finance module
class FinanceLocalizations {
  final AppLocalizations _appLocalizations;

  FinanceLocalizations(this._appLocalizations);

  // General
  String get finance {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Finanzen';
      case AppLanguage.turkish:
        return 'Finans';
      case AppLanguage.arabic:
        return 'المالية';
      case AppLanguage.bosnian:
        return 'Finansije';
      case AppLanguage.spanish:
        return 'Finanzas';
      case AppLanguage.persian:
        return 'امور مالی';
      case AppLanguage.english:
      default:
        return 'Finances';
    }
  }

  String get save {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Speichern';
      case AppLanguage.turkish:
        return 'Kaydet';
      case AppLanguage.arabic:
        return 'حفظ';
      case AppLanguage.bosnian:
        return 'Sačuvaj';
      case AppLanguage.spanish:
        return 'Guardar';
      case AppLanguage.persian:
        return 'ذخیره';
      case AppLanguage.english:
      default:
        return 'Save';
    }
  }

  String get cancel {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Abbrechen';
      case AppLanguage.turkish:
        return 'İptal';
      case AppLanguage.arabic:
        return 'إلغاء';
      case AppLanguage.bosnian:
        return 'Otkaži';
      case AppLanguage.spanish:
        return 'Cancelar';
      case AppLanguage.persian:
        return 'لغو';
      case AppLanguage.english:
      default:
        return 'Cancel';
    }
  }

  String get delete {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Löschen';
      case AppLanguage.turkish:
        return 'Sil';
      case AppLanguage.arabic:
        return 'حذف';
      case AppLanguage.bosnian:
        return 'Izbriši';
      case AppLanguage.spanish:
        return 'Eliminar';
      case AppLanguage.persian:
        return 'حذف';
      case AppLanguage.english:
      default:
        return 'Delete';
    }
  }

  String get edit {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Bearbeiten';
      case AppLanguage.turkish:
        return 'Düzenle';
      case AppLanguage.arabic:
        return 'تعديل';
      case AppLanguage.bosnian:
        return 'Uredi';
      case AppLanguage.spanish:
        return 'Editar';
      case AppLanguage.persian:
        return 'ویرایش';
      case AppLanguage.english:
      default:
        return 'Edit';
    }
  }

  String get title {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Titel';
      case AppLanguage.turkish:
        return 'Başlık';
      case AppLanguage.arabic:
        return 'العنوان';
      case AppLanguage.bosnian:
        return 'Naslov';
      case AppLanguage.spanish:
        return 'Título';
      case AppLanguage.persian:
        return 'عنوان';
      case AppLanguage.english:
      default:
        return 'Title';
    }
  }

  String get amount {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Betrag';
      case AppLanguage.turkish:
        return 'Miktar';
      case AppLanguage.arabic:
        return 'المبلغ';
      case AppLanguage.bosnian:
        return 'Iznos';
      case AppLanguage.spanish:
        return 'Cantidad';
      case AppLanguage.persian:
        return 'مقدار';
      case AppLanguage.english:
      default:
        return 'Amount';
    }
  }

  String get date {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Datum';
      case AppLanguage.turkish:
        return 'Tarih';
      case AppLanguage.arabic:
        return 'التاريخ';
      case AppLanguage.bosnian:
        return 'Datum';
      case AppLanguage.spanish:
        return 'Fecha';
      case AppLanguage.persian:
        return 'تاریخ';
      case AppLanguage.english:
      default:
        return 'Date';
    }
  }

  String get notes {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Notizen';
      case AppLanguage.turkish:
        return 'Notlar';
      case AppLanguage.arabic:
        return 'ملاحظات';
      case AppLanguage.bosnian:
        return 'Bilješke';
      case AppLanguage.spanish:
        return 'Notas';
      case AppLanguage.persian:
        return 'یادداشت‌ها';
      case AppLanguage.english:
      default:
        return 'Notes';
    }
  }

  String get category {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Kategorie';
      case AppLanguage.turkish:
        return 'Kategori';
      case AppLanguage.arabic:
        return 'الفئة';
      case AppLanguage.bosnian:
        return 'Kategorija';
      case AppLanguage.spanish:
        return 'Categoría';
      case AppLanguage.persian:
        return 'دسته‌بندی';
      case AppLanguage.english:
      default:
        return 'Category';
    }
  }

  String get requiredField {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Pflichtfeld';
      case AppLanguage.turkish:
        return 'Zorunlu alan';
      case AppLanguage.arabic:
        return 'حقل مطلوب';
      case AppLanguage.bosnian:
        return 'Obavezno polje';
      case AppLanguage.spanish:
        return 'Campo obligatorio';
      case AppLanguage.persian:
        return 'فیلد ضروری';
      case AppLanguage.english:
      default:
        return 'Required field';
    }
  }

  String get invalidNumberFormat {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Ungültiges Zahlenformat';
      case AppLanguage.turkish:
        return 'Geçersiz sayı formatı';
      case AppLanguage.arabic:
        return 'تنسيق رقم غير صالح';
      case AppLanguage.bosnian:
        return 'Nevažeći format broja';
      case AppLanguage.spanish:
        return 'Formato de número inválido';
      case AppLanguage.persian:
        return 'قالب عدد نامعتبر';
      case AppLanguage.english:
      default:
        return 'Invalid number format';
    }
  }

  String get amountGreaterThanZero {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Betrag muss größer als 0 sein';
      case AppLanguage.turkish:
        return 'Miktar 0\'dan büyük olmalıdır';
      case AppLanguage.arabic:
        return 'يجب أن يكون المبلغ أكبر من 0';
      case AppLanguage.bosnian:
        return 'Iznos mora biti veći od 0';
      case AppLanguage.spanish:
        return 'La cantidad debe ser mayor que 0';
      case AppLanguage.persian:
        return 'مقدار باید بیشتر از 0 باشد';
      case AppLanguage.english:
      default:
        return 'Amount must be greater than 0';
    }
  }

  // Finance Page
  String get overview {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Übersicht';
      case AppLanguage.turkish:
        return 'İcmal';
      case AppLanguage.arabic:
        return 'نظرة عامة';
      case AppLanguage.bosnian:
        return 'Pregled';
      case AppLanguage.spanish:
        return 'Resumen';
      case AppLanguage.persian:
        return 'نمای کلی';
      case AppLanguage.english:
      default:
        return 'Overview';
    }
  }

  String get transactions {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Transaktionen';
      case AppLanguage.turkish:
        return 'Əməliyyatlar';
      case AppLanguage.arabic:
        return 'المعاملات';
      case AppLanguage.bosnian:
        return 'Transakcije';
      case AppLanguage.spanish:
        return 'Transacciones';
      case AppLanguage.persian:
        return 'تراکنش‌ها';
      case AppLanguage.english:
      default:
        return 'Transactions';
    }
  }

  String get debts {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Schulden';
      case AppLanguage.turkish:
        return 'Borclar';
      case AppLanguage.arabic:
        return 'الديون';
      case AppLanguage.bosnian:
        return 'Dugovi';
      case AppLanguage.spanish:
        return 'Deudas';
      case AppLanguage.persian:
        return 'بدهی‌ها';
      case AppLanguage.english:
      default:
        return 'Debts';
    }
  }

  String get deadlines {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Fristen';
      case AppLanguage.turkish:
        return 'Son tarixlər';
      case AppLanguage.arabic:
        return 'المواعيد النهائية';
      case AppLanguage.bosnian:
        return 'Rokovi';
      case AppLanguage.spanish:
        return 'Fechas límite';
      case AppLanguage.persian:
        return 'مهلت‌ها';
      case AppLanguage.english:
      default:
        return 'Deadlines';
    }
  }

  String get savingsGoals {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Sparziele';
      case AppLanguage.turkish:
        return 'Yığım hədəfləri';
      case AppLanguage.arabic:
        return 'أهداف التوفير';
      case AppLanguage.bosnian:
        return 'Ciljevi štednje';
      case AppLanguage.spanish:
        return 'Objetivos de ahorro';
      case AppLanguage.persian:
        return 'اهداف پس‌انداز';
      case AppLanguage.english:
      default:
        return 'Savings Goals';
    }
  }

  // Overview Page
  String get monthlyOverview {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Monatsübersicht';
      case AppLanguage.turkish:
        return 'Aylıq icmal';
      case AppLanguage.arabic:
        return 'النظرة العامة الشهرية';
      case AppLanguage.bosnian:
        return 'Mjesečni pregled';
      case AppLanguage.spanish:
        return 'Resumen mensual';
      case AppLanguage.persian:
        return 'نمای کلی ماهانه';
      case AppLanguage.english:
      default:
        return 'Monthly Overview';
    }
  }

  String get totalIncome {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Einnahmen gesamt';
      case AppLanguage.turkish:
        return 'Ümumi gəlir';
      case AppLanguage.arabic:
        return 'إجمالي الدخل';
      case AppLanguage.bosnian:
        return 'Ukupni prihod';
      case AppLanguage.spanish:
        return 'Ingresos totales';
      case AppLanguage.persian:
        return 'درآمد کل';
      case AppLanguage.english:
      default:
        return 'Total Income';
    }
  }

  String get totalExpenses {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Ausgaben gesamt';
      case AppLanguage.turkish:
        return 'Ümumi xərc';
      case AppLanguage.arabic:
        return 'إجمالي المصروفات';
      case AppLanguage.bosnian:
        return 'Ukupni troškovi';
      case AppLanguage.spanish:
        return 'Gastos totales';
      case AppLanguage.persian:
        return 'هزینه کل';
      case AppLanguage.english:
      default:
        return 'Total Expenses';
    }
  }

  String get savingsTotal {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Erspartes gesamt';
      case AppLanguage.turkish:
        return 'Ümumi yığım';
      case AppLanguage.arabic:
        return 'إجمالي المدخرات';
      case AppLanguage.bosnian:
        return 'Ukupna ušteđevina';
      case AppLanguage.spanish:
        return 'Ahorros totales';
      case AppLanguage.persian:
        return 'کل پس‌انداز';
      case AppLanguage.english:
      default:
        return 'Total Savings';
    }
  }

  String get debtPayments {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Schuldenrückzahlungen';
      case AppLanguage.turkish:
        return 'Borc ödənişləri';
      case AppLanguage.arabic:
        return 'مدفوعات الديون';
      case AppLanguage.bosnian:
        return 'Otplate dugova';
      case AppLanguage.spanish:
        return 'Pagos de deudas';
      case AppLanguage.persian:
        return 'پرداخت‌های بدهی';
      case AppLanguage.english:
      default:
        return 'Debt Payments';
    }
  }

  String get balance {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Bilanz';
      case AppLanguage.turkish:
        return 'Balans';
      case AppLanguage.arabic:
        return 'الرصيد';
      case AppLanguage.bosnian:
        return 'Stanje';
      case AppLanguage.spanish:
        return 'Balance';
      case AppLanguage.persian:
        return 'تراز';
      case AppLanguage.english:
      default:
        return 'Balance';
    }
  }

  // Transaction
  String get income {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Einkommen';
      case AppLanguage.turkish:
        return 'Gəlir';
      case AppLanguage.arabic:
        return 'الدخل';
      case AppLanguage.bosnian:
        return 'Prihod';
      case AppLanguage.spanish:
        return 'Ingreso';
      case AppLanguage.persian:
        return 'درآمد';
      case AppLanguage.english:
      default:
        return 'Income';
    }
  }

  String get expense {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Ausgabe';
      case AppLanguage.turkish:
        return 'Xərc';
      case AppLanguage.arabic:
        return 'المصروفات';
      case AppLanguage.bosnian:
        return 'Trošak';
      case AppLanguage.spanish:
        return 'Gasto';
      case AppLanguage.persian:
        return 'هزینه';
      case AppLanguage.english:
      default:
        return 'Expense';
    }
  }

  String get transfer {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Überweisung';
      case AppLanguage.turkish:
        return 'Köçürmə';
      case AppLanguage.arabic:
        return 'تحويل';
      case AppLanguage.bosnian:
        return 'Transfer';
      case AppLanguage.spanish:
        return 'Transferencia';
      case AppLanguage.persian:
        return 'انتقال';
      case AppLanguage.english:
      default:
        return 'Transfer';
    }
  }

  String get addTransaction {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Transaktion hinzufügen';
      case AppLanguage.turkish:
        return 'Əməliyyat əlavə et';
      case AppLanguage.arabic:
        return 'إضافة معاملة';
      case AppLanguage.bosnian:
        return 'Dodaj transakciju';
      case AppLanguage.spanish:
        return 'Añadir transacción';
      case AppLanguage.persian:
        return 'افزودن تراکنش';
      case AppLanguage.english:
      default:
        return 'Add Transaction';
    }
  }

  String get editTransaction {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Transaktion bearbeiten';
      case AppLanguage.turkish:
        return 'Əməliyyatı redaktə et';
      case AppLanguage.arabic:
        return 'تعديل المعاملة';
      case AppLanguage.bosnian:
        return 'Uredi transakciju';
      case AppLanguage.spanish:
        return 'Editar transacción';
      case AppLanguage.persian:
        return 'ویرایش تراکنش';
      case AppLanguage.english:
      default:
        return 'Edit Transaction';
    }
  }

  String get noTransactions {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Keine Transaktionen';
      case AppLanguage.turkish:
        return 'Əməliyyat yoxdur';
      case AppLanguage.arabic:
        return 'لا توجد معاملات';
      case AppLanguage.bosnian:
        return 'Nema transakcija';
      case AppLanguage.spanish:
        return 'Sin transacciones';
      case AppLanguage.persian:
        return 'تراکنشی موجود نیست';
      case AppLanguage.english:
      default:
        return 'No Transactions';
    }
  }

  String get transactionType {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Transaktionstyp';
      case AppLanguage.turkish:
        return 'Əməliyyat növü';
      case AppLanguage.arabic:
        return 'نوع المعاملة';
      case AppLanguage.bosnian:
        return 'Tip transakcije';
      case AppLanguage.spanish:
        return 'Tipo de transacción';
      case AppLanguage.persian:
        return 'نوع تراکنش';
      case AppLanguage.english:
      default:
        return 'Transaction Type';
    }
  }

  String get searchTransactions {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Transaktionen durchsuchen';
      case AppLanguage.turkish:
        return 'Əməliyyatları axtar';
      case AppLanguage.arabic:
        return 'البحث في المعاملات';
      case AppLanguage.bosnian:
        return 'Pretraži transakcije';
      case AppLanguage.spanish:
        return 'Buscar transacciones';
      case AppLanguage.persian:
        return 'جستجوی تراکنش‌ها';
      case AppLanguage.english:
      default:
        return 'Search Transactions';
    }
  }

  String get allTransactions {
    switch (_appLocalizations.currentLanguage) {
      case AppLanguage.german:
        return 'Alle Transaktionen';
      case AppLanguage.turkish:
        return 'Bütün əməliyyatlar';
      case AppLanguage.arabic:
        return 'جميع المعاملات';
      case AppLanguage.bosnian:
        return 'Sve transakcije';
      case AppLanguage.spanish:
        return 'Todas las transacciones';
      case AppLanguage.persian:
        return 'همه تراکنش‌ها';
      case AppLanguage.english:
      default:
        return 'All Transactions';
    }
  }

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

  // Kategorien
  String get selectCategory => _getLocalizedText(
      'Kategorie wählen', 'Select category', 'Kateqoriya seçin');
  String get customCategory => _getLocalizedText(
      'Benutzerdefinierte Kategorie', 'Custom category', 'Xüsusi kateqoriya');
  String get enterCustomCategory => _getLocalizedText(
      'Eigene Kategorie eingeben',
      'Enter custom category',
      'Xüsusi kateqoriya daxil edin');

  // Wiederholungstypen
  String get recurrenceType => _getLocalizedText(
      'Wiederholungstyp', 'Recurrence type', 'Təkrarlanma növü');
  String get variable => _getLocalizedText('Variabel', 'Variable', 'Dəyişkən');
  String get fixed => _getLocalizedText('Fest', 'Fixed', 'Sabit');

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
