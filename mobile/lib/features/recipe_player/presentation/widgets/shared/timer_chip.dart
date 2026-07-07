import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/recipe_timer.dart';

/// Minuteur en cours affiché de façon compacte (top bar) quand il ne
/// concerne pas l'étape actuellement affichée (maquette 10e/10j).
class TimerChip extends StatelessWidget {
  const TimerChip({super.key, required this.timer});

  final RecipeTimer timer;

  @override
  Widget build(BuildContext context) {
    final remaining = timer.remaining ?? Duration.zero;
    final minutes = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF1DE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFF1DFB8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 15, color: AppColors.timerAccent),
          const SizedBox(width: 6),
          Text(
            '$minutes:$seconds',
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF8A6316),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
