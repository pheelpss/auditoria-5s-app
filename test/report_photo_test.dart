import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:auditoria_5s/utils/report_photo.dart';

void main() {
  test('JPEG de 12 megapixels mantém exatamente os bytes e a resolução', () {
    final source = img.encodeJpg(img.Image(width: 4000, height: 3000));
    final photo = ReportPhoto.prepare(source)!;
    expect(photo.extension, 'jpg');
    expect(photo.width, 4000);
    expect(photo.height, 3000);
    expect(photo.bytes, orderedEquals(source));
  });

  test('PNG mantém bytes, transparência e resolução original', () {
    final source = img.encodePng(
      img.Image(width: 1600, height: 1200, numChannels: 4),
    );
    final photo = ReportPhoto.prepare(source)!;
    expect(photo.extension, 'png');
    expect(photo.width, 1600);
    expect(photo.height, 1200);
    expect(photo.bytes, orderedEquals(source));
  });

  for (var orientation = 2; orientation <= 8; orientation++) {
    test('orientação EXIF $orientation preserva os pixels decodificados', () {
      final original = img.Image(width: 120, height: 80);
      for (var y = 0; y < original.height; y++) {
        for (var x = 0; x < original.width; x++) {
          original.setPixelRgb(x, y, x * 2, y * 3, (x + y) % 256);
        }
      }
      original.exif.imageIfd.orientation = orientation;
      final source = img.encodeJpg(original, quality: 95);
      expect(img.decodeJpgExif(source)?.imageIfd.orientation, orientation);
      final expected = img.decodeJpg(source)!;
      final photo = ReportPhoto.prepare(source)!;
      final actual = img.decodePng(photo.bytes)!;
      expect(photo.extension, 'png');
      expect(photo.width, orientation >= 5 ? 80 : 120);
      expect(photo.height, orientation >= 5 ? 120 : 80);
      expect(actual.getBytes(), orderedEquals(expected.getBytes()));
      expect(actual.exif.imageIfd.orientation, anyOf(isNull, 1));
    });
  }

  test('BMP é convertido em PNG sem perder pixels ou resolução', () {
    final original = img.Image(width: 1300, height: 1000);
    original.setPixelRgb(15, 24, 20, 80, 210);
    final source = img.encodeBmp(original);
    final photo = ReportPhoto.prepare(source)!;
    expect(photo.extension, 'png');
    expect(photo.width, 1300);
    expect(photo.height, 1000);
    expect(
      img.decodePng(photo.bytes)!.getBytes(),
      orderedEquals(img.decodeBmp(source)!.getBytes()),
    );
  });

  test('arquivo não reconhecido não derruba o gerador', () {
    expect(ReportPhoto.prepare(Uint8List.fromList([1, 2, 3])), isNull);
    expect(ReportPhoto.prepare(Uint8List(0)), isNull);
  });
}
