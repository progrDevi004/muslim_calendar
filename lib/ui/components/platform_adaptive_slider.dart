import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Eine plattformspezifische Slider-Komponente
/// Auf Android: Material Slider
/// Auf iOS: CupertinoSlider
class PlatformAdaptiveSlider extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final Color? activeColor;
  final int? divisions;
  final String? label;

  const PlatformAdaptiveSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.activeColor,
    this.divisions,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = activeColor ?? theme.colorScheme.primary;

    if (Platform.isIOS) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        activeColor: color,
        divisions: divisions,
      );
    } else {
      return Slider(
        value: value,
        min: min,
        max: max,
        onChanged: onChanged,
        activeColor: color,
        divisions: divisions,
        label: label,
      );
    }
  }
}
