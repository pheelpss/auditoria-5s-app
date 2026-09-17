import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../providers/audit_provider.dart';
import 'evidence_picker.dart';
import 'score_dropdown.dart';
import 'score_indicator.dart';

/// Um bloco expansível para uma categoria (1S..5S): lista de perguntas com
/// seletor de nota, resultado calculado automaticamente e evidências.
class CategorySection extends StatelessWidget {
  final FiveSCategoryDef category;
  const CategorySection({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audit = provider.current!;
    final media = audit.averageForCategory(category.code);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: category.code == '1S',
        title: Text(category.displayTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: ScoreIndicator(label: 'Resultado do ${category.code}', score: media),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final q in category.questions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text('${q.number}  ${q.text}', style: const TextStyle(fontSize: 13.5)),
                  ),
                  const SizedBox(width: 10),
                  ScoreDropdown(
                    value: audit.items
                        .firstWhere((i) => i.categoryCode == category.code && i.number == q.number)
                        .score,
                    onChanged: (v) => provider.setScore(category.code, q.number, v),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          EvidencePicker(categoryCode: category.code),
        ],
      ),
    );
  }
}
