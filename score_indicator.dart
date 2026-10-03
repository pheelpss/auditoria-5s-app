import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/five_s_data.dart';

/// Mostra nota numérica + barra de progresso + classificação, usado tanto
/// no resultado de cada senso quanto na nota geral.
class ScoreIndicator extends StatelessWidget {
  final String label;
  final double? score;
  final bool big;
  const ScoreIndicator({super.key, required this.label, required this.score, this.big = false});

  @override
  Widget build(BuildContext context) {
    final s = score ?? 0;
    final color = AppTheme.colorForScore(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: big ? 18 : 14)),
            Text(
              score != null ? score!.toStringAsFixed(2) : '-',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: big ? 22 : 16,
                color: score != null ? color : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearPercentIndicator(
          lineHeight: big ? 14 : 10,
          percent: (s / 5).clamp(0, 1),
          backgroundColor: Colors.grey.shade200,
          progressColor: color,
          barRadius: const Radius.circular(8),
          padding: EdgeInsets.zero,
        ),
        if (score != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              classificacaoParaNota(score!),
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: big ? 15 : 12),
            ),
          ),
      ],
    );
  }
}
