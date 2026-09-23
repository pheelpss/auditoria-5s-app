import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/constants/five_s_data.dart';
import '../../core/constants/setores.dart';
import '../providers/audit_provider.dart';

/// Formulário do cabeçalho da auditoria: responsável, área, auditor,
/// acompanhante, data e mês de referência. Todos os campos são editáveis
/// por toque.
class HeaderForm extends StatefulWidget {
  const HeaderForm({super.key});

  @override
  State<HeaderForm> createState() => _HeaderFormState();
}

class _HeaderFormState extends State<HeaderForm> {
  late final TextEditingController _responsavel;
  late final TextEditingController _auditor;
  late final TextEditingController _acompanhante;

  @override
  void initState() {
    super.initState();
    final audit = context.read<AuditProvider>().current!;
    _responsavel = TextEditingController(text: audit.responsavel);
    _auditor = TextEditingController(text: audit.auditor);
    _acompanhante = TextEditingController(text: audit.acompanhante);
  }

  @override
  void dispose() {
    _responsavel.dispose();
    _auditor.dispose();
    _acompanhante.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditProvider>();
    final audit = provider.current!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dados da Auditoria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _responsavel,
              decoration: const InputDecoration(labelText: 'Nome do Responsável'),
              onChanged: (v) => provider.updateHeader(responsavel: v),
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Área/Seção Auditada'),
              child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                value: areaConhecida(audit.area),
                isExpanded: true,
                hint: const Text('Selecione uma área'),
                items: [
                const DropdownMenuItem<String>(enabled: false, child: Text('ADMINISTRATIVO')),
                ...setoresAdministrativos.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                const DropdownMenuItem<String>(enabled: false, child: Text('PRODUÇÃO')),
                ...setoresProducao.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                ],
                onChanged: (value) async {
                if (value == null || value == audit.area) return;
                if (audit.items.any((item) => item.score != null)) {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Alterar área auditada?'),
                      content: const Text('As notas das perguntas atuais serão apagadas para carregar o checklist da nova área.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
                        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Alterar área')),
                      ],
                    ),
                  );
                  if (confirm != true || !mounted) return;
                }
                provider.updateHeader(area: value);
                await provider.saveCurrent();
                },
              )),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _auditor,
              decoration: const InputDecoration(labelText: 'Nome do Auditor(a)'),
              onChanged: (v) => provider.updateHeader(auditor: v),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _acompanhante,
              decoration: const InputDecoration(labelText: 'Nome do Acompanhante da Área'),
              onChanged: (v) => provider.updateHeader(acompanhante: v),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: audit.data,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) provider.updateHeader(data: picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Data da Auditoria'),
                child: Text(DateFormat('dd/MM/yyyy').format(audit.data)),
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: audit.mesReferencia,
              decoration: const InputDecoration(labelText: 'Mês de Referência'),
              items: mesesReferencia
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) {
                if (v != null) provider.updateHeader(mesReferencia: v);
              },
            ),
          ],
        ),
      ),
    );
  }
}
