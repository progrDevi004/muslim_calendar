// lib/models/selected_calendar.dart
class SelectedCalendar {
  final String id;
  final String title;
  final bool isSelected;

  SelectedCalendar({
    required this.id,
    required this.title,
    this.isSelected = false,
  });

  SelectedCalendar copyWith({
    String? id,
    String? title,
    bool? isSelected,
  }) {
    return SelectedCalendar(
      id: id ?? this.id,
      title: title ?? this.title,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
