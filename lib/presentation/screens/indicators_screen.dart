import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/setores.dart';
import '../../domain/entities/audit.dart';
import '../providers/audit_provider.dart';
import 'audit_form_screen.dart';

/// Tela de Indicadores: mostra, mês a mês, quais setores da lista fixa
/// ainda não foram auditados — tocar num setor pendente já abre uma
/// nova auditoria com a área pré-preenchida.
class IndicatorsScreen extends StatefulWidget {
  const IndicatorsScreen({super.key});

  @override
  State<IndicatorsScreen> createState() => _IndicatorsScreenState();
}

class _IndicatorsScreenState extends State<IndicatorsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditProvider>().loadAllAudits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final groups = _buildPendingGroups(provider.allAudits);

    return Scaffold(
      appBar: AppBar(title: const Text('Setores pendentes')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              itemCount: groups.length,
              itemBuilder: (ctx, i) => _MonthPendingCard(group: groups[i]),
            ),
    );
  }

  /// Monta um grupo por mês/ano — todos os que já têm auditoria salva,
  /// mais o mês atual (mesmo que ainda não tenha nenhuma), para o
  /// usuário sempre ver o que falta no mês corrente. Mais recente primeiro.
  List<_MonthGroup> _buildPendingGroups(List<Audit> audits) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final now = DateTime.now();
    final auditedByKey = <String, Set<String>>{};

    for (final a in audits) {
      final key = '${a.mesReferencia}|${a.data.year}';
      auditedByKey.putIfAbsent(key, () => {});
      auditedByKey[key]!.add(a.area.trim().toLowerCase());
    }

    final currentKey = '${meses[now.month - 1]}|${now.year}';
    auditedByKey.putIfAbsent(currentKey, () => {});

    final keys = auditedByKey.keys.toList()
      ..sort((a, b) {
        final pa = a.split('|');
        final pb = b.split('|');
        final anoA = int.parse(pa[1]);
        final anoB = int.parse(pb[1]);
        if (anoA != anoB) return anoB.compareTo(anoA);
        return meses.indexOf(pb[0]).compareTo(meses.indexOf(pa[0]));
      });

    return keys.map((key) {
      final parts = key.split('|');
      final mes = parts[0];
      final ano = int.parse(parts[1]);
      final auditadas = auditedByKey[key]!;
      final pendentes = setoresAuditaveis
          .where((s) => !auditadas.contains(s.trim().toLowerCase()))
          .toList();
      return _MonthGroup(mes: mes, ano: ano, pendentes: pendentes);
    }).toList();
  }
}

class _MonthGroup {
  final String mes;
  final int ano;
  final List<String> pendentes;
  _MonthGroup({required this.mes, required this.ano, required this.pendentes});
}

class _MonthPendingCard extends StatelessWidget {
  final _MonthGroup group;
  const _MonthPendingCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final tudoAuditado = group.pendentes.isEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${group.mes}/${group.ano}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: tudoAuditado ? Colors.green.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: tudoAuditado ? Colors.green.shade300 : Colors.orange.shade300,
                    ),
                  ),
                  child: Text(
                    tudoAuditado ? 'Completo' : '${group.pendentes.length} pendente(s)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: tudoAuditado ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (!tudoAuditado) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.pendentes.map((setor) {
                  return ActionChip(
                    avatar: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(setor, style: const TextStyle(fontSize: 12.5)),
                    onPressed: () {
                      context.read<AuditProvider>().startNewAuditFor(
                            area: setor,
                            mesReferencia: group.mes,
                          );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AuditFormScreen()),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
