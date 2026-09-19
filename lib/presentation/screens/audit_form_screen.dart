import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../../utils/docx_generator.dart';
import '../providers/audit_provider.dart';
import '../widgets/category_section.dart';
import '../widgets/evidence_picker.dart';
import '../widgets/header_form.dart';
import '../widgets/score_indicator.dart';
import 'audit_preview_screen.dart';

/// Tela principal de preenchimento de uma auditoria 5S: cabeçalho,
/// categorias com checklist e evidências, nota geral e ações de
/// salvar / gerar relatório Word.
class AuditFormScreen extends StatelessWidget {
  const AuditFormScreen({super.key});

  Future<void> _gerarRelatorio(BuildContext context) async {
    final provider = context.read<AuditProvider>();
    final audit = provider.current!;
    final messenger = ScaffoldMessenger.of(context);

    // Salva automaticamente antes de gerar o relatório
    await provider.saveCurrent();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final file = await DocxGenerator.generate(audit, previousAudit: provider.previous);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audit = provider.current!;

    // PopScope intercepta quando o usuário sai da tela e salva como rascunho.
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        // SALVAMENTO AUTOMÁTICO: Salva os dados ao sair da tela
        provider.saveCurrent();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Auditoria 5S', style: TextStyle(fontSize: 18)),
          // Botão manual de salvar foi removido para incentivar o auto-save
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 100), // Espaçamento reduzido
          children: [
            const HeaderForm(),
            const SizedBox(height: 4),
            
            // Loop de categorias (1S ao 5S)
            for (final cat in fiveSCategories) CategorySection(category: cat),
            
            const SizedBox(height: 8),
            
            // --- NOVA SEÇÃO ÚNICA DE EVIDÊNCIAS ---
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Evidências da Auditoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'Tire fotos ou anexe arquivos e PDFs gerais desta auditoria aqui.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    EvidencePicker(
                      evidences: audit.globalEvidences,
                      onChanged: (updated) {
                        audit.globalEvidences = updated;
                        provider.saveCurrent(); // Auto-save ao adicionar/remover foto
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),

            Card(
              margin: EdgeInsets.zero,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Resultado Geral', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 8),
                    ScoreIndicator(label: 'Nota Geral 5S', score: audit.notaGeral, big: true),
                    if (provider.previousNotaGeral != null) ...[
                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
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
              decoration: const InputDecoration(
                labelText: 'Comentários (opcional)', 
                isDense: true,
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: audit.comentarios),
              onChanged: (v) {
                provider.updateHeader(comentarios: v);
                provider.saveCurrent(); // Auto-save enquanto digita
              },
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
      ),
    );
  }
}
