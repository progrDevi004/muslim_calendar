// lib/data/services/automatic_category_service.dart

import 'package:muslim_calendar/models/category_model.dart';

/// Einfache regelbasierte Logik, um eine Kategorie anhand von Text zu ermitteln.
/// In einer echten KI-Lösung würde man ggf. ML-Modelle, NLP und Training einsetzen.
class AutomaticCategoryService {
  // >>> ERWEITERTE Dictionary-Map mit vielen Schlagwörtern:
  static final Map<String, List<String>> _keywordMap = {
    // ---------------------
    // Kategorie: ISLAM
    // ---------------------
    'Islam': [
      // Deutsch
      "Moschee", "Gebet", "Koran", "Sunnah", "Umrah", "Tawaf", "Halal", "Haram",
      "Dua", "Iftar", "Suhoor", "Ramadan", "Eid", "Minarett", "Adhan",
      "Muezzin",
      "Fard", "Witr", "Zakat", "Madrasa", "Hadith", "Ulama", "Mecca", "Medina",
      "Kaaba", "Takbir", "Tawakkul", "Tarawih", "Tahajjud", "Iman", "Imam",
      "InshaAllah", "Fatwa", "Ajr", "Ihsan", "Dhikr", "Dschihad", "Scharia",
      "Sadaqah", "Fitra", "Dhul-Hijjah", "Sunnah", "Nafs", "Hidschra", "Qibla",
      "Sawab", "Ibn", "Mawlid", "Tafsir", "Rakat", "Jannah", "Aqidah", "Taqwa",
      "Al-Fatiha", "Surah", "Ayah", "Minbar", "Kalif", "Dīn", "Risalah",
      "Ghusl",
      "Janaza", "Umma", "Wudu", "Istikhara", "Mustahab", "Makruh", "Mahr",
      "Sirat", "Awqaf", "Baytullah", "Rukn", "Mihrab", "Mufti", "Khalifa",
      "Shahada", "Shaytan", "Mahr", "Qunut", "Munajat", "Nisab", "Halaqa",
      "Siyam", "Miqdad", "Shura", "Maqam", "Madhhab", "La ilaha illa-Allah",
      "Waqf", "Mishkat", "Tabligh", "Khatib", "Marwa", "Safa", "Ihram",
      "Safa-Marwa", "Marwa",
      "Maqam Ibrahim",
      "Zamzam",
      "Shafa'ah",
      "Kusuf",
      "Ayat",
      // Englisch
      "Mosque", "Prayer", "Quran", "Sunnah", "Umrah", "Tawaf", "Halal", "Haram",
      "Dua", "Iftar", "Suhoor", "Ramadan", "Eid", "Minaret", "Adhan", "Muezzin",
      "Fard", "Witr", "Zakat", "Madrasa", "Hadith", "Ulama", "Mecca", "Medina",
      "Kaaba", "Takbir", "Tawakkul", "Taraweeh", "Tahajjud", "Iman", "Imam",
      "InshaAllah", "Fatwa", "Ajr", "Ihsan", "Dhikr", "Jihad", "Sharia",
      "Sadaqah",
      "Fitra", "Dhul-Hijjah", "Nafs", "Hijra", "Qibla", "Reward", "Ibn",
      "Mawlid",
      "Tafsir", "Rakat", "Jannah", "Aqidah", "Taqwa", "Al-Fatiha", "Surah",
      "Ayah",
      "Minbar", "Caliph", "Din", "Risalah", "Ghusl", "Janazah", "Ummah", "Wudu",
      "Istikhara", "Mustahabb", "Makruh", "Mahr", "Sirat", "Awqaf", "Baytullah",
      "Rukn", "Mihrab", "Mufti", "Khalifah", "Shahadah", "Shaytan", "Qunut",
      "Munajat", "Nisab", "Halaqa", "Sawm", "Miqdad", "Shura", "Maqam",
      "Madhhab",
      "La ilaha illallah", "Waqf", "Mishkat", "Tabligh", "Khatib", "Safa",
      "Marwa",
      "Ihram",
      "Maqam Ibrahim",
      "Zamzam",
      "Intercession",
      "Kusuf",
      "Verses",
      //türkisch
      "Cami", "Namaz", "Kur'an", "Sünnet", "Umre", "Tavaf", "Helal", "Haram",
      "Dua", "İftar", "Sahur", "Ramazan", "Bayram", "Minare", "Ezan", "Müezzin",
      "Farz", "Vitir", "Zekat", "Medrese", "Hadis", "Ulema", "Mekke", "Medine",
      "Kabe", "Tekbir", "Tevekkül", "Teravih", "Teheccüd", "İman", "İmam",
      "Fetva", "Sevap", "İhsan", "Zikir", "Cihad", "Şeriat",
      "Sadaka",
      "Fıtır", "Zilhicce", "Nefs", "Hicret", "Kıble", "Sevap", "İbn", "Mevlid",
      "Tefsir", "Rekat", "Cennet", "Akide", "Takva", "Fatiha", "Sure", "Ayet",
      "Minber", "Halife", "Din", "Risale", "Gusül", "Cenaze", "Ümmet", "Abdest",
      "İstihare", "Müstehap", "Mekruh", "Mehir", "Sırat", "Evkaf", "Beytullah",
      "Rükn", "Mihrab", "Müftü", "Hilafet", "Şehadet", "Şeytan", "Kunut",
      "Münacat", "Nisap", "Halka", "Oruç", "Tefsir1", "Şura", "Makâm", "Mezhep",
      "La ilahe illallah", "Vakıf", "Mişkat", "Tebliğ", "Hatip", "Safa",
      "Merve",
      "İhram", "Makâm-ı İbrahim", "Zemzem", "Şefaat", "Küsuf", "Ayetler",
      "Sohbet", "Ders",
      // Arabische Begriffe
      'tawaf',
      'umrah',
      'hajj',
      'zul-hijjah',
      'sunnah',
      'iman',
      'dars',
    ],

    // ---------------------
    // Kategorie: PRIVAT
    // ---------------------
    'Privat': [
      // Deutsch
      "Privat", "Familie", "Freunde", "Geburtstag", "Feier", "Wochenende",
      "Urlaub", "Freizeit", "Hobby", "Ausflug", "Spaziergang", "Haushalt",
      "Haustier", "Kino", "Restaurant", "Party", "Verwandte", "Einkaufen",
      "Schlafen", "Entspannen", "Pflanzen", "Sport", "Joggen", "Yoga",
      "Fahrradfahren", "Schwimmen", "Grillen", "Picknick", "Fernsehen", "Lesen",
      "Musik", "Konzert", "Videospiele", "Basteln", "Malen", "Fotografie",
      "Buchclub", "Kochen", "Backen", "Tanzen", "Sauna", "Urlaubsplanung",
      "Strand", "Museum", "Theater", "Oper", "Stadtbummel", "Gartenarbeit",
      "Wohnung", "Hausputz", "Schlittschuhlaufen", "Skifahren", "Rodeln",
      "Eishockey", "Fußball", "Volleyball", "Ehejubiläum", "Taufen",
      "Frühstück",
      "Mittagessen", "Abendessen", "Spieleabend", "Karten spielen",
      "Brief schreiben",
      "Brief lesen", "Rätsel lösen", "Wellness", "Therme", "Schlendern",
      "Wochenmarkt", "Möbel einkaufen", "Deko planen", "Zeitungslesen",
      "Briefmarken sammeln", "Bastelrunde", "Zeichnen", "Handarbeit",
      "Elternabend", "Geschenke kaufen", "Geschenke verpacken", "Kekse backen",
      "Winterspaziergang", "Herbstblätter sammeln", "Picknickkorb",
      "Fotobuch erstellen", "Freunde treffen", "Kaffee trinken", "Teepause",
      "Schlafzimmer aufräumen", "Fitnessstudio", "Brettspiele",
      "Online-Streaming",
      "Serien schauen", "Sonnenbad", "Sternenhimmel", "Geocaching",
      "Städtetrip",
      "Kurzurlaub",
      "Wandern"
          // Englisch
          "Private",
      "Family",
      "Friends",
      "Birthday",
      "Party",
      "Weekend",
      "Vacation", "Leisure", "Hobby", "Trip", "Stroll", "Household",
      "Pet", "Cinema", "Restaurant", "Celebration", "Relatives", "Shopping",
      "Sleeping", "Relaxing", "Plants", "Sports", "Jogging", "Yoga",
      "Cycling", "Swimming", "Barbecue", "Picnic", "TV", "Reading",
      "Music", "Concert", "Video games", "Crafting", "Painting", "Photography",
      "Book club", "Cooking", "Baking", "Dancing", "Sauna", "Holiday planning",
      "Beach", "Museum", "Theatre", "Opera", "City walk", "Gardening",
      "Apartment", "House cleaning", "Ice skating", "Skiing", "Sledding",
      "Ice hockey", "Soccer", "Volleyball", "Anniversary", "Baptism",
      "Breakfast", "Lunch", "Dinner", "Board games", "Card games",
      "Writing letters",
      "Reading letters", "Puzzles", "Wellness", "Thermal spa",
      "Window shopping",
      "Farmers market", "Furniture shopping", "Decoration planning",
      "Newspaper reading",
      "Stamp collecting", "Art session", "Sketching", "Knitting",
      "Parent meeting", "Gift buying", "Gift wrapping", "Cookie baking",
      "Winter walk", "Autumn leaves", "Picnic basket", "Photo album",
      "Friend meetup", "Coffee break", "Tea time", "Bedroom cleaning",
      "Gym", "Board gaming", "Online streaming", "Binge watching", "Sunbathing",
      "Star gazing",
      "Geocaching",
      "City trip",
      "Short vacation",
      "Hiking",
      // Weitere häufige Begriffe
      'hobby',
      'mutter',
      'vater',
      'mom',
      'dad',
      'visiting',
      'wedding',
      //türkisch
      "Özel", "Aile", "Arkadaşlar", "Doğum günü", "Parti", "Hafta sonu",
      "Tatil", "Boş zaman", "Hobi", "Gezi", "Yürüyüş", "Ev işleri",
      "Evcil hayvan", "Sinema", "Restoran", "Kutlama", "Akrabalar", "Alışveriş",
      "Uyumak", "Dinlenmek", "Bitkiler", "Spor", "Koşu", "Yoga",
      "Bisiklet", "Yüzme", "Mangal", "Piknik", "Televizyon", "Okuma",
      "Müzik", "Konser", "Video oyunları", "El işi", "Resim", "Fotoğrafçılık",
      "Kitap kulübü", "Yemek yapmak", "Fırıncılık", "Dans etmek", "Sauna",
      "Tatil planlama", "Plaj", "Müze", "Tiyatro", "Opera", "Şehir turu",
      "Bahçe bakımı", "Daire", "Ev temizliği", "Buz pateni", "Kayak", "Kızak",
      "Buz hokeyi", "Futbol", "Voleybol", "Yıl dönümü", "Vaftiz",
      "Kahvaltı", "Öğle yemeği", "Akşam yemeği", "Masa oyunları",
      "Kart oyunları",
      "Mektup yazma", "Mektup okuma", "Bulmaca çözme", "Spa", "Termal",
      "Vitrin gezmesi", "Pazar alışverişi", "Mobilya bakma", "Dekor planlama",
      "Gazete okuma", "Pul koleksiyonu", "Sanat atölyesi", "Karalama", "Örgü",
      "Veli toplantısı", "Hediye almak", "Hediye paketleme", "Kurabiye pişirme",
      "Kış yürüyüşü", "Sonbahar yaprakları", "Piknik sepeti", "Fotoğraf albümü",
      "Arkadaş buluşması", "Kahve molası", "Çay saati", "Yatak odası düzenleme",
      "Spor salonu", "Kutu oyunları", "Online izleme", "Dizi maratonu",
      "Güneşlenme", "Yıldız gözlemi", "Geocaching", "Şehir gezisi",
      "Kısa tatil",
      "Doğa yürüyüşü"
    ],

    // ---------------------
    // Kategorie: GESCHÄFTLICH
    // ---------------------
    'Geschäftlich': [
      // Deutsch
      "Geschäftlich", "Meeting", "Firma", "Chef", "Kunde", "Büro", "Deadline",
      "Vertrag", "Mitarbeiter", "Projekt", "Angebot", "Team", "Präsentation",
      "Konferenz", "Rechnung", "Steuern", "Bilanz", "Accounting", "Belegschaft",
      "Geschäftsreise", "Budget", "Planung", "Kalkulation", "Bestellung",
      "Wareneingang", "Lieferant", "Vertrieb", "Marketing", "Personalabteilung",
      "Buchhaltung", "Personalgespräch", "Auftrag", "Inventur", "Mahnung",
      "Reklamation", "Geschäftsführer", "Protokoll", "Meetingraum", "Lobby",
      "Sitzung", "Zielsetzung", "Leistungsbeurteilung", "Abteilung", "Entwurf",
      "Fortbildung", "Kundenkontakt", "Verhandeln", "Veranstaltung",
      "Messe", "Geschäftsessen", "Projektplan", "Interne Kommunikation",
      "Netzwerken", "Homeoffice", "Dienstreise", "Risikomanagement",
      "Ressourcen",
      "Kundenservice", "Anforderung", "Deadline-Extension", "Kostenvoranschlag",
      "Wartungsvertrag", "Zeiterfassung", "Consulting", "Führungskraft",
      "Karriere", "Anfahrt", "Besprechung", "Team-Event", "Zielvereinbarung",
      "Reisekosten", "Führung", "Statusupdate", "Mittagspause", "Beamer",
      "Firmenwagen", "Schulung", "Coaching", "Einarbeitung", "Dienstplan",
      "Report", "Brainstorming", "Referat", "Veröffentlichung", "Audit",
      "Datenschutz", "Konzept", "Entwicklung", "Briefing", "Abgabefrist",
      "Projektmanagement", "Stakeholder", "Budgetplanung", "Q&A",
      "Abschreibung",
      "Jahresabschluss", "Umstrukturierung",
      // Englisch
      "Business", "Meeting", "Company", "Boss", "Client", "Office", "Deadline",
      "Contract", "Employee", "Project", "Proposal", "Team", "Presentation",
      "Conference", "Invoice", "Tax", "Balance sheet", "Accounting",
      "Workforce",
      "Business trip", "Budget", "Planning", "Calculation", "Order",
      "Goods receipt", "Supplier", "Sales", "Marketing", "Human resources",
      "Bookkeeping", "Review meeting", "Task", "Inventory", "Reminder",
      "Complaint", "CEO", "Minutes", "Meeting room", "Lobby", "Session",
      "Target setting", "Performance review", "Department", "Draft",
      "Training", "Customer contact", "Negotiation", "Event",
      "Exhibition", "Business lunch", "Project plan", "Internal communication",
      "Networking", "Home office", "Business travel", "Risk management",
      "Resources",
      "Customer service", "Requirement", "Deadline extension", "Quotation",
      "Maintenance contract", "Time tracking", "Consulting", "Leadership",
      "Career", "Transport", "Briefing", "Team event", "Goal agreement",
      "Travel expenses", "Management", "Status update", "Lunch break",
      "Projector",
      "Company car", "Seminar", "Coaching", "Onboarding", "Duty roster",
      "Report", "Brainstorming", "Lecture", "Release", "Audit",
      "Data protection", "Concept", "Development", "Scrum", "Deliverable",
      "Project management", "Stakeholder", "Budget planning", "Q&A",
      "Depreciation",
      "Annual report", "Restructuring",
      //türksich
      "İş", "Toplantı", "Şirket", "Patron", "Müşteri", "Ofis", "Son tarih",
      "Sözleşme", "Çalışan", "Proje", "Teklif", "Takım", "Sunum",
      "Konferans", "Fatura", "Vergi", "Bilanço", "Muhasebe", "İş gücü",
      "İş gezisi", "Bütçe", "Planlama", "Hesaplama", "Sipariş",
      "Mal kabul", "Tedarikçi", "Satış", "Pazarlama", "İnsan kaynakları",
      "Defter tutma", "Değerlendirme toplantısı", "Görev", "Envanter",
      "Hatırlatma", "Şikayet", "CEO", "Tutanak", "Toplantı odası", "Lobi",
      "Oturum", "Hedef belirleme", "Performans değerlendirme", "Bölüm",
      "Tasarım", "Eğitim", "Müşteri iletişimi", "Müzakere", "Etkinlik",
      "Fuar", "İş yemeği", "Proje planı", "Dahili iletişim", "Ağ oluşturma",
      "Evden çalışma", "İş seyahati", "Risk yönetimi", "Kaynaklar",
      "Müşteri hizmetleri", "Gereklilik", "Son tarih uzatma", "Fiyat teklifi",
      "Bakım sözleşmesi", "Zaman takibi", "Danışmanlık", "Liderlik",
      "Kariyer", "Ulaşım", "Brifing", "Takım etkinliği", "Hedef anlaşması",
      "Seyahat masrafları", "Yönetim", "Durum güncellemesi", "Öğle arası",
      "Projektör", "Şirket aracı", "Seminer", "Koçluk", "Oryantasyon",
      "Vardiya planı", "Rapor", "Beyin fırtınası", "Konuşma", "Yayın",
      "Denetim", "Veri koruma", "Konsept", "Geliştirme", "Çıktı",
      "Proje yönetimi", "Paydaş", "Bütçe planlama", "Soru-Cevap", "Amortisman",
      "Yıllık rapor", "Yapısal değişiklik",
      // Mögliche Synonyme
      'shareholder',
      'ceo',
      'manager',
    ],
  };

  /// Ermittelt auf Basis von [title] und [notes] eine wahrscheinliche Kategorie
  /// anhand von Schlagwörtern. Gibt den Kategorienamen (z. B. 'Islam') zurück
  /// oder null, falls nichts passt.
  static String? suggestCategoryName(String title, String? notes) {
    final textToCheck = (title + ' ' + (notes ?? '')).toLowerCase();

    // Für jede bekannte Kategorie durchgehen
    for (final categoryName in _keywordMap.keys) {
      final keywords = _keywordMap[categoryName]!;
      // Prüfen, ob ein Keyword vorkommt
      for (final kw in keywords) {
        if (textToCheck.contains(kw.toLowerCase())) {
          return categoryName;
        }
      }
    }
    return null;
  }
}
