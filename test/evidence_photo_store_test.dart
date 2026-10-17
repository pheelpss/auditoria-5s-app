import 'dart:io';

import 'package:archive/archive.dart';
import 'package:auditoria_5s/domain/entities/evidence.dart';
import 'package:auditoria_5s/utils/docx_generator.dart';
import 'package:auditoria_5s/utils/evidence_photo_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import 'area_docx_test.dart' show reportAudit;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ondexa-photo-store-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  test(
    'capture stores only the optimized photo and DOCX reuses its bytes',
    () async {
      final source = File('${directory.path}/camera.png');
      await source.writeAsBytes(
        img.encodePng(img.Image(width: 3000, height: 1500)),
      );
      final stored = await EvidencePhotoStore.saveCaptured(
        source.path,
        'capture',
      );
      final bytes = await stored.readAsBytes();
      final image = img.decodeJpg(bytes)!;
      expect([image.width, image.height], [2560, 1280]);
      expect(stored.parent.listSync().whereType<File>().length, 1);
      final evidence = Evidence(
        id: 'capture',
        filePath: stored.path,
        fileName: 'camera.jpg',
        type: EvidenceType.photo,
      );
      expect((await EvidencePhotoStore.forReport(evidence)).path, stored.path);
      final audit = reportAudit('PCP')..evidences.add(evidence);
      for (var run = 0; run < 2; run++) {
        final report = await DocxGenerator.generate(audit);
        final zip = ZipDecoder().decodeBytes(await report.readAsBytes());
        expect(
          zip.findFile('word/media/image1.jpg')!.content,
          orderedEquals(bytes),
        );
      }
    },
  );

  test('legacy evidence is cached, source stays intact and changed source invalidates cache', () async {
    final source = File('${directory.path}/old.png');
    final original = img.encodePng(img.Image(width: 100, height: 50));
    await source.writeAsBytes(original);
    final evidence = Evidence(
      id: 'legacy',
      filePath: source.path,
      fileName: 'old.png',
      type: EvidenceType.photo,
    );
    final first = await EvidencePhotoStore.forReport(evidence);
    final modified = (await first.stat()).modified;
    final second = await EvidencePhotoStore.forReport(evidence);
    expect(second.path, first.path);
    expect((await second.stat()).modified, modified);
    expect(await source.readAsBytes(), orderedEquals(original));
    await source.writeAsBytes(
      img.encodePng(img.Image(width: 150, height: 100)),
    );
    final changed = await EvidencePhotoStore.forReport(evidence);
    expect(changed.path, isNot(first.path));
    expect(img.decodeJpg(await changed.readAsBytes())!.width, 150);
  });
}
