import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Stepper +/- pour éditer un nombre de parts (création + édition de recette).
class ServingsStepper extends StatelessWidget {
  const ServingsStepper({super.key, required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          onTap: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            '$value',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        _StepButton(icon: Icons.add_rounded, onTap: () => onChanged(value + 1)),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled ? AppColors.primary : AppColors.card,
          shape: BoxShape.circle,
          border: enabled ? null : Border.all(color: AppColors.divider),
        ),
        child: Icon(icon,
            size: 18, color: enabled ? Colors.white : AppColors.textMuted),
      ),
    );
  }
}
