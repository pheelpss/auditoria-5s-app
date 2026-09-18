import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../../utils/docx_generator.dart';
import '../providers/audit_provider.dart';
import '../widgets/category_section.dart';
import '../widgets/header_form.dart';
import '../widgets/score_indicator.dart';

/// Tela principal de preenchimento de uma auditoria 5S: cabeçalho,
/// categorias com checklist e evidências, nota geral e ações de
/// salvar / gerar relatório Word.
class AuditFormScreen extends StatelessWidget {
  const AuditFormScreen({super.key});

  Future<void> _gerarRelatorio(BuildContext context) async {
    final provider = context.read<AuditProvider>();
    final audit = provider.current!;
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await DocxGenerator.generate(audit, previousAudit: provider.previous);
      await provider.saveCurrent();
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Relatório gerado: ${file.path.split('/').last}'),
          action: SnackBarAction(label: 'Abrir', onPressed: () => OpenFilex.open(file.path)),
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: $e')));
    }
  }

  Future<void> _salvar(BuildContext context) async {
    final provider = context.read<AuditProvider>();
    await provider.saveCurrent();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auditoria salva com sucesso.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audit = provider.current!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auditoria 5S'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Salvar auditoria',
            onPressed: () => _salvar(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 100),
        children: [
          const HeaderForm(),
          const SizedBox(height: 8),
          for (final cat in fiveSCategories) CategorySection(category: cat),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resultado Geral', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  ScoreIndicator(label: 'Nota Geral 5S', score: audit.notaGeral, big: true),
                  if (provider.previousNotaGeral != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 10),
                    ScoreIndicator(
                      label: 'Nota Geral do mês anterior',
                      score: provider.previousNotaGeral,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Comentários (opcional)'),
            controller: TextEditingController(text: audit.comentarios),
            onChanged: (v) => provider.updateHeader(comentarios: v),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: provider.isLoading ? null : () => _gerarRelatorio(context),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Gerar Relatório Word'),
          ),
        ),
      ),
    );
  }
}
