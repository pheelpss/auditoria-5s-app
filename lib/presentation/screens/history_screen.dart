import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audit_grouping.dart';
import '../../domain/entities/audit.dart';
import '../../domain/repositories/audit_repository.dart';
import '../providers/audit_provider.dart';
import 'audit_form_screen.dart';
import 'indicators_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuditProvider>().loadHistory();
    });

    // 1. Quando o app está totalmente fechado e o usuário clica no arquivo no WhatsApp
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        final path = value.first.path;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AuditProvider>().importFromFilePath(path, context);
        });
      }
    });

    // 2. Quando o app já está em segundo plano e o usuário clica no arquivo no WhatsApp
    _intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        final path = value.first.path;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AuditProvider>().importFromFilePath(path, context);
        });
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
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
                  decoration: const InputDecoration(labelText: 'Mês', isDense: true),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todos')),
                    ...mesesReferencia.map((m) => DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (v) => setModalState(() => mes = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Ano (ex: 2026)', isDense: true),
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(text: ano?.toString() ?? ''),
                  onChanged: (v) => ano = int.tryParse(v),
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Área auditada', isDense: true),
                  controller: areaCtrl,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: const InputDecoration(labelText: 'Auditor', isDense: true),
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
    final grouped = groupAuditsByYearMonthArea(audits);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditorias 5S'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sync_alt_outlined),
            tooltip: 'Sincronizar',
            onSelected: (value) {
              if (value == 'export') {
                provider.exportData(context);
              } else if (value == 'import') {
                provider.importData(context);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Compartilhar Banco'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const PopupMenuItem<String>(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Importar Manualmente'),
                  contentPadding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Indicadores',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IndicatorsScreen()),
            ),
          ),
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
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
                    itemCount: grouped.length,
                    itemBuilder: (ctx, i) => _YearTile(group: grouped[i]),
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

class _YearTile extends StatelessWidget {
  final YearGroup group;
  const _YearTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ExpansionTile(
        initiallyExpanded: group.year == DateTime.now().year,
        visualDensity: VisualDensity.compact,
        leading: const Icon(Icons.calendar_today_outlined, size: 22),
        title: Text('${group.year}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text('${group.totalAudits} auditoria(s)', style: const TextStyle(fontSize: 12)),
        children: group.months.map((m) => _MonthTile(group: m)).toList(),
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final MonthGroup group;
  const _MonthTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      visualDensity: VisualDensity.compact,
      tilePadding: const EdgeInsets.only(left: 24, right: 16),
      leading: const Icon(Icons.event_note_outlined, size: 20),
      title: Text(group.mes, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('${group.totalAudits} auditoria(s)', style: const TextStyle(fontSize: 12)),
      children: group.areas.map((a) => _AreaTile(group: a)).toList(),
    );
  }
}

class _AreaTile extends StatelessWidget {
  final AreaGroup group;
  const _AreaTile({required this.group});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      visualDensity: VisualDensity.compact,
      tilePadding: const EdgeInsets.only(left: 40, right: 16),
      leading: const Icon(Icons.factory_outlined, size: 18),
      title: Text(group.area, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      children: group.audits.map((a) => AuditTile(audit: a)).toList(),
    );
  }
}

class AuditTile extends StatelessWidget {
  final Audit audit;
  const AuditTile({super.key, required this.audit});

  @override
  Widget build(BuildContext context) {
    final nota = audit.notaGeral;
    final color = nota != null ? AppTheme.colorForScore(nota) : Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(left: 32.0, right: 8.0, bottom: 4.0),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        child: ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Text(nota != null ? nota.toStringAsFixed(1) : '-',
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          title: Text(audit.area.isEmpty ? '(Área não informada)' : audit.area,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          subtitle: Text(
            '${audit.auditor} · ${DateFormat('dd/MM/yy').format(audit.data)} · ${audit.classificacao}',
            style: const TextStyle(fontSize: 11),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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
      ),
    );
  }
}
