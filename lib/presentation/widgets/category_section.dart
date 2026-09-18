import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/theme/app_theme.dart';
import '../providers/audit_provider.dart';
import 'evidence_picker.dart';
import 'score_dropdown.dart';
import 'score_indicator.dart';

/// Um bloco expansível para uma categoria (1S..5S): lista de perguntas com
/// seletor de nota (e a nota do mês anterior ao lado, para comparação),
/// resultado calculado automaticamente e evidências.
class CategorySection extends StatelessWidget {
  final FiveSCategoryDef category;
  const CategorySection({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audit = provider.current!;
    final media = audit.averageForCategory(category.code);
    final mediaAnterior = provider.previousAverageForCategory(category.code);

    return Card(
      child: ExpansionTile(
        initiallyExpanded: category.code == '1S',
        title: Text(category.displayTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6, right: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ScoreIndicator(label: 'Resultado do ${category.code}', score: media),
              ),
              if (mediaAnterior != null) ...[
                const SizedBox(width: 10),
                _PreviousBadge(label: 'Mês ant.', value: mediaAnterior),
              ],
            ],
          ),
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
                  const SizedBox(width: 8),
                  Builder(builder: (_) {
                    final anterior = provider.previousScoreFor(category.code, q.number);
                    if (anterior == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6, top: 4),
                      child: _PreviousChip(value: anterior),
                    );
                  }),
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

/// Pequeno indicador de comparação com a média do mês anterior, mostrado
/// ao lado do resultado de cada senso.
class _PreviousBadge extends StatelessWidget {
  final String label;
  final double value;
  const _PreviousBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForScore(value);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
          ),
        ],
      ),
    );
  }
}

/// Nota individual do mês anterior, exibida ao lado do seletor de cada
/// pergunta — só leitura, para comparação instantânea.
class _PreviousChip extends StatelessWidget {
  final int value;
  const _PreviousChip({required this.value});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.colorForScore(value.toDouble());
    return Tooltip(
      message: 'Nota do mês anterior',
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Text(
          '$value',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
