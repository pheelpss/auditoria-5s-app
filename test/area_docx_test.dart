import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:xml/xml.dart';
import 'package:auditoria_5s/core/constants/setores.dart';
import 'package:auditoria_5s/domain/entities/audit.dart';
import 'package:auditoria_5s/domain/entities/audit_item.dart';
import 'package:auditoria_5s/domain/entities/evidence.dart';
import 'package:auditoria_5s/utils/docx_generator.dart';
import 'package:auditoria_5s/utils/evidence_photo_store.dart';

Audit reportAudit(String area) => Audit(
  id: 'report-$area',
  responsavel: 'Responsável de teste',
  area: area,
  auditor: 'Auditor de teste',
  acompanhante: 'Acompanhante de teste',
  data: DateTime(2026, 10, 16),
  mesReferencia: 'Outubro',
);

XmlDocument documentXml(Archive archive) => XmlDocument.parse(
  utf8.decode(archive.findFile('word/document.xml')!.content as List<int>),
);

List<String> textNodes(XmlDocument document) => document.descendants
    .whereType<XmlElement>()
    .where((e) => e.name.local == 't')
    .map((e) => e.innerText)
    .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('ondexa-docx-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => directory.path);
  });
  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await directory.delete(recursive: true);
  });

  test(
    'all 32 reports include every area question and the existing summary',
    () async {
      for (final area in setoresAuditaveis) {
        final audit = reportAudit(area);
        for (final item in audit.items) {
          item.score = 4;
        }
        final file = await DocxGenerator.generate(audit);
        final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
        final document = documentXml(archive);
        final text = textNodes(document);
        expect(text, contains('PROGRAMA 5S'));
        expect(text, contains(area));
        for (final label in [
          'Nome do Responsável',
          'Área/Seção Auditada',
          'Nome do Auditor(a)',
          'Nome do Acompanhante da Área',
          'Data',
          'Mês de Referência',
        ]) {
          expect(text, contains(label));
        }
        final questions = text
            .where((t) => RegExp(r'^[1-5]\.\d+ ').hasMatch(t))
            .toList();
        expect(
          questions,
          audit.items.map((i) => '${i.number} ${i.question}').toList(),
        );
        expect(text, contains('MÉDIA GERAL DA AUDITORIA: '));
        expect(text, contains('4.00'));
        expect(text, contains('MUITO BOM'));
        expect(text.join(), contains('Atende Plenamente'));
        expect(text, isNot(contains('EVIDÊNCIAS FOTOGRÁFICAS')));
        expect(
          archive.files.where((f) => f.name.startsWith('word/media/')),
          isEmpty,
        );
      }
    },
  );

  test('historical report uses its saved questions and excludes incompatible comparison', () async {
    final audit = Audit.fromMap(
      reportAudit('QA').toMap(),
      items: [
        AuditItem(
          categoryCode: '1S',
          number: '1.1',
          question: 'Texto histórico preservado',
          score: 2,
        ),
      ],
      evidences: [],
    );
    final file = await DocxGenerator.generate(
      audit,
      previousAudit: reportAudit('QA'),
    );
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final text = textNodes(documentXml(archive));
    expect(text, contains('1.1 Texto histórico preservado'));
    expect(text, isNot(contains('MÊS ANT.')));
    expect(text.where((t) => RegExp(r'^[1-5]\.\d+ ').hasMatch(t)).length, 1);
  });

  test('matching report comparison and photographic evidence keep their existing sections', () async {
    final audit = reportAudit('Almoxarifado');
    final previous = reportAudit('Almoxarifado');
    for (final item in audit.items) {
      item.score = 5;
    }
    for (final item in previous.items) {
      item.score = 3;
    }
    final photo = File('${directory.path}/evidence.png');
    await photo.writeAsBytes(img.encodePng(img.Image(width: 40, height: 20)));
    audit.evidences.add(
      Evidence(
        id: 'photo',
        fileName: 'evidence.png',
        filePath: photo.path,
        type: EvidenceType.photo,
      ),
    );
    final file = await DocxGenerator.generate(audit, previousAudit: previous);
    final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
    final document = documentXml(archive);
    final text = textNodes(document);
    expect(text.where((t) => t == 'MÊS ANT.').length, 5);
    expect(text.where((t) => t == 'MÊS ATUAL').length, 5);
    expect(text, contains('EVIDÊNCIAS FOTOGRÁFICAS'));
    expect(
      text.indexOf('EVIDÊNCIAS FOTOGRÁFICAS'),
      greaterThan(text.indexOf('MÉDIA GERAL DA AUDITORIA: ')),
    );
    expect(
      document.descendants
          .whereType<XmlElement>()
          .where(
            (e) => e.name.local == 'br' && e.getAttribute('w:type') == 'page',
          )
          .length,
      1,
    );
    expect(
      archive.files.where((f) => f.name.startsWith('word/media/')).length,
      1,
    );
  });
  for (var count = 1; count <= 7; count++) {
    test(
      'DOCX com $count fotos reutiliza JPEG otimizado e preserva a grade',
      () async {
        final audit = reportAudit('Teste Titan');
        final originals = <List<int>>[];
        for (var i = 0; i < count; i++) {
          final picture = img.Image(
            width: i.isEven ? 1600 : 1000,
            height: i.isEven ? 1000 : 1600,
          );
          picture.setPixelRgb(100, 100, 30 + i, 70, 190);
          final bytes = i.isEven
              ? img.encodeJpg(picture)
              : img.encodePng(picture);
          // Extensão propositalmente diferente: o formato vem dos bytes.
          final photo = File('${directory.path}/photo$i.data');
          await photo.writeAsBytes(bytes);
          audit.evidences.add(
            Evidence(
              id: 'photo$i',
              fileName: 'photo$i.data',
              filePath: photo.path,
              type: EvidenceType.photo,
            ),
          );
          originals.add(
            await (await EvidencePhotoStore.forReport(audit.evidences.last))
                .readAsBytes(),
          );
        }
        final file = await DocxGenerator.generate(audit);
        final archive = ZipDecoder().decodeBytes(await file.readAsBytes());
        final document = documentXml(archive);
        final media = archive.files
            .where((f) => f.name.startsWith('word/media/'))
            .toList();
        expect(media.length, count);
        final extents = document.descendants
            .whereType<XmlElement>()
            .where((e) => e.name.local == 'extent')
            .toList();
        expect(extents.length, count);
        final widthEmu = (5250000 / (count > 6 ? 4 : 3)).floor();
        for (var i = 0; i < count; i++) {
          expect(media[i].content as List<int>, orderedEquals(originals[i]));
          expect(media[i].name, endsWith('.jpg'));
          expect(extents[i].getAttribute('cx'), '$widthEmu');
          final heightEmu = (widthEmu * (i.isEven ? 1000 / 1600 : 1600 / 1000))
              .round();
          expect(extents[i].getAttribute('cy'), '$heightEmu');
        }
        final relationships = XmlDocument.parse(
          utf8.decode(
            archive.findFile('word/_rels/document.xml.rels')!.content
                as List<int>,
          ),
        );
        final rels = relationships.findAllElements('Relationship').toList();
        expect(
          rels.map((e) => e.getAttribute('Id')).toSet().length,
          rels.length,
        );
        for (final rel in rels) {
          expect(
            archive.findFile('word/${rel.getAttribute('Target')}'),
            isNotNull,
          );
        }
        final types = XmlDocument.parse(
          utf8.decode(
            archive.findFile('[Content_Types].xml')!.content as List<int>,
          ),
        );
        expect(
          types
              .findAllElements('Default')
              .any(
                (e) =>
                    e.getAttribute('Extension') == 'png' &&
                    e.getAttribute('ContentType') == 'image/png',
              ),
          isTrue,
        );
        final settings = XmlDocument.parse(
          utf8.decode(
            archive.findFile('word/settings.xml')!.content as List<int>,
          ),
        );
        expect(
          settings.descendants.whereType<XmlElement>().any(
            (e) => e.name.local == 'doNotAutoCompressPictures',
          ),
          isTrue,
        );
        expect(textNodes(document), contains('Teste Titan'));
      },
    );
  }
}
