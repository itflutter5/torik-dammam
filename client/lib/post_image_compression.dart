import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const postImageMaxBytes = 1024 * 1024;
const postImageMaxDimension = 1600;

Future<Uint8List> compressPostImage(Uint8List bytes) =>
    compute(_compressPostImage, bytes);

Uint8List _compressPostImage(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) throw const FormatException('Unsupported image');
  var photo = img.bakeOrientation(decoded);
  if (photo.width > postImageMaxDimension ||
      photo.height > postImageMaxDimension) {
    photo = img.copyResize(
      photo,
      width: photo.width >= photo.height ? postImageMaxDimension : null,
      height: photo.height > photo.width ? postImageMaxDimension : null,
      interpolation: img.Interpolation.average,
    );
  }
  // Flatten transparency onto white and discard metadata from the upload.
  final background = img.Image(width: photo.width, height: photo.height);
  img.fill(background, color: img.ColorRgb8(255, 255, 255));
  photo = img.compositeImage(background, photo);
  var quality = 80;
  while (true) {
    final compressed = img.encodeJpg(photo, quality: quality);
    if (compressed.length <= postImageMaxBytes) return compressed;
    if (quality > 50) {
      quality -= 15;
    } else {
      photo = img.copyResize(
        photo,
        width: (photo.width * 0.8).round().clamp(1, photo.width),
        height: (photo.height * 0.8).round().clamp(1, photo.height),
        interpolation: img.Interpolation.average,
      );
    }
  }
}
