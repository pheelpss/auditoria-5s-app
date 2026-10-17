import 'dart:typed_data';

import 'package:auditoria_5s/utils/photo_optimizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  test('12 MP becomes 2560x1920 JPEG with a smaller file', () {
    final original = img.Image(width: 4000, height: 3000);
    for (var y = 0; y < original.height; y++) {
      for (var x = 0; x < original.width; x++) {
        original.setPixelRgb(
          x,
          y,
          (x ~/ 8) % 256,
          (y ~/ 8) % 256,
          (x + y) % 256,
        );
      }
    }
    final source = img.encodeJpg(original, quality: 95);
    final watch = Stopwatch()..start();
    final bytes = optimizePhoto(source);
    final result = img.decodeJpg(bytes)!;
    expect([result.width, result.height], [2560, 1920]);
    expect(bytes.length, lessThan(source.length * .75));
    // Métrica de laboratório; não representa o tempo no aparelho do usuário.
    // ignore: avoid_print
    print(
      'Foto 12 MP: ${source.length} -> ${bytes.length} bytes; ${watch.elapsedMilliseconds} ms',
    );
  });

  test(
    'portrait is limited proportionally and smaller photos are not enlarged',
    () {
      for (final size in [(900, 3000), (320, 200)]) {
        final bytes = optimizePhoto(
          img.encodePng(img.Image(width: size.$1, height: size.$2)),
        );
        final result = img.decodeJpg(bytes)!;
        expect(result.height, size.$2 > 2560 ? 2560 : size.$2);
        expect(result.width / result.height, closeTo(size.$1 / size.$2, .001));
        if (size.$2 < 2560) expect(result.width, size.$1);
      }
    },
  );

  for (var orientation = 2; orientation <= 8; orientation++) {
    test('EXIF $orientation is applied before JPEG encoding', () {
      final original = img.Image(width: 120, height: 80);
      for (var y = 0; y < 80; y++) {
        for (var x = 0; x < 120; x++) {
          original.setPixelRgb(x, y, x * 2, y * 3, (x + y) % 256);
        }
      }
      original.exif.imageIfd.orientation = orientation;
      final source = img.encodeJpg(original, quality: 95);
      final expected = img.decodeJpg(source)!;
      final result = img.decodeJpg(optimizePhoto(source))!;
      expect([result.width, result.height], [expected.width, expected.height]);
      var error = 0.0;
      for (var y = 0; y < result.height; y++) {
        for (var x = 0; x < result.width; x++) {
          final actual = result.getPixel(x, y),
              target = expected.getPixel(x, y);
          error +=
              (actual.r - target.r).abs() +
              (actual.g - target.g).abs() +
              (actual.b - target.b).abs();
        }
      }
      expect(error / (result.width * result.height * 3), lessThan(5));
      expect(result.exif.imageIfd.orientation, anyOf(isNull, 1));
    });
  }

  test('transparent PNG uses white rather than a black JPEG background', () {
    final source = img.encodePng(
      img.Image(width: 80, height: 40, numChannels: 4),
    );
    final pixel = img.decodeJpg(optimizePhoto(source))!.getPixel(20, 20);
    expect(pixel.r, greaterThan(245));
    expect(pixel.g, greaterThan(245));
    expect(pixel.b, greaterThan(245));
  });

  test(
    'unsupported photos report an error rather than saving corrupt evidence',
    () {
      expect(
        () => optimizePhoto(Uint8List.fromList([1, 2, 3])),
        throwsFormatException,
      );
    },
  );
}
