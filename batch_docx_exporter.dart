import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/entities/audit.dart';
import '../domain/repositories/audit_repository.dart';
import 'docx_generator.dart';

class BatchExportFailure {
  final String auditId;
  final String area;
  final Object error;

  const BatchExportFailure({
    required this.auditId,
    required this.area,
    required this.error,
  });
}

class BatchExportResult {
  final File zipFile;
  final Uint8List bytes;
  final int generatedCount;
  final int totalCount;
  final List<BatchExportFailure> failures;

  const BatchExportResult({
    required this.zipFile,
    required this.bytes,
    required this.generatedCount,
    required this.totalCount,
    required this.failures,
  });

  String get fileName => p.basename(zipFile.path);
}

/// Gera um pacote ZIP contendo apenas os relatórios DOCX selecionados.
///
/// O mesmo [DocxGenerator] usado na exportação individual é reutilizado aqui
/// para manter o layout e as regras do relatório. Nenhum JSON, banco ou arquivo
/// auxiliar é incluído no pacote.
class BatchDocxExporter {
  static Future<BatchExportResult> generate({
    required List<Audit> audits,
    required AuditRepository repository,
    void Function(int current, int total)? onProgress,
  }) async {
    if (audits.isEmpty) {
      throw ArgumentError('Nenhuma auditoria foi selecionada.');
    }

    final ordered = List<Audit>.from(audits)
      ..sort((a, b) {
        final byDate = a.data.compareTo(b.data);
        if (byDate != 0) return byDate;
        return a.area.toLowerCase().compareTo(b.area.toLowerCase());
      });

    final periodKeys = ordered
        .map((a) => '${a.data.year}|${a.mesReferencia.trim().toLowerCase()}')
        .toSet();
    final samePeriod = periodKeys.length == 1;

    final archive = Archive();
    final usedPaths = <String>{};
    final failures = <BatchExportFailure>[];
    var generatedCount = 0;

    for (var index = 0; index < ordered.length; index++) {
      final audit = ordered[index];
      onProgress?.call(index + 1, ordered.length);

      try {
        Audit? previous = await repository.getPreviousAudit(
          area: audit.area,
          beforeDate: audit.data,
          excludeId: audit.id,
        );
        if (previous != null && !audit.hasSameQuestions(previous)) {
          previous = null;
        }

        final docx = await DocxGenerator.generate(
          audit,
          previousAudit: previous,
        );
        final docxBytes = await docx.readAsBytes();
        final folder = samePeriod
            ? ''
            : '${audit.data.year}/${_safeFolderName(audit.mesReferencia)}/';
        final entryPath = _uniqueArchivePath(
          '$folder${p.basename(docx.path)}',
          usedPaths,
        );

        archive.addFile(
          ArchiveFile(entryPath, docxBytes.length, docxBytes),
        );
        generatedCount++;
      } catch (error) {
        failures.add(
          BatchExportFailure(
            auditId: audit.id,
            area: audit.area.trim().isEmpty ? '(Área não informada)' : audit.area.trim(),
            error: error,
          ),
        );
      }
    }

    if (generatedCount == 0) {
      throw StateError('Não foi possível gerar nenhum dos relatórios selecionados.');
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Não foi possível compactar os relatórios.');
    }
    final zipBytes = Uint8List.fromList(encoded);

    final zipName = samePeriod
        ? 'Relatorios_5S_${_safeFilePart(ordered.first.mesReferencia)}_${ordered.first.data.year}.zip'
        : 'Relatorios_5S_Selecionados.zip';
    final tempDir = await getTemporaryDirectory();
    final zipFile = File(p.join(tempDir.path, zipName));
    await zipFile.writeAsBytes(zipBytes, flush: true);

    return BatchExportResult(
      zipFile: zipFile,
      bytes: zipBytes,
      generatedCount: generatedCount,
      totalCount: ordered.length,
      failures: failures,
    );
  }

  static String _uniqueArchivePath(String desiredPath, Set<String> usedPaths) {
    if (usedPaths.add(desiredPath)) return desiredPath;

    final directory = p.dirname(desiredPath);
    final extension = p.extension(desiredPath);
    final baseName = p.basenameWithoutExtension(desiredPath);
    var counter = 2;

    while (true) {
      final suffix = counter.toString().padLeft(2, '0');
      final candidateName = '${baseName}_$suffix$extension';
      final candidate = directory == '.'
          ? candidateName
          : p.posix.join(directory.replaceAll('\\', '/'), candidateName);
      if (usedPaths.add(candidate)) return candidate;
      counter++;
    }
  }

  static String _safeFolderName(String value) {
    final clean = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_');
    return clean.isEmpty ? 'Sem_mes' : clean;
  }

  static String _safeFilePart(String value) {
    final clean = value.trim().replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ_-]+'), '_');
    return clean.isEmpty ? 'Selecionados' : clean;
  }
}
