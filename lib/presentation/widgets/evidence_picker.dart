import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/evidence.dart';
import '../screens/evidence_gallery_screen.dart';

/// Área global de "Evidências": permite tirar foto, escolher da
/// galeria ou anexar arquivos, mostra miniaturas e permite gerenciar
/// tudo de forma centralizada.
class EvidencePicker extends StatelessWidget {
  final List<Evidence> evidences;
  final Function(List<Evidence>) onChanged;

  const EvidencePicker({
    super.key,
    required this.evidences,
    required this.onChanged,
  });

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source, imageQuality: 80);
    if (xfile == null) return;
    
    final newEvidence = Evidence(
      id: const Uuid().v4(),
      categoryCode: 'GLOBAL',
      filePath: xfile.path,
      fileName: xfile.name,
      type: EvidenceType.photo,
    );
    
    final updatedList = List<Evidence>.from(evidences)..add(newEvidence);
    onChanged(updatedList);
  }

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = result.files.single;
    
    final newEvidence = Evidence(
      id: const Uuid().v4(),
      categoryCode: 'GLOBAL',
      filePath: file.path!,
      fileName: file.name,
      type: EvidenceType.file,
    );
    
    final updatedList = List<Evidence>.from(evidences)..add(newEvidence);
    onChanged(updatedList);
  }
  
  void _openPhoto(BuildContext context, Evidence selected) {
    final photos = evidences.where((e) => e.type == EvidenceType.photo).toList();
    final index = photos.indexWhere((e) => e.id == selected.id);
    if (index < 0) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => EvidenceGalleryScreen(photos: photos, initialIndex: index),
    ));
  }

  void _removeEvidence(String id) {
    final updatedList = evidences.where((e) => e.id != id).toList();
    onChanged(updatedList);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              label: 'Arquivo',
              onTap: () => _pickFile(context),
            ),
          ],
        ),
        if (evidences.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: evidences
                .map((ev) => _EvidenceThumb(
                      evidence: ev,
                      onOpen: () => _openPhoto(context, ev),
                      onRemove: () => _removeEvidence(ev.id),
                    ))
                .toList(),
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
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
    );
  }
}

class _EvidenceThumb extends StatelessWidget {
  final Evidence evidence;
  final VoidCallback onRemove;
  final VoidCallback onOpen;
  
  const _EvidenceThumb({required this.evidence, required this.onRemove, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade200,
          ),
          clipBehavior: Clip.antiAlias,
          child: evidence.type == EvidenceType.photo
              ? Semantics(
                  button: true,
                  label: 'Ampliar foto ${evidence.fileName}',
                  child: GestureDetector(
                    onTap: onOpen,
                    behavior: HitTestBehavior.opaque,
                    child: Image.file(File(evidence.filePath), fit: BoxFit.cover,
                      cacheWidth: 240,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Colors.grey),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.insert_drive_file, size: 24, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          evidence.fileName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        Positioned(
          top: -4,
          right: -4,
          child: InkWell(
            onTap: onRemove,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.red,
              child: Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
