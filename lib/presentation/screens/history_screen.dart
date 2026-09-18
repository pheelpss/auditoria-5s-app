import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/audit.dart';
import '../../domain/repositories/audit_repository.dart';
import '../providers/audit_provider.dart';
import 'audit_form_screen.dart';

/// Tela de histórico: lista as auditorias já salvas, com filtros por mês,
/// ano, área e auditor.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditProvider>().loadHistory();
    });
  }

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
                const Text('Filtrar auditorias', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
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
        title: const Text('Auditorias 5S'),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt_outlined), onPressed: _openFilters),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : audits.isEmpty
              ? const _EmptyState()
              : RefreshIndicator(
                  onRefresh: () => provider.loadHistory(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 90),
                    itemCount: audits.length,
                    itemBuilder: (ctx, i) => _AuditTile(audit: audits[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          provider.startNewAudit();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditFormScreen()));
        },
        icon: const Icon(Icons.add),
        label: const Text('Nova Auditoria'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Nenhuma auditoria encontrada', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Toque em "Nova Auditoria" para começar',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final Audit audit;
  const _AuditTile({required this.audit});

  @override
  Widget build(BuildContext context) {
    final nota = audit.notaGeral;
    final color = nota != null ? AppTheme.colorForScore(nota) : Colors.grey;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text(nota != null ? nota.toStringAsFixed(1) : '-',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        title: Text(audit.area.isEmpty ? '(Área não informada)' : audit.area,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${audit.auditor} · ${audit.mesReferencia} · ${DateFormat('dd/MM/yyyy').format(audit.data)}\n${audit.classificacao}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Excluir auditoria?'),
                content: const Text('Esta ação não pode ser desfeita.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              context.read<AuditProvider>().deleteAudit(audit.id);
            }
          },
        ),
        onTap: () {
          context.read<AuditProvider>().editAudit(audit);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditFormScreen()));
        },
      ),
    );
  }
}
