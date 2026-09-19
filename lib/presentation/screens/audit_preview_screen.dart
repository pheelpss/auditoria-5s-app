import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/evidence.dart';
import '../../utils/docx_generator.dart';
import '../providers/audit_provider.dart';

class AuditPreviewScreen extends StatefulWidget {
  const AuditPreviewScreen({super.key});

  @override
  State<AuditPreviewScreen> createState() => _AuditPreviewScreenState();
}

class _AuditPreviewScreenState extends State<AuditPreviewScreen> {
  late TextEditingController _comentariosCtrl;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Puxa os comentários que já existem (se houver) para o campo de texto
    final current = context.read<AuditProvider>().current;
    _comentariosCtrl = TextEditingController(text: current?.comentarios ?? '');
  }

  @override
  void dispose() {
    _comentariosCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateDocx() async {
    final provider = context.read<AuditProvider>();
    final current = provider.current;
    final previous = provider.previous;

    if (current == null) return;

    // 1. Salva os comentários que foram digitados/editados na tela de revisão
    provider.updateHeader(comentarios: _comentariosCtrl.text);
    await provider.saveCurrent();

    // 2. Inicia o loading
    setState(() => _isGenerating = true);

    try {
      // 3. Gera o arquivo Word
      final file = await DocxGenerator.generate(current, previousAudit: previous);
      
      // 4. Compartilha o arquivo gerado
      await Share.shareXFiles(
        [XFile(file.path)], 
        text: 'Relatório 5S - ${current.area}'
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao gerar relatório: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audit = provider.current;
    final previous = provider.previous;

    if (audit == null) return const Scaffold();

    final notaGeral = audit.notaGeral;
    final color = notaGeral != null ? AppTheme.colorForScore(notaGeral) : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revisar Relatório'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. CABEÇALHO ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INFORMAÇÕES DA AUDITORIA', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const Divider(),
                    _InfoRow('Área:', audit.area),
                    _InfoRow('Responsável:', audit.responsavel),
                    _InfoRow('Auditor:', audit.auditor),
                    _InfoRow('Data:', DateFormat('dd/MM/yyyy').format(audit.data)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 2. RESUMO DE NOTAS ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RESULTADOS POR SENSO', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const Divider(),
                    ...fiveSCategories.map((cat) {
                      final media = audit.averageForCategory(cat.code);
                      final mediaAnt = previous?.averageForCategory(cat.code);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${cat.code} - ${cat.title}'),
                            Row(
                              children: [
                                if (mediaAnt != null) ...[
                                  Text(mediaAnt.toStringAsFixed(1), style: const TextStyle(color: Colors.grey)),
                                  const Icon(Icons.arrow_right_alt, size: 16, color: Colors.grey),
                                ],
                                Text(media != null ? media.toStringAsFixed(1) : '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('MÉDIA GERAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            notaGeral != null ? notaGeral.toStringAsFixed(2) : '-',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Classificação: ${audit.classificacao}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 3. COMENTÁRIOS GERAIS (EDITÁVEL) ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('COMENTÁRIOS FINAIS / OBSERVAÇÕES', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _comentariosCtrl,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Adicione observações gerais, pontos fortes, pendências...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 4. PREVIEW DE FOTOS ---
            if (audit.evidences.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EVIDÊNCIAS ANEXADAS (${audit.evidences.length})', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: audit.evidences.map((ev) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ev.type == EvidenceType.photo 
                              ? Image.file(File(ev.filePath), width: 65, height: 65, fit: BoxFit.cover)
                              : Container(
                                  width: 65, height: 65, color: Colors.grey.shade200,
                                  child: const Icon(Icons.insert_drive_file, color: Colors.grey),
                                ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 80), // Espaço pro botão flutuante não tampar o conteúdo
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isGenerating ? null : _generateDocx,
        icon: _isGenerating 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
            : const Icon(Icons.description_outlined),
        label: Text(_isGenerating ? 'Gerando Relatório...' : 'Gerar Arquivo Word'),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value.isEmpty ? '-' : value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
        ],
      ),
    );
  }
}
