import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:scrap_market/post_image_compression.dart';

void main() {
  test('compresses a large noisy photo below the upload target', () async {
    final photo = img.Image(width: 2100, height: 1700);
    final random = Random(42);
    for (final pixel in photo) {
      pixel.setRgb(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    }
    final original = img.encodePng(photo);
    final compressed = await compressPostImage(original);
    final result = img.decodeJpg(compressed)!;
    expect(compressed.length, lessThanOrEqualTo(postImageMaxBytes));
    expect(compressed.length, lessThan(original.length));
    expect(result.width, lessThanOrEqualTo(postImageMaxDimension));
    expect(result.height, lessThanOrEqualTo(postImageMaxDimension));
    expect(result.width / result.height, closeTo(2100 / 1700, 0.01));
  });

  test(
    'keeps small photos at their original size and flattens transparency',
    () async {
      final photo = img.Image(width: 100, height: 200, numChannels: 4);
      final result = img.decodeJpg(
        await compressPostImage(img.encodePng(photo)),
      )!;
      expect(result.width, 100);
      expect(result.height, 200);
      expect(result.getPixel(50, 50).r, greaterThan(245));
    },
  );

  test('rejects invalid photo data', () async {
    await expectLater(compressPostImage(Uint8List(10)), throwsFormatException);
  });
}
