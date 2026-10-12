import 'package:flutter/material.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/core/design_system/colors/app_contrast.dart';

class AppColorChoice extends StatelessWidget {
  static const palette = <int, String>{
    0xFF3B82F6: 'azul',
    0xFF10B981: 'verde',
    0xFFF59E0B: 'amarela',
    0xFFEF4444: 'vermelha',
    0xFF8B5CF6: 'roxa',
    0xFFEC4899: 'rosa',
    0xFF14B8A6: 'turquesa',
    0xFF64748B: 'cinza',
  };

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final double diameter;

  const AppColorChoice({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.diameter = 36,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final targetSize = diameter < 48 ? 48.0 : diameter;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: SizedBox.square(
        dimension: targetSize,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: Center(
              child: AnimatedContainer(
                duration: AppAnimations.durationFor(
                  context,
                  AppAnimations.transition,
                ),
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: selected
                      ? Border.all(color: theme.colorScheme.onSurface, width: 2)
                      : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                child: selected
                    ? Icon(
                        Icons.check,
                        size: diameter * 0.5,
                        color: AppContrast.foregroundOn(color),
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
