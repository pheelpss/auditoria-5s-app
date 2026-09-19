import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/setores.dart';
import '../../domain/entities/audit.dart';
import '../providers/audit_provider.dart';
import 'audit_form_screen.dart';

/// Tela de Indicadores: mostra, mês a mês, quais setores da lista fixa
/// ainda não foram auditados — tocar num setor pendente já abre uma
/// nova auditoria com a área pré-preenchida. Também lista os setores
/// já auditados para conferência.
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
      appBar: AppBar(title: const Text('Status dos Setores')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24), // Espaçamento reduzido
              itemCount: groups.length,
              itemBuilder: (ctx, i) => _MonthPendingCard(group: groups[i]),
            ),
    );
  }

  /// Monta um grupo por mês/ano separando o que está pendente do que
  /// já foi auditado.
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
      final auditadasLowercase = auditedByKey[key]!;
      
      final pendentes = <String>[];
      final auditados = <String>[];

      for (final setor in setoresAuditaveis) {
        if (auditadasLowercase.contains(setor.trim().toLowerCase())) {
          auditados.add(setor);
        } else {
          pendentes.add(setor);
        }
      }
      
      return _MonthGroup(mes: mes, ano: ano, pendentes: pendentes, auditados: auditados);
    }).toList();
  }
}

class _MonthGroup {
  final String mes;
  final int ano;
  final List<String> pendentes;
  final List<String> auditados;
  
  _MonthGroup({
    required this.mes, 
    required this.ano, 
    required this.pendentes,
    required this.auditados,
  });
}

class _MonthPendingCard extends StatelessWidget {
  final _MonthGroup group;
  const _MonthPendingCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final tudoAuditado = group.pendentes.isEmpty;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 6), // Redução de espaço vertical
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${group.mes}/${group.ano}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
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
            
            // --- SEÇÃO: SETORES PENDENTES ---
            if (group.pendentes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Setores Pendentes', 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6, // Reduzido de 8 para 6
                runSpacing: 6,
                children: group.pendentes.map((setor) {
                  return ActionChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.add_circle_outline, size: 16),
                    label: Text(setor, style: const TextStyle(fontSize: 12)),
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

            // --- SEÇÃO: SETORES AUDITADOS ---
            if (group.auditados.isNotEmpty) ...[
              if (group.pendentes.isNotEmpty) const Divider(height: 20),
              if (group.pendentes.isEmpty) const SizedBox(height: 12),
              
              Text('Setores Auditados', 
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: group.auditados.map((setor) {
                  return Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.check_circle, color: Colors.green, size: 16), // Ícone de ✓
                    label: Text(setor, style: const TextStyle(fontSize: 12)),
                    backgroundColor: Colors.green.shade50,
                    side: BorderSide(color: Colors.green.shade200),
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
