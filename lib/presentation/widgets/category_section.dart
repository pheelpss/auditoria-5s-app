import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/theme/app_theme.dart';
import '../providers/audit_provider.dart';
import 'score_dropdown.dart';
import 'score_indicator.dart';

/// Um bloco expansível para uma categoria (1S..5S): lista de perguntas com
/// seletor de nota (e a nota do mês anterior ao lado, para comparação) e
/// resultado calculado automaticamente. (Evidências agora são globais no final).
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
      margin: const EdgeInsets.only(bottom: 6), // Margem reduzida para compactar
      child: ExpansionTile(
        visualDensity: VisualDensity.compact, // Achata o cabeçalho do painel
        initiallyExpanded: category.code == '1S',
        title: Text(category.displayTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // Fonte levemente menor
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4, right: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ScoreIndicator(label: 'Resultado do ${category.code}', score: media),
              ),
              if (mediaAnterior != null) ...[
                const SizedBox(width: 8),
                _PreviousBadge(label: 'Mês ant.', value: mediaAnterior),
              ],
            ],
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12), // Padding interno reduzido
        children: [
          for (final q in audit.itemsFor(category.code))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4), // Distância menor entre perguntas
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text('${q.number}  ${q.text}', style: const TextStyle(fontSize: 13)), // Texto compacto
                  ),
                  const SizedBox(width: 6),
                  Builder(builder: (_) {
                    final anterior = provider.previousScoreFor(category.code, q.number);
                    if (anterior == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _PreviousChip(value: anterior),
                    );
                  }),
                  ScoreDropdown(
                    value: q.score,
                    onChanged: (v) {
                      // Atualiza a nota na tela
                      provider.setScore(category.code, q.number, v);
                      // SALVAMENTO AUTOMÁTICO NA HORA!
                      provider.saveCurrent(); 
                    },
                  ),
                ],
              ),
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Mais fino
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
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
        width: 26, // Círculo menor
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.6)),
        ),
        child: Text(
          '$value',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
        ),
      ),
    );
  }
}
