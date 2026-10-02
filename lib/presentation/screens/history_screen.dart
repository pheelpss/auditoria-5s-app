import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/audit_grouping.dart';
import '../../domain/entities/audit.dart';
import '../../domain/repositories/audit_repository.dart';
import '../../utils/batch_docx_exporter.dart';
import '../providers/audit_provider.dart';
import 'audit_form_screen.dart';
import 'indicators_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _selectionMode = false;
  bool _isGeneratingBatch = false;
  int _batchCurrent = 0;
  int _batchTotal = 0;
  final Set<String> _selectedAuditIds = <String>{};

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

  void _startAreaSelection(AreaGroup group) {
    setState(() {
      _selectionMode = true;
      _selectedAuditIds.addAll(group.audits.map((a) => a.id));
    });
  }

  void _toggleAreaSelection(AreaGroup group) {
    final ids = group.audits.map((a) => a.id).toList();
    final allSelected = ids.isNotEmpty && ids.every(_selectedAuditIds.contains);
    setState(() {
      if (allSelected) {
        _selectedAuditIds.removeAll(ids);
      } else {
        _selectedAuditIds.addAll(ids);
      }
    });
  }

  void _toggleSelectAll(List<Audit> audits) {
    final visibleIds = audits.map((a) => a.id).toSet();
    final allSelected = visibleIds.isNotEmpty && visibleIds.every(_selectedAuditIds.contains);
    setState(() {
      if (allSelected) {
        _selectedAuditIds.removeAll(visibleIds);
      } else {
        _selectedAuditIds.addAll(visibleIds);
      }
    });
  }

  void _exitSelectionMode() {
    if (!mounted) return;
    setState(() {
      _selectionMode = false;
      _selectedAuditIds.clear();
      _batchCurrent = 0;
      _batchTotal = 0;
    });
  }

  int _selectedAreaCount(List<YearGroup> grouped) {
    var count = 0;
    for (final year in grouped) {
      for (final month in year.months) {
        for (final area in month.areas) {
          final ids = area.audits.map((a) => a.id).toList();
          if (ids.isNotEmpty && ids.every(_selectedAuditIds.contains)) count++;
        }
      }
    }
    return count;
  }

  Future<void> _generateBatchZip() async {
    final provider = context.read<AuditProvider>();
    final selected = provider.history.where((a) => _selectedAuditIds.contains(a.id)).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma área.')),
      );
      return;
    }

    setState(() {
      _isGeneratingBatch = true;
      _batchCurrent = 0;
      _batchTotal = selected.length;
    });

    try {
      final result = await BatchDocxExporter.generate(
        audits: selected,
        repository: provider.repository,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() {
            _batchCurrent = current;
            _batchTotal = total;
          });
        },
      );

      if (!mounted) return;
      setState(() => _isGeneratingBatch = false);
      await _showZipActions(result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGeneratingBatch = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar o ZIP: $e')),
      );
    }
  }

  Future<void> _showZipActions(BatchExportResult result) async {
    final failedAreas = result.failures.map((f) => f.area).toSet().toList();
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pacote de relatórios pronto',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 6),
              Text('${result.generatedCount} de ${result.totalCount} relatório(s) gerado(s).'),
              if (failedAreas.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Não foi possível gerar: ${failedAreas.join(', ')}.',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.save_alt_outlined),
                title: const Text('Salvar arquivo'),
                subtitle: Text(result.fileName),
                onTap: () => Navigator.pop(ctx, 'save'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.share_outlined),
                title: const Text('Compartilhar'),
                subtitle: const Text('WhatsApp, Drive, e-mail e outros aplicativos'),
                onTap: () => Navigator.pop(ctx, 'share'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == 'save') {
      try {
        final outputPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Salvar pacote de relatórios',
          fileName: result.fileName,
          type: FileType.custom,
          allowedExtensions: const ['zip'],
          bytes: result.bytes,
        );
        if (!mounted || outputPath == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ZIP salvo com sucesso.')),
        );
        _exitSelectionMode();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar o ZIP: $e')),
        );
      }
      return;
    }

    if (action == 'share') {
      try {
        await Share.shareXFiles(
          [XFile(result.zipFile.path)],
          text: 'Relatórios 5S - OnDexa',
        );
        if (!mounted) return;
        _exitSelectionMode();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compartilhar o ZIP: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audits = provider.history;
    final grouped = groupAuditsByYearMonthArea(audits);
    final visibleIds = audits.map((a) => a.id).toList();
    final allVisibleSelected = visibleIds.isNotEmpty && visibleIds.every(_selectedAuditIds.contains);
    final selectedAreaCount = _selectedAreaCount(grouped);

    final historyList = ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 90),
      itemCount: grouped.length,
      itemBuilder: (ctx, i) => _YearTile(
        group: grouped[i],
        selectionMode: _selectionMode,
        selectedAuditIds: _selectedAuditIds,
        onAreaLongPress: _startAreaSelection,
        onAreaToggle: _toggleAreaSelection,
      ),
    );

    final content = provider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : audits.isEmpty
            ? const _EmptyState()
            : Column(
                children: [
                  if (_selectionMode)
                    CheckboxListTile(
                      value: allVisibleSelected,
                      onChanged: (_) => _toggleSelectAll(audits),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      title: const Text('Selecionar todas'),
                      subtitle: Text(
                        '$selectedAreaCount área(s) · ${_selectedAuditIds.length} auditoria(s) selecionada(s)',
                      ),
                    ),
                  Expanded(
                    child: _selectionMode
                        ? historyList
                        : RefreshIndicator(
                            onRefresh: () => provider.loadHistory(),
                            child: historyList,
                          ),
                  ),
                ],
              );

    return WillPopScope(
      onWillPop: () async {
        if (_selectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !_selectionMode,
          leading: _selectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancelar seleção',
                  onPressed: _exitSelectionMode,
                )
              : null,
          title: Text(_selectionMode ? 'Selecionar áreas' : 'Ondexa'),
          actions: _selectionMode
              ? null
              : [
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.sync_alt_outlined),
                    tooltip: 'Sincronizar e Exportar',
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
                          title: Text('Importar Backup (.5s)'),
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
        body: Stack(
          children: [
            Positioned.fill(child: content),
            if (_isGeneratingBatch)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 36),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            const Text(
                              'Gerando relatórios...',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text('$_batchCurrent de $_batchTotal'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: _selectionMode
            ? SafeArea(
                top: false,
                child: Material(
                  elevation: 12,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$selectedAreaCount área(s) selecionada(s)',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _selectedAuditIds.isEmpty || _isGeneratingBatch
                              ? null
                              : _generateBatchZip,
                          icon: const Icon(Icons.folder_zip_outlined),
                          label: const Text('Gerar ZIP'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        floatingActionButton: _selectionMode
            ? null
            : FloatingActionButton.extended(
                onPressed: () {
                  provider.startNewAudit();
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AuditFormScreen()));
                },
                icon: const Icon(Icons.add),
                label: const Text('Nova Auditoria'),
              ),
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
  final bool selectionMode;
  final Set<String> selectedAuditIds;
  final ValueChanged<AreaGroup> onAreaLongPress;
  final ValueChanged<AreaGroup> onAreaToggle;

  const _YearTile({
    required this.group,
    required this.selectionMode,
    required this.selectedAuditIds,
    required this.onAreaLongPress,
    required this.onAreaToggle,
  });

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
        children: group.months
            .map(
              (m) => _MonthTile(
                group: m,
                selectionMode: selectionMode,
                selectedAuditIds: selectedAuditIds,
                onAreaLongPress: onAreaLongPress,
                onAreaToggle: onAreaToggle,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final MonthGroup group;
  final bool selectionMode;
  final Set<String> selectedAuditIds;
  final ValueChanged<AreaGroup> onAreaLongPress;
  final ValueChanged<AreaGroup> onAreaToggle;

  const _MonthTile({
    required this.group,
    required this.selectionMode,
    required this.selectedAuditIds,
    required this.onAreaLongPress,
    required this.onAreaToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: false,
      visualDensity: VisualDensity.compact,
      tilePadding: const EdgeInsets.only(left: 24, right: 16),
      leading: const Icon(Icons.event_note_outlined, size: 20),
      title: Text(group.mes, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text('${group.totalAudits} auditoria(s)', style: const TextStyle(fontSize: 12)),
      children: group.areas
          .map(
            (a) => _AreaTile(
              group: a,
              selectionMode: selectionMode,
              selectedAuditIds: selectedAuditIds,
              onLongPress: onAreaLongPress,
              onToggle: onAreaToggle,
            ),
          )
          .toList(),
    );
  }
}

class _AreaTile extends StatelessWidget {
  final AreaGroup group;
  final bool selectionMode;
  final Set<String> selectedAuditIds;
  final ValueChanged<AreaGroup> onLongPress;
  final ValueChanged<AreaGroup> onToggle;

  const _AreaTile({
    required this.group,
    required this.selectionMode,
    required this.selectedAuditIds,
    required this.onLongPress,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ids = group.audits.map((a) => a.id).toList();
    final selected = ids.isNotEmpty && ids.every(selectedAuditIds.contains);

    if (selectionMode) {
      return ListTile(
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.only(left: 34, right: 16),
        leading: Checkbox(
          value: selected,
          onChanged: (_) => onToggle(group),
        ),
        title: Text(group.area, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        subtitle: Text('${group.audits.length} auditoria(s)', style: const TextStyle(fontSize: 11)),
        onTap: () => onToggle(group),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: () => onLongPress(group),
      child: ExpansionTile(
        initiallyExpanded: true,
        visualDensity: VisualDensity.compact,
        tilePadding: const EdgeInsets.only(left: 40, right: 16),
        leading: const Icon(Icons.factory_outlined, size: 18),
        title: Text(group.area, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        children: group.audits.map((a) => AuditTile(audit: a)).toList(),
      ),
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
