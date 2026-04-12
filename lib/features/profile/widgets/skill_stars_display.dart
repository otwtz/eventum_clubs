import 'package:flutter/material.dart';

/// Отображение уровня 0.0–5.0 звёздами (половинки — [Icons.star_half]).
class SkillStarsDisplay extends StatelessWidget {
  const SkillStarsDisplay({
    super.key,
    required this.value,
    this.size = 26,
  });

  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final v = value.clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = v - i;
        if (starValue >= 1) {
          return Icon(Icons.star, color: color, size: size);
        }
        if (starValue >= 0.5) {
          return Icon(Icons.star_half, color: color, size: size);
        }
        return Icon(Icons.star_border, color: color, size: size);
      }),
    );
  }
}
