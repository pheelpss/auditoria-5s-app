import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../core/constants/five_s_data.dart';
import '../domain/entities/audit.dart';
import '../domain/entities/evidence.dart';

/// Gera um relatório .DOCX profissional a partir de uma [Audit], no
/// padrão do formulário físico "PROGRAMA 5S - ÁREAS FABRIS": tabela
/// compacta por senso, com pergunta + nota lado a lado e linha de
/// resultado destacada, seguida das evidências fotográficas com a
/// orientação e proporção corretas.
class DocxGenerator {
  static Future<File> generate(Audit audit, {Audit? previousAudit}) async {
    final builder = _DocxBuilder();

    builder.addTitle('PROGRAMA 5S - ÁREAS FABRIS');
    builder.addSpacerSmall();

    builder.addHeaderInfo([
      _Field('Nome do Responsável', audit.responsavel),
      _Field('Área/Seção Auditada', audit.area),
      _Field('Nome do Auditor(a)', audit.auditor),
      _Field('Nome do Acompanhante da Área', audit.acompanhante),
      _Field('Data', DateFormat('dd/MM/yyyy').format(audit.data)),
      _Field('Mês de Referência', audit.mesReferencia),
    ]);

    builder.addSpacerSmall();

    final colunaAnterior = previousAudit != null
        ? 'NOTA ${previousAudit.mesReferencia.substring(0, 3).toUpperCase()}${DateFormat('yy').format(previousAudit.data)}'
        : null;
    final colunaAtual =
        'NOTA ${audit.mesReferencia.substring(0, 3).toUpperCase()}${DateFormat('yy').format(audit.data)}';

    for (final cat in fiveSCategories) {
      final media = audit.averageForCategory(cat.code);
      final mediaAnterior = previousAudit?.averageForCategory(cat.code);
      final rows = <List<String>>[];
      for (final item in audit.itemsFor(cat.code)) {
        final notaAnterior = previousAudit == null
            ? null
            : previousAudit
                .itemsFor(cat.code)
                .firstWhere((i) => i.number == item.number,
                    orElse: () => item)
                .score;
        rows.add([
          '${item.number} ${item.question}',
          if (previousAudit != null) notaAnterior?.toString() ?? '-',
          item.score?.toString() ?? '-',
        ]);
      }
      builder.addCategoryTable(
        title: '${cat.code} - ${cat.title.toUpperCase()} (${cat.senseName})',
        rows: rows,
        resultLabel: 'RESULTADO ${cat.code}',
        resultValue: media != null ? media.toStringAsFixed(2) : '-',
        resultValueAnterior: previousAudit != null
            ? (mediaAnterior != null ? mediaAnterior.toStringAsFixed(2) : '-')
            : null,
        colunaAnteriorLabel: colunaAnterior,
        colunaAtualLabel: colunaAtual,
      );

      final photos = audit.evidencesFor(cat.code).where((e) => e.type == EvidenceType.photo);
      final files = audit.evidencesFor(cat.code).where((e) => e.type == EvidenceType.file);

      if (photos.isNotEmpty || files.isNotEmpty) {
        builder.addSmallLabel('Evidências — ${cat.code}');
        for (final ev in photos) {
          final file = File(ev.filePath);
          if (await file.exists()) {
            final rawBytes = await file.readAsBytes();
            await builder.addImage(rawBytes);
          }
        }
        if (files.isNotEmpty) {
          builder.addSmallText('Anexos: ${files.map((f) => f.fileName).join(', ')}');
        }
      }

      builder.addSpacerSmall();
    }

    final nota = audit.notaGeral;
    final notaAnteriorGeral = previousAudit?.notaGeral;
    builder.addFinalResult(
      notaLabel: 'NOTA 5S (média geral)',
      notaValue: nota != null ? nota.toStringAsFixed(2) : '-',
      classificacao: audit.classificacao,
      notaAnteriorLabel: previousAudit != null ? 'Mês anterior ($colunaAnterior)' : null,
      notaAnteriorValue: previousAudit != null
          ? (notaAnteriorGeral != null ? notaAnteriorGeral.toStringAsFixed(2) : '-')
          : null,
      classificacaoAnterior: previousAudit?.classificacao,
    );

    builder.addLegend();

    if (audit.comentarios.trim().isNotEmpty) {
      builder.addSpacerSmall();
      builder.addSmallLabel('Comentários');
      builder.addSmallText(audit.comentarios);
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

class _Field {
  final String label;
  final String value;
  _Field(this.label, this.value);
}

/// Construtor mínimo de pacotes OOXML (.docx): título, cabeçalho
/// compacto, tabelas de checklist por senso e imagens com proporção e
/// orientação corretas — sem depender de template externo.
class _DocxBuilder {
  static const _fontFamily = 'Calibri';
  static const _borderColor = '000000';
  static const _headerFill = 'D9D9D9';
  static const _resultFill = 'BFBFBF';

  final StringBuffer _body = StringBuffer();
  final List<_ImagePart> _images = [];
  int _imgCounter = 0;

  // ---- Blocos de alto nível ----

  void addTitle(String text) {
    _body.write(_paragraphXml(text, bold: true, sizePt: 16, align: 'center', spacingAfter: 60));
  }

  void addSpacerSmall() => _body.write(_paragraphXml('', sizePt: 4, spacingAfter: 0));

  void addSmallLabel(String text) {
    _body.write(_paragraphXml(text, bold: true, sizePt: 9, spacingAfter: 20, spacingBefore: 40));
  }

  void addSmallText(String text) {
    _body.write(_paragraphXml(text, sizePt: 9, spacingAfter: 40));
  }

  /// Cabeçalho compacto com os campos da auditoria, 2 por linha, como
  /// um mini-formulário (rótulo em negrito seguido do valor).
  void addHeaderInfo(List<_Field> fields) {
    final buffer = StringBuffer();
    buffer.write('<w:tbl>');
    buffer.write(_tblPrXml(borderColor: _borderColor, borderSz: 4));
    buffer.write('<w:tblGrid><w:gridCol w:w="2500"/><w:gridCol w:w="2200"/>'
        '<w:gridCol w:w="2500"/><w:gridCol w:w="2200"/></w:tblGrid>');

    for (var i = 0; i < fields.length; i += 2) {
      buffer.write('<w:tr>');
      buffer.write(_labelValueCells(fields[i]));
      if (i + 1 < fields.length) {
        buffer.write(_labelValueCells(fields[i + 1]));
      } else {
        buffer.write(_emptyCell(2200));
        buffer.write(_emptyCell(2200));
      }
      buffer.write('</w:tr>');
    }
    buffer.write('</w:tbl>');
    _body.write(buffer.toString());
    _body.write(_paragraphXml('', sizePt: 2, spacingAfter: 0));
  }

  String _labelValueCells(_Field f) {
    final buffer = StringBuffer();
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="2500" w:type="dxa"/>'
        '<w:shd w:val="clear" w:fill="$_headerFill"/>'
        '<w:tcMar><w:top w:w="30" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/>'
        '<w:left w:w="60" w:type="dxa"/><w:right w:w="60" w:type="dxa"/></w:tcMar></w:tcPr>');
    buffer.write(_paragraphXml(f.label, bold: true, sizePt: 8, spacingAfter: 0));
    buffer.write('</w:tc>');
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="2200" w:type="dxa"/>'
        '<w:tcMar><w:top w:w="30" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/>'
        '<w:left w:w="60" w:type="dxa"/><w:right w:w="60" w:type="dxa"/></w:tcMar></w:tcPr>');
    buffer.write(_paragraphXml(f.value.isEmpty ? '-' : f.value, sizePt: 9, spacingAfter: 0));
    buffer.write('</w:tc>');
    return buffer.toString();
  }

  String _emptyCell(int width) =>
      '<w:tc><w:tcPr><w:tcW w:w="$width" w:type="dxa"/></w:tcPr>${_paragraphXml('', sizePt: 9, spacingAfter: 0)}</w:tc>';

  /// Tabela de um senso (1S..5S): título mesclado no topo, cabeçalho de
  /// colunas (com o rótulo do mês, se houver comparação), uma linha por
  /// pergunta (pergunta + nota[s]) e a linha de resultado destacada —
  /// igual ao formulário físico de referência.
  void addCategoryTable({
    required String title,
    required List<List<String>> rows,
    required String resultLabel,
    required String resultValue,
    String? resultValueAnterior,
    String? colunaAnteriorLabel,
    required String colunaAtualLabel,
  }) {
    final temAnterior = colunaAnteriorLabel != null;
    final buffer = StringBuffer();
    buffer.write('<w:tbl>');
    buffer.write(_tblPrXml(borderColor: _borderColor, borderSz: 4));
    if (temAnterior) {
      buffer.write('<w:tblGrid><w:gridCol w:w="7400"/><w:gridCol w:w="900"/>'
          '<w:gridCol w:w="900"/></w:tblGrid>');
    } else {
      buffer.write('<w:tblGrid><w:gridCol w:w="8300"/><w:gridCol w:w="900"/></w:tblGrid>');
    }
    final totalWidth = temAnterior ? 9200 : 9200;
    final questionWidth = temAnterior ? 7400 : 8300;

    // Cabeçalho mesclado com o título do senso.
    buffer.write('<w:tr>');
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="$totalWidth" w:type="dxa"/>'
        '<w:gridSpan w:val="${temAnterior ? 3 : 2}"/>'
        '<w:shd w:val="clear" w:fill="$_headerFill"/>'
        '<w:tcMar><w:top w:w="30" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/>'
        '<w:left w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>');
    buffer.write(_paragraphXml(title, bold: true, sizePt: 9.5, spacingAfter: 0));
    buffer.write('</w:tc></w:tr>');

    // Cabeçalho de colunas (Pergunta / Nota mês anterior / Nota mês atual).
    buffer.write('<w:tr>');
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="$questionWidth" w:type="dxa"/>'
        '<w:shd w:val="clear" w:fill="F2F2F2"/>'
        '<w:tcMar><w:top w:w="20" w:type="dxa"/><w:bottom w:w="20" w:type="dxa"/>'
        '<w:left w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>');
    buffer.write(_paragraphXml('', sizePt: 7, spacingAfter: 0));
    buffer.write('</w:tc>');
    if (temAnterior) {
      buffer.write('<w:tc><w:tcPr><w:tcW w:w="900" w:type="dxa"/>'
          '<w:shd w:val="clear" w:fill="F2F2F2"/><w:vAlign w:val="center"/></w:tcPr>');
      buffer.write(_paragraphXml(colunaAnteriorLabel, bold: true, sizePt: 6.5, align: 'center', spacingAfter: 0));
      buffer.write('</w:tc>');
    }
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="900" w:type="dxa"/>'
        '<w:shd w:val="clear" w:fill="F2F2F2"/><w:vAlign w:val="center"/></w:tcPr>');
    buffer.write(_paragraphXml(colunaAtualLabel, bold: true, sizePt: 6.5, align: 'center', spacingAfter: 0));
    buffer.write('</w:tc>');
    buffer.write('</w:tr>');

    for (final row in rows) {
      buffer.write('<w:tr>');
      buffer.write('<w:tc><w:tcPr><w:tcW w:w="$questionWidth" w:type="dxa"/>'
          '<w:tcMar><w:top w:w="30" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/>'
          '<w:left w:w="80" w:type="dxa"/><w:right w:w="60" w:type="dxa"/></w:tcMar></w:tcPr>');
      buffer.write(_paragraphXml(row[0], sizePt: 8.5, spacingAfter: 0));
      buffer.write('</w:tc>');
      if (temAnterior) {
        buffer.write('<w:tc><w:tcPr><w:tcW w:w="900" w:type="dxa"/>'
            '<w:vAlign w:val="center"/></w:tcPr>');
        buffer.write(_paragraphXml(row[1], sizePt: 9, align: 'center', spacingAfter: 0));
        buffer.write('</w:tc>');
      }
      buffer.write('<w:tc><w:tcPr><w:tcW w:w="900" w:type="dxa"/>'
          '<w:vAlign w:val="center"/></w:tcPr>');
      buffer.write(_paragraphXml(row[temAnterior ? 2 : 1], sizePt: 9, bold: true, align: 'center', spacingAfter: 0));
      buffer.write('</w:tc>');
      buffer.write('</w:tr>');
    }

    // Linha de resultado, destacada.
    buffer.write('<w:tr>');
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="$questionWidth" w:type="dxa"/>'
        '<w:shd w:val="clear" w:fill="$_resultFill"/>'
        '<w:tcMar><w:top w:w="30" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/>'
        '<w:left w:w="80" w:type="dxa"/></w:tcMar></w:tcPr>');
    buffer.write(_paragraphXml(resultLabel, bold: true, sizePt: 9, align: 'right', spacingAfter: 0));
    buffer.write('</w:tc>');
    if (temAnterior) {
      buffer.write('<w:tc><w:tcPr><w:tcW w:w="900" w:type="dxa"/>'
          '<w:shd w:val="clear" w:fill="$_resultFill"/><w:vAlign w:val="center"/></w:tcPr>');
      buffer.write(_paragraphXml(resultValueAnterior ?? '-', bold: true, sizePt: 9.5, align: 'center', spacingAfter: 0));
      buffer.write('</w:tc>');
    }
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="900" w:type="dxa"/>'
        '<w:shd w:val="clear" w:fill="$_resultFill"/><w:vAlign w:val="center"/></w:tcPr>');
    buffer.write(_paragraphXml(resultValue, bold: true, sizePt: 9.5, align: 'center', spacingAfter: 0));
    buffer.write('</w:tc>');
    buffer.write('</w:tr>');

    buffer.write('</w:tbl>');
    _body.write(buffer.toString());
    _body.write(_paragraphXml('', sizePt: 2, spacingAfter: 0));
  }

  /// Bloco final com a nota geral, classificação e, se houver, a
  /// comparação com o mês anterior.
  void addFinalResult({
    required String notaLabel,
    required String notaValue,
    required String classificacao,
    String? notaAnteriorLabel,
    String? notaAnteriorValue,
    String? classificacaoAnterior,
  }) {
    final temAnterior = notaAnteriorLabel != null;
    final buffer = StringBuffer();
    buffer.write('<w:tbl>');
    buffer.write(_tblPrXml(borderColor: _borderColor, borderSz: 6));
    if (temAnterior) {
      buffer.write('<w:tblGrid><w:gridCol w:w="3067"/><w:gridCol w:w="3066"/>'
          '<w:gridCol w:w="3067"/></w:tblGrid>');
    } else {
      buffer.write('<w:tblGrid><w:gridCol w:w="4600"/><w:gridCol w:w="4600"/></w:tblGrid>');
    }
    buffer.write('<w:tr>');
    if (temAnterior) {
      buffer.write('<w:tc><w:tcPr><w:tcW w:w="3067" w:type="dxa"/>'
          '<w:shd w:val="clear" w:fill="F2F2F2"/>'
          '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>'
          '<w:left w:w="100" w:type="dxa"/></w:tcMar></w:tcPr>');
      buffer.write(_paragraphXml(notaAnteriorLabel, bold: true, sizePt: 8.5, spacingAfter: 20));
      buffer.write(_paragraphXml(notaAnteriorValue ?? '-', bold: true, sizePt: 16, spacingAfter: 4));
      buffer.write(_paragraphXml(classificacaoAnterior ?? '-', sizePt: 9, spacingAfter: 0));
      buffer.write('</w:tc>');
    }
    final notaWidth = temAnterior ? 3066 : 4600;
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="$notaWidth" w:type="dxa"/>'
        '<w:shd w:val="clear" w:fill="$_headerFill"/>'
        '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>'
        '<w:left w:w="100" w:type="dxa"/></w:tcMar></w:tcPr>');
    buffer.write(_paragraphXml(notaLabel, bold: true, sizePt: 10, spacingAfter: 20));
    buffer.write(_paragraphXml(notaValue, bold: true, sizePt: 20, spacingAfter: 0));
    buffer.write('</w:tc>');
    final classWidth = temAnterior ? 3067 : 4600;
    buffer.write('<w:tc><w:tcPr><w:tcW w:w="$classWidth" w:type="dxa"/>'
        '<w:shd w:val="clear" w:fill="$_headerFill"/>'
        '<w:tcMar><w:top w:w="80" w:type="dxa"/><w:bottom w:w="80" w:type="dxa"/>'
        '<w:left w:w="100" w:type="dxa"/></w:tcMar></w:tcPr>');
    buffer.write(_paragraphXml('Classificação', bold: true, sizePt: 10, spacingAfter: 20));
    buffer.write(_paragraphXml(classificacao, bold: true, sizePt: 16, spacingAfter: 0));
    buffer.write('</w:tc>');
    buffer.write('</w:tr>');
    buffer.write('</w:tbl>');
    _body.write(buffer.toString());
    _body.write(_paragraphXml('', sizePt: 4, spacingAfter: 0));
  }

  /// Legenda de classificação (0 Muito Ruim ... 5 Atende Plenamente),
  /// igual à do formulário físico.
  void addLegend() {
    const legendaEsq = ['0  Muito Ruim', '1  Ruim', '2  Regular'];
    const legendaDir = ['3  Bom', '4  Muito Bom', '5  Atende Plenamente'];
    for (var i = 0; i < 3; i++) {
      _body.write(_twoColLineXml(legendaEsq[i], legendaDir[i]));
    }
  }

  String _twoColLineXml(String left, String right) {
    return '''
      <w:p>
        <w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/>
          <w:tabs><w:tab w:val="left" w:pos="3200"/></w:tabs>
        </w:pPr>
        <w:r><w:rPr><w:rFonts w:ascii="$_fontFamily" w:hAnsi="$_fontFamily"/><w:sz w:val="17"/></w:rPr>
          <w:t xml:space="preserve">${_escapeXml(left)}</w:t>
        </w:r>
        <w:r><w:rPr><w:rFonts w:ascii="$_fontFamily" w:hAnsi="$_fontFamily"/><w:sz w:val="17"/></w:rPr>
          <w:tab/><w:t xml:space="preserve">${_escapeXml(right)}</w:t>
        </w:r>
      </w:p>
    ''';
  }

  // ---- Imagem: proporção e orientação corretas ----

  /// Decodifica a imagem (aplicando a orientação EXIF automaticamente,
  /// como o pacote `image` faz ao decodificar), redimensiona para um
  /// tamanho razoável de arquivo e a insere no documento respeitando a
  /// proporção real (largura x altura) — sem esticar nem deitar fotos
  /// verticais.
  Future<void> addImage(Uint8List rawBytes) async {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(rawBytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) return;

    // Limita o lado maior a 1280px para manter o .docx leve.
    img.Image resized = decoded;
    const maxSide = 1280;
    if (decoded.width > maxSide || decoded.height > maxSide) {
      resized = decoded.width >= decoded.height
          ? img.copyResize(decoded, width: maxSide)
          : img.copyResize(decoded, height: maxSide);
    }
    final jpgBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 78));

    // Largura máxima útil na página (área útil ~ 9200 twips ≈ 16.2cm).
    const maxWidthEmu = 3200000; // ~8.4cm — cabe bem ao lado de outra foto
    final aspect = resized.height / resized.width;
    final widthEmu = maxWidthEmu;
    final heightEmu = (maxWidthEmu * aspect).round();

    _imgCounter++;
    final rId = 'rIdImg$_imgCounter';
    _images.add(_ImagePart(rId: rId, fileName: 'image$_imgCounter.jpg', bytes: jpgBytes));

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

  // ---- Baixo nível ----

  String _tblPrXml({required String borderColor, required int borderSz}) => '''
      <w:tblPr>
        <w:tblW w:w="5000" w:type="pct"/>
        <w:tblBorders>
          <w:top w:val="single" w:sz="$borderSz" w:color="$borderColor"/>
          <w:left w:val="single" w:sz="$borderSz" w:color="$borderColor"/>
          <w:bottom w:val="single" w:sz="$borderSz" w:color="$borderColor"/>
          <w:right w:val="single" w:sz="$borderSz" w:color="$borderColor"/>
          <w:insideH w:val="single" w:sz="$borderSz" w:color="$borderColor"/>
          <w:insideV w:val="single" w:sz="$borderSz" w:color="$borderColor"/>
        </w:tblBorders>
        <w:tblCellMar>
          <w:top w:w="30" w:type="dxa"/><w:bottom w:w="30" w:type="dxa"/>
          <w:left w:w="60" w:type="dxa"/><w:right w:w="60" w:type="dxa"/>
        </w:tblCellMar>
      </w:tblPr>
    ''';

  String _paragraphXml(
    String text, {
    bool bold = false,
    double sizePt = 9,
    String color = '000000',
    String align = 'left',
    int spacingAfter = 20,
    int spacingBefore = 0,
  }) {
    final escaped = _escapeXml(text);
    final b = bold ? '<w:b/>' : '';
    final halfPoints = (sizePt * 2).round();
    return '''
      <w:p>
        <w:pPr>
          <w:spacing w:after="$spacingAfter" w:before="$spacingBefore" w:line="240" w:lineRule="auto"/>
          <w:jc w:val="$align"/>
        </w:pPr>
        <w:r>
          <w:rPr>$b<w:rFonts w:ascii="$_fontFamily" w:hAnsi="$_fontFamily"/><w:sz w:val="$halfPoints"/><w:color w:val="$color"/></w:rPr>
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

    for (final imgPart in _images) {
      archive.addFile(ArchiveFile('word/media/${imgPart.fileName}', imgPart.bytes.length, imgPart.bytes));
    }

    final zipData = ZipEncoder().encode(archive);
    return Uint8List.fromList(zipData!);
  }

  String _contentTypesXml() {
    final hasJpg = _images.any((i) => i.fileName.endsWith('.jpg'));
    final jpgOverride = hasJpg ? '<Default Extension="jpg" ContentType="image/jpeg"/>' : '';
    return '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  $jpgOverride
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';
  }

  String _rootRelsXml() => '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

  String _documentRelsXml() {
    final rels = _images
        .map((imgPart) =>
            '<Relationship Id="${imgPart.rId}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/${imgPart.fileName}"/>')
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
      <w:pgMar w:top="850" w:right="850" w:bottom="850" w:left="850"/>
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
