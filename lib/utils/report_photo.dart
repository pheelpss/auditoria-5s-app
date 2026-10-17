import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Insere a foto já otimizada no Word sem outra compressão com perdas.
class ReportPhoto {
  final Uint8List bytes;
  final String extension;
  final int width;
  final int height;

  const ReportPhoto(this.bytes, this.extension, this.width, this.height);

  static ReportPhoto? prepare(Uint8List source) {
    try {
      final decoder = img.findDecoderForData(source);
      if (decoder == null) return null;

      // JPEG/PNG comuns: basta ler as dimensões. Os bytes recebidos entram
      // inteiros no DOCX, evitando decodificar novamente os pixels.
      if (decoder is img.JpegDecoder) {
        final orientation = img.decodeJpgExif(source)?.imageIfd.orientation;
        if (orientation == null || orientation == 1) {
          final info = decoder.startDecode(source);
          if (info != null && info.width > 0 && info.height > 0) {
            return ReportPhoto(source, 'jpg', info.width, info.height);
          }
        }
      } else if (decoder is img.PngDecoder) {
        final info = decoder.startDecode(source);
        if (info != null && info.width > 0 && info.height > 0) {
          return ReportPhoto(source, 'png', info.width, info.height);
        }
      }

      // O decoder JPEG aplica EXIF antes de devolver os pixels. Os demais
      // formatos passam por bakeOrientation. PNG mantém todos esses pixels,
      // sem a perda de uma segunda codificação JPEG e sem redimensionamento.
      final decoded = decoder.decode(source);
      if (decoded == null) return null;
      final oriented = img.bakeOrientation(decoded);
      return ReportPhoto(
        Uint8List.fromList(img.encodePng(oriented)),
        'png',
        oriented.width,
        oriented.height,
      );
    } catch (_) {
      return null;
    }
  }
}
