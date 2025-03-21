import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Plattformadaptive Formular-Elemente
class PlatformAdaptiveForm {
  /// Erstellt ein plattformadaptives Textfeld
  static Widget buildTextField({
    required BuildContext context,
    required String label,
    String? placeholder,
    String? initialValue,
    TextEditingController? controller,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    bool obscureText = false,
    bool enabled = true,
    bool autofocus = false,
    int? maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onEditingComplete,
    FormFieldValidator<String>? validator,
    String? helperText,
    Widget? prefix,
    Widget? suffix,
    EdgeInsetsGeometry? padding,
    BoxDecoration? decoration,
  }) {
    // CupertinoTextField unterstützt kein initialValue, daher erstellen wir einen
    // TextEditingController wenn initialValue angegeben und kein Controller existiert
    if (initialValue != null && controller == null) {
      controller = TextEditingController(text: initialValue);
    }

    if (Platform.isIOS) {
      // iOS-spezifisches Textfeld
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Container(
            decoration: decoration ??
                BoxDecoration(
                  color: CupertinoColors.systemBackground.resolveFrom(context),
                  border: Border.all(
                    color: CupertinoColors.systemGrey4.resolveFrom(context),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 8.0),
            child: CupertinoTextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction: textInputAction,
              obscureText: obscureText,
              enabled: enabled,
              autofocus: autofocus,
              maxLines: maxLines,
              maxLength: maxLength,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onEditingComplete: onEditingComplete,
              placeholder: placeholder ?? label,
              prefix: prefix,
              suffix: suffix,
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
              decoration: const BoxDecoration(
                color: Colors.transparent,
              ),
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
              child: Text(
                helperText,
                style: TextStyle(
                  fontSize: 12.0,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
            ),
        ],
      );
    } else {
      // Android-spezifisches Textfeld
      return TextFormField(
        controller: controller,
        initialValue: controller == null
            ? initialValue
            : null, // Entweder Controller oder initialValue
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        obscureText: obscureText,
        enabled: enabled,
        autofocus: autofocus,
        maxLines: maxLines,
        maxLength: maxLength,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        onEditingComplete: onEditingComplete,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          helperText: helperText,
          prefixIcon: prefix,
          suffixIcon: suffix,
          enabled: enabled,
          border: const OutlineInputBorder(),
        ),
      );
    }
  }

  /// Erstellt ein plattformadaptives Dropdown
  static Widget buildDropdown<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    String? helperText,
    bool isExpanded = true,
    bool disabled = false,
  }) {
    if (Platform.isIOS) {
      // iOS-spezifisches Dropdown (Picker in einem Button)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          GestureDetector(
            onTap: disabled
                ? null
                : () => _showIOSPicker<T>(
                      context: context,
                      label: label,
                      items: items,
                      currentValue: value,
                      onChanged: onChanged,
                    ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Finde das passende Label für den aktuellen Wert
                  Text(
                    items
                        .firstWhere((item) => item.value == value)
                        .child
                        .toString(),
                    style: TextStyle(
                      color: disabled
                          ? CupertinoColors.systemGrey.resolveFrom(context)
                          : CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_down,
                    size: 16.0,
                    color: disabled
                        ? CupertinoColors.systemGrey.resolveFrom(context)
                        : CupertinoColors.systemGrey2.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
              child: Text(
                helperText,
                style: TextStyle(
                  fontSize: 12.0,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
            ),
        ],
      );
    } else {
      // Android-spezifisches Dropdown
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              helperText: helperText,
              border: const OutlineInputBorder(),
            ),
            isEmpty: false,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                items: items,
                onChanged: disabled ? null : onChanged,
                isExpanded: isExpanded,
                isDense: true,
              ),
            ),
          ),
        ],
      );
    }
  }

  /// Zeigt einen iOS-Picker für Dropdown-Elemente an
  static Future<void> _showIOSPicker<T>({
    required BuildContext context,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required T currentValue,
    required ValueChanged<T?> onChanged,
  }) async {
    // Fokus entfernen, um Keyboard zu schließen
    FocusScope.of(context).unfocus();

    // Temporärer Wert
    T? pickedValue = currentValue;

    // Picker anzeigen
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 250.0,
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemBackground,
            context,
          ),
          child: Column(
            children: [
              // Titelzeile mit Buttons
              Container(
                height: 44.0,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondarySystemBackground,
                  context,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Abbrechen'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    CupertinoButton(
                      child: const Text('Fertig'),
                      onPressed: () {
                        onChanged(pickedValue);
                        Navigator.of(context).pop();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ],
                ),
              ),
              // Der eigentliche Picker
              Expanded(
                child: CupertinoPicker(
                  backgroundColor: CupertinoDynamicColor.resolve(
                    CupertinoColors.systemBackground,
                    context,
                  ),
                  itemExtent: 32.0,
                  scrollController: FixedExtentScrollController(
                    initialItem: items
                        .indexWhere((element) => element.value == currentValue),
                  ),
                  onSelectedItemChanged: (index) {
                    pickedValue = items[index].value;
                  },
                  children: items
                      .map((item) => Center(
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                fontSize: 17.0,
                              ),
                              child: item.child,
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Erstellt ein plattformadaptives Datumsauswahlfeld
  static Widget buildDatePicker({
    required BuildContext context,
    required String label,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helperText,
    bool disabled = false,
  }) {
    // Standardwerte für erstes und letztes Datum
    firstDate ??= DateTime.now().subtract(const Duration(days: 365 * 10));
    lastDate ??= DateTime.now().add(const Duration(days: 365 * 10));

    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    final String formattedDate = formatter.format(selectedDate);

    if (Platform.isIOS) {
      // iOS-spezifischer DatePicker
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          GestureDetector(
            onTap: disabled
                ? null
                : () => _showIOSDatePicker(
                      context: context,
                      selectedDate: selectedDate,
                      onDateChanged: onDateChanged,
                      firstDate: firstDate!,
                      lastDate: lastDate!,
                    ),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground.resolveFrom(context),
                border: Border.all(
                  color: CupertinoColors.systemGrey4.resolveFrom(context),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: disabled
                          ? CupertinoColors.systemGrey.resolveFrom(context)
                          : CupertinoColors.label.resolveFrom(context),
                    ),
                  ),
                  Icon(
                    CupertinoIcons.calendar,
                    size: 20.0,
                    color: disabled
                        ? CupertinoColors.systemGrey.resolveFrom(context)
                        : CupertinoColors.systemGrey2.resolveFrom(context),
                  ),
                ],
              ),
            ),
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 4.0),
              child: Text(
                helperText,
                style: TextStyle(
                  fontSize: 12.0,
                  color: CupertinoColors.systemGrey.resolveFrom(context),
                ),
              ),
            ),
        ],
      );
    } else {
      // Android-spezifischer DatePicker
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: disabled
                ? null
                : () => _showAndroidDatePicker(
                      context: context,
                      selectedDate: selectedDate,
                      onDateChanged: onDateChanged,
                      firstDate: firstDate!,
                      lastDate: lastDate!,
                    ),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                helperText: helperText,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              child: Text(
                formattedDate,
                style: TextStyle(
                  color: disabled
                      ? Theme.of(context).disabledColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }

  /// Zeigt einen iOS-DatePicker an
  static Future<void> _showIOSDatePicker({
    required BuildContext context,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateChanged,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Fokus entfernen, um Keyboard zu schließen
    FocusScope.of(context).unfocus();

    // Temporärer Wert
    DateTime pickedDate = selectedDate;

    // DatePicker anzeigen
    await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 250.0,
          color: CupertinoDynamicColor.resolve(
            CupertinoColors.systemBackground,
            context,
          ),
          child: Column(
            children: [
              // Titelzeile mit Buttons
              Container(
                height: 44.0,
                color: CupertinoDynamicColor.resolve(
                  CupertinoColors.secondarySystemBackground,
                  context,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      child: const Text('Abbrechen'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    CupertinoButton(
                      child: const Text('Fertig'),
                      onPressed: () {
                        onDateChanged(pickedDate);
                        Navigator.of(context).pop();
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                  ],
                ),
              ),
              // Der eigentliche DatePicker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: selectedDate,
                  minimumDate: firstDate,
                  maximumDate: lastDate,
                  onDateTimeChanged: (DateTime date) {
                    pickedDate = date;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Zeigt einen Android-DatePicker an
  static Future<void> _showAndroidDatePicker({
    required BuildContext context,
    required DateTime selectedDate,
    required ValueChanged<DateTime> onDateChanged,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    // Fokus entfernen, um Keyboard zu schließen
    FocusScope.of(context).unfocus();

    // DatePicker anzeigen
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      onDateChanged(pickedDate);
    }
  }
}

// Helper für DateFormat
class DateFormat {
  final String pattern;

  DateFormat(this.pattern);

  String format(DateTime date) {
    // Sehr einfache Implementierung - in der Realität sollte man intl verwenden
    return pattern
        .replaceAll('dd', date.day.toString().padLeft(2, '0'))
        .replaceAll('MM', date.month.toString().padLeft(2, '0'))
        .replaceAll('yyyy', date.year.toString());
  }
}
