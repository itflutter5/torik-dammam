import 'package:flutter_test/flutter_test.dart';
import 'package:scrap_market/post_validation.dart';

void main() {
  String? validate({String? category = 'Scrap', String title = 'Metal for sale',
    String description = 'Good quality scrap metal', String price = '50',
    String? unit = 'kg', String storeNumber = '0101', int photoCount = 1}) =>
      validatePostFields(category: category, title: title, description: description,
        price: price, unit: unit, storeNumber: storeNumber, photoCount: photoCount);

  test('requires all displayed fields and at least one photo', () {
    expect(validate(), isNull);
    expect(validate(category: null), isNotNull);
    expect(validate(title: ''), isNotNull);
    expect(validate(description: ''), isNotNull);
    expect(validate(price: ''), isNotNull);
    expect(validate(unit: null), isNotNull);
    expect(validate(storeNumber: ''), isNotNull);
    expect(validate(photoCount: 0), isNotNull);
  });

  test('requires salary but skips units for employment posts', () {
    for (final category in ['Need Job', 'Need Worker']) {
      expect(validate(category: category, unit: null), isNull);
      expect(validate(category: category, price: '', unit: null), isNotNull);
    }
  });

  test('rejects invalid amounts and units', () {
    for (final price in [' ', '-1', 'NaN', 'Infinity', 'abc', '10000000000']) {
      expect(validate(price: price), isNotNull);
    }
    expect(validate(unit: 'item'), isNotNull);
  });
}
