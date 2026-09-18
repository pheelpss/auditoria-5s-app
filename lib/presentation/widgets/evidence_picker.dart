import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/evidence.dart';
import '../providers/audit_provider.dart';

/// Área de "Evidências" de uma categoria: permite tirar foto, escolher da
/// galeria ou anexar arquivos (PDF/Word/Excel/outros), mostra miniaturas
/// e permite excluir/substituir anexos.
class EvidencePicker extends StatelessWidget {
  final String categoryCode;
  const EvidencePicker({super.key, required this.categoryCode});

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 80);
    if (xfile == null) return;
    if (!context.mounted) return;
    context.read<AuditProvider>().addEvidence(
          Evidence(
            id: const Uuid().v4(),
            categoryCode: categoryCode,
            filePath: xfile.path,
            fileName: xfile.name,
            type: EvidenceType.photo,
          ),
        );
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    if (!context.mounted) return;
    context.read<AuditProvider>().addEvidence(
          Evidence(
            id: const Uuid().v4(),
            categoryCode: categoryCode,
            filePath: file.path!,
            fileName: file.name,
            type: EvidenceType.file,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final audit = context.watch<AuditProvider>().current!;
    final evidences = audit.evidencesFor(categoryCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Evidências', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ActionChip(
              icon: Icons.photo_camera,
              label: 'Câmera',
              onTap: () => _pickPhoto(context, ImageSource.camera),
            ),
            _ActionChip(
              icon: Icons.photo_library,
              label: 'Galeria',
              onTap: () => _pickPhoto(context, ImageSource.gallery),
            ),
            _ActionChip(
              icon: Icons.attach_file,
              label: 'Anexar arquivo',
              onTap: () => _pickFile(context),
            ),
          ],
        ),
        if (evidences.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: evidences.map((ev) => _EvidenceThumb(evidence: ev)).toList(),
          ),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}

class _EvidenceThumb extends StatelessWidget {
  final Evidence evidence;
  const _EvidenceThumb({required this.evidence});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey.shade200,
          ),
          clipBehavior: Clip.antiAlias,
          child: evidence.type == EvidenceType.photo
              ? Image.file(File(evidence.filePath), fit: BoxFit.cover)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.insert_drive_file, size: 28),
                        Text(
                          evidence.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: InkWell(
            onTap: () => context.read<AuditProvider>().removeEvidence(evidence.id),
            child: const CircleAvatar(
              radius: 11,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
