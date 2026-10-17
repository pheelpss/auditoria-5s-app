import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Executado em isolate: uma única otimização, antes de guardar a evidência.
Uint8List optimizePhoto(Uint8List source) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(source);
  } catch (_) {
    throw const FormatException('Formato de foto inválido.');
  }
  if (decoded == null) throw const FormatException('Formato de foto inválido.');
  var photo = img.bakeOrientation(decoded);
  if (photo.width > 2560 || photo.height > 2560) {
    photo = img.copyResize(
      photo,
      width: photo.width >= photo.height ? 2560 : null,
      height: photo.height > photo.width ? 2560 : null,
      interpolation: img.Interpolation.average,
    );
  }
  // JPEG não tem transparência: usa fundo branco para fotos importadas em PNG.
  if (photo.hasAlpha) {
    final background = img.Image(width: photo.width, height: photo.height);
    img.fill(background, color: img.ColorRgb8(255, 255, 255));
    img.compositeImage(background, photo);
    photo = background;
  }
  return Uint8List.fromList(img.encodeJpg(photo, quality: 90));
}
