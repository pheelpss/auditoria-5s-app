import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/audit.dart';
import '../../domain/repositories/audit_repository.dart';
import '../providers/audit_provider.dart';
import 'history_screen.dart';

/// Tela de indicadores: quantidade de auditorias por área, evolução
/// mensal das notas, histórico completo e os mesmos filtros do
/// histórico (mês, ano, área, auditor).
class IndicatorsScreen extends StatefulWidget {
  const IndicatorsScreen({super.key});

  @override
  State<IndicatorsScreen> createState() => _IndicatorsScreenState();
}

class _IndicatorsScreenState extends State<IndicatorsScreen> {
  Future<void> _openFilters() async {
    final provider = context.read<AuditProvider>();
    String? mes = provider.filter.mes;
    int? ano = provider.filter.ano;
    final areaCtrl = TextEditingController(text: provider.filter.area ?? '');
    final auditorCtrl = TextEditingController(text: provider.filter.auditor ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (ctx, setModalState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Filtrar indicadores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                const SizedBox(height: 14),
                DropdownButtonFormField<String?>(
                  value: mes,
                  decoration: const InputDecoration(labelText: 'Mês'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...mesesReferencia.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (v) => setModalState(() => mes = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Ano (ex: 2026)'),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: ano?.toString() ?? ''),
                  onChanged: (v) => ano = int.tryParse(v),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Área auditada'),
                  controller: areaCtrl,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Auditor'),
                  controller: auditorCtrl,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.loadHistory(filter: const AuditFilter());
                          Navigator.pop(ctx);
                        },
                        child: const Text('Limpar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          provider.loadHistory(
                            filter: AuditFilter(
                              mes: mes,
                              ano: ano,
                              area: areaCtrl.text.trim().isEmpty ? null : areaCtrl.text.trim(),
                              auditor: auditorCtrl.text.trim().isEmpty ? null : auditorCtrl.text.trim(),
                            ),
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audits = provider.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: _openFilters),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : audits.isEmpty
              ? Center(
                  child: Text('Nenhuma auditoria encontrada para os filtros atuais',
                      style: TextStyle(color: Colors.grey.shade600)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  children: [
                    _SectionCard(
                      title: 'Auditorias por área',
                      child: _AuditsPerArea(audits: audits),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Evolução mensal das notas',
                      child: _MonthlyEvolution(audits: audits),
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Histórico completo (${audits.length})',
                      child: Column(
                        children: audits.map((a) => AuditTile(audit: a)).toList(),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Contagem de auditorias por área, com barra proporcional ao maior valor.
class _AuditsPerArea extends StatelessWidget {
  final List<Audit> audits;
  const _AuditsPerArea({required this.audits});

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final a in audits) {
      final area = a.area.trim().isEmpty ? '(Área não informada)' : a.area.trim();
      counts[area] = (counts[area] ?? 0) + 1;
    }
    final entries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final maxCount = entries.isEmpty ? 1 : entries.first.value;

    return Column(
      children: entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 110,
                child: Text(e.key, style: const TextStyle(fontSize: 12.5), overflow: TextOverflow.ellipsis),
              ),
              Expanded(
                child: LinearPercentIndicator(
                  lineHeight: 14,
                  percent: e.value / maxCount,
                  backgroundColor: Colors.grey.shade200,
                  progressColor: Theme.of(context).colorScheme.primary,
                  barRadius: const Radius.circular(6),
                  padding: EdgeInsets.zero,
                  trailing: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Média da nota geral por mês/ano, em ordem cronológica.
class _MonthlyEvolution extends StatelessWidget {
  final List<Audit> audits;
  const _MonthlyEvolution({required this.audits});

  @override
  Widget build(BuildContext context) {
    final sums = <String, double>{};
    final counts = <String, int>{};
    final order = <String>[];

    final sorted = [...audits]..sort((a, b) => a.data.compareTo(b.data));
    for (final a in sorted) {
      final nota = a.notaGeral;
      if (nota == null) continue;
      final key = '${a.mesReferencia}/${a.data.year}';
      if (!order.contains(key)) order.add(key);
      sums[key] = (sums[key] ?? 0) + nota;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    if (order.isEmpty) {
      return Text('Sem notas suficientes para calcular a evolução.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5));
    }

    return Column(
      children: order.map((key) {
        final media = sums[key]! / counts[key]!;
        final color = AppTheme.colorForScore(media);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(width: 90, child: Text(key, style: const TextStyle(fontSize: 12.5))),
              Expanded(
                child: LinearPercentIndicator(
                  lineHeight: 14,
                  percent: (media / 5).clamp(0, 1),
                  backgroundColor: Colors.grey.shade200,
                  progressColor: color,
                  barRadius: const Radius.circular(6),
                  padding: EdgeInsets.zero,
                  trailing: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(media.toStringAsFixed(2),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
