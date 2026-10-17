import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/entities/evidence.dart';
import 'photo_optimizer.dart';

class EvidencePhotoStore {
  static const _folder = 'evidence-photos-v1';

  static Future<File> saveCaptured(String sourcePath, String id) async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(documents.path, _folder));
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, '${_safeId(id)}.jpg'));
    final bytes = await compute(
      optimizePhoto,
      await File(sourcePath).readAsBytes(),
    );
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<File> forReport(Evidence evidence) async {
    final source = File(evidence.filePath);
    final documents = await getApplicationDocumentsDirectory();
    final optimizedDirectory = p.join(documents.path, _folder);
    if (p.equals(
      p.dirname(source.absolute.path),
      p.absolute(optimizedDirectory),
    )) {
      return source;
    }
    // Evidências anteriores à atualização recebem uma cópia temporária leve.
    // O cache muda quando o arquivo muda e evita recomprimir a cada relatório.
    final stat = await source.stat();
    final temporary = await getTemporaryDirectory();
    final directory = Directory(
      p.join(temporary.path, 'ondexa-photo-cache-v1'),
    );
    final key =
        '${_safeId(evidence.id)}_${stat.size}_${stat.modified.microsecondsSinceEpoch}';
    final cached = File(p.join(directory.path, '$key.jpg'));
    if (await cached.exists()) return cached;
    final bytes = await compute(optimizePhoto, await source.readAsBytes());
    await directory.create(recursive: true);
    await cached.writeAsBytes(bytes, flush: true);
    return cached;
  }

  static String _safeId(String id) =>
      id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}
