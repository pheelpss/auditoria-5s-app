import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/five_s_data.dart';
import '../domain/entities/audit.dart';
import '../domain/entities/evidence.dart';

/// Gera um relatório .DOCX profissional a partir de uma [Audit], sem
/// depender de nenhum template pré-existente: monta o pacote OOXML
/// (Office Open XML) manualmente — documento + tabelas + imagens
/// embutidas — e o compacta com [ArchiveEncoder].
class DocxGenerator {
  static Future<File> generate(Audit audit) async {
    final builder = _DocxBuilder();

    builder.addTitle('RELATÓRIO DE AUDITORIA 5S');
    builder.addSubtitle(audit.area);

    builder.addKeyValueTable({
      'Responsável': audit.responsavel,
      'Área/Seção Auditada': audit.area,
      'Auditor(a)': audit.auditor,
      'Acompanhante da Área': audit.acompanhante,
      'Data da Auditoria': DateFormat('dd/MM/yyyy').format(audit.data),
      'Mês de Referência': audit.mesReferencia,
    });

    builder.addSpacer();

    for (final cat in fiveSCategories) {
      final media = audit.averageForCategory(cat.code);
      builder.addHeading(cat.displayTitle);

      final rows = <List<String>>[
        ['Item', 'Pergunta', 'Nota'],
      ];
      for (final item in audit.itemsFor(cat.code)) {
        rows.add([item.number, item.question, item.score?.toString() ?? '-']);
      }
      builder.addTable(rows, colWidthsPercent: [8, 76, 16]);

      builder.addParagraph(
        'Resultado do ${cat.code}: ${media != null ? media.toStringAsFixed(2) : '-'}',
        bold: true,
      );

      final evidences = audit.evidencesFor(cat.code).where((e) => e.type == EvidenceType.photo);
      if (evidences.isNotEmpty) {
        builder.addParagraph('Evidências fotográficas:', bold: true);
        for (final ev in evidences) {
          final file = File(ev.filePath);
          if (await file.exists()) {
            builder.addImage(await file.readAsBytes());
          }
        }
      }

      final files = audit.evidencesFor(cat.code).where((e) => e.type == EvidenceType.file);
      if (files.isNotEmpty) {
        builder.addParagraph(
          'Anexos: ${files.map((f) => f.fileName).join(', ')}',
        );
      }

      builder.addSpacer();
    }

    final nota = audit.notaGeral;
    builder.addHeading('RESULTADO FINAL');
    builder.addParagraph(
      'Nota Geral 5S: ${nota != null ? nota.toStringAsFixed(2) : '-'}',
      bold: true,
      sizePt: 28,
    );
    builder.addParagraph('Classificação: ${audit.classificacao}', bold: true, sizePt: 28);

    if (audit.comentarios.trim().isNotEmpty) {
      builder.addSpacer();
      builder.addHeading('Comentários');
      builder.addParagraph(audit.comentarios);
    }

    final bytes = builder.build();

    final dir = await getApplicationDocumentsDirectory();
    final safeArea = audit.area.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
    final fileName =
        'Auditoria5S_${safeArea}_${DateFormat('yyyyMMdd_HHmm').format(audit.data)}.docx';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}

/// Construtor mínimo de pacotes OOXML (.docx). Não pretende cobrir todo o
/// padrão Word — apenas o suficiente para títulos, parágrafos, tabelas e
/// imagens em um layout corporativo simples.
class _DocxBuilder {
  final StringBuffer _body = StringBuffer();
  final List<_ImagePart> _images = [];
  int _imgCounter = 0;

  void addTitle(String text) {
    _body.write(_paragraphXml(text, bold: true, sizePt: 36, color: '0B5FA5', align: 'center'));
  }

  void addSubtitle(String text) {
    _body.write(_paragraphXml(text, bold: false, sizePt: 22, color: '555555', align: 'center'));
  }

  void addHeading(String text) {
    _body.write(_paragraphXml(text, bold: true, sizePt: 24, color: '0B5FA5'));
  }

  void addParagraph(String text, {bool bold = false, int sizePt = 20}) {
    _body.write(_paragraphXml(text, bold: bold, sizePt: sizePt));
  }

  void addSpacer() => _body.write(_paragraphXml('', sizePt: 8));

  void addKeyValueTable(Map<String, String> data) {
    final rows = data.entries.map((e) => [e.key, e.value]).toList();
    addTable(rows, colWidthsPercent: [35, 65], header: false, boldFirstCol: true);
  }

  void addTable(
    List<List<String>> rows, {
    required List<int> colWidthsPercent,
    bool header = true,
    bool boldFirstCol = false,
  }) {
    final buffer = StringBuffer();
    buffer.write('<w:tbl>');
    buffer.write('''
      <w:tblPr>
        <w:tblW w:w="5000" w:type="pct"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="4" w:color="C9CED4"/>
          <w:left w:val="single" w:sz="4" w:color="C9CED4"/>
          <w:bottom w:val="single" w:sz="4" w:color="C9CED4"/>
          <w:right w:val="single" w:sz="4" w:color="C9CED4"/>
          <w:insideH w:val="single" w:sz="4" w:color="C9CED4"/>
          <w:insideV w:val="single" w:sz="4" w:color="C9CED4"/>
        </w:tblBorders>
      </w:tblPr>
    ''');
    buffer.write('<w:tblGrid>');
    for (final w in colWidthsPercent) {
      buffer.write('<w:gridCol w:w="${w * 50}"/>');
    }
    buffer.write('</w:tblGrid>');

    for (var r = 0; r < rows.length; r++) {
      final isHeaderRow = header && r == 0;
      buffer.write('<w:tr>');
      for (var c = 0; c < rows[r].length; c++) {
        final isBoldCell = isHeaderRow || (boldFirstCol && c == 0);
        buffer.write('<w:tc><w:tcPr><w:tcW w:w="${colWidthsPercent[c] * 50}" w:type="pct"/>');
        if (isHeaderRow) {
          buffer.write('<w:shd w:val="clear" w:fill="0B5FA5"/>');
        }
        buffer.write('</w:tcPr>');
        buffer.write(_paragraphXml(
          rows[r][c],
          bold: isBoldCell,
          sizePt: 18,
          color: isHeaderRow ? 'FFFFFF' : '000000',
        ));
        buffer.write('</w:tc>');
      }
      buffer.write('</w:tr>');
    }
    buffer.write('</w:tbl>');
    _body.write(buffer.toString());
    // Word exige um parágrafo vazio após tabelas em alguns leitores.
    _body.write(_paragraphXml('', sizePt: 4));
  }

  void addImage(Uint8List bytes, {int widthEmu = 4572000, int heightEmu = 3429000}) {
    _imgCounter++;
    final rId = 'rIdImg$_imgCounter';
    final part = _ImagePart(rId: rId, fileName: 'image$_imgCounter.png', bytes: bytes);
    _images.add(part);
    _body.write('''
      <w:p><w:r><w:drawing>
        <wp:inline distT="0" distB="0" distL="0" distR="0">
          <wp:extent cx="$widthEmu" cy="$heightEmu"/>
          <wp:docPr id="$_imgCounter" name="Evidencia$_imgCounter"/>
          <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
            <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
              <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                <pic:nvPicPr>
                  <pic:cNvPr id="$_imgCounter" name="Evidencia$_imgCounter"/>
                  <pic:cNvPicPr/>
                </pic:nvPicPr>
                <pic:blipFill>
                  <a:blip r:embed="$rId" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"/>
                  <a:stretch><a:fillRect/></a:stretch>
                </pic:blipFill>
                <pic:spPr>
                  <a:xfrm><a:off x="0" y="0"/><a:ext cx="$widthEmu" cy="$heightEmu"/></a:xfrm>
                  <a:prstGeom prst="rect"><a:avLst/></a:prstGeom>
                </pic:spPr>
              </pic:pic>
            </a:graphicData>
          </a:graphic>
        </wp:inline>
      </w:drawing></w:r></w:p>
    ''');
  }

  String _paragraphXml(
    String text, {
    bool bold = false,
    int sizePt = 20,
    String color = '000000',
    String align = 'left',
  }) {
    final escaped = _escapeXml(text);
    final b = bold ? '<w:b/>' : '';
    final halfPoints = sizePt * 2;
    return '''
      <w:p>
        <w:pPr><w:jc w:val="$align"/></w:pPr>
        <w:r>
          <w:rPr>$b<w:sz w:val="$halfPoints"/><w:color w:val="$color"/></w:rPr>
          <w:t xml:space="preserve">$escaped</w:t>
        </w:r>
      </w:p>
    ''';
  }

  String _escapeXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  Uint8List build() {
    final archive = Archive();

    void addText(String path, String content) {
      final bytes = Uint8List.fromList(utf8.encode(content));
      archive.addFile(ArchiveFile(path, bytes.length, bytes));
    }

    addText('[Content_Types].xml', _contentTypesXml());
    addText('_rels/.rels', _rootRelsXml());
    addText('word/_rels/document.xml.rels', _documentRelsXml());
    addText('word/document.xml', _documentXml());

    for (final img in _images) {
      archive.addFile(ArchiveFile('word/media/${img.fileName}', img.bytes.length, img.bytes));
    }

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData!);
  }

  String _contentTypesXml() {
    final imgOverrides = _images.isEmpty
        ? ''
        : '<Default Extension="png" ContentType="image/png"/>';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  $imgOverrides
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
  }

  String _rootRelsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  String _documentRelsXml() {
    final rels = _images
        .map((img) =>
            '<Relationship Id="${img.rId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/${img.fileName}"/>')
        .join('\n');
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  $rels
</Relationships>''';
  }

  String _documentXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
            xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
            xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main"
            xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <w:body>
    ${_body.toString()}
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134"/>
    </w:sectPr>
  </w:body>
</w:document>''';
}

class _ImagePart {
  final String rId;
  final String fileName;
  final Uint8List bytes;
  _ImagePart({required this.rId, required this.fileName, required this.bytes});
}
