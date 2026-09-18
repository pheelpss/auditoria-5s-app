import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Seletor suspenso de nota (0 a 5). O auditor nunca digita números —
/// apenas toca e escolhe da lista, em um único clique.
class ScoreDropdown extends StatelessWidget {
  final int? value;
  final ValueChanged<int> onChanged;
  const ScoreDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = value == null ? Colors.grey.shade300 : AppTheme.colorForScore(value!.toDouble());
    return Container(
      width: 64,
      height: 44,
      decoration: BoxDecoration(
        color: value == null ? Colors.grey.shade100 : color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value == null ? Colors.grey.shade400 : color, width: 1.4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          alignment: Alignment.center,
          hint: const Center(child: Text('-')),
          icon: const SizedBox.shrink(),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          items: List.generate(6, (i) => i)
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Center(
                      child: Text(
                        '$n',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colorForScore(n.toDouble()),
                        ),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
