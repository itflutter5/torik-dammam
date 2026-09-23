import test from 'node:test';
import assert from 'node:assert/strict';
import { postSchema, postPhotosSchema } from '../src/post_validation.js';

const valid = {
  category: 'Scrap', title: 'Metal for sale', description: 'Good quality scrap metal',
  price: '50', unit: 'kg', storeNumber: '0101',
};

test('every displayed post field is required', () => {
  assert.equal(postSchema.safeParse(valid).success, true);
  for (const key of Object.keys(valid)) {
    for (const value of ['', '   ', undefined]) {
      assert.equal(postSchema.safeParse({ ...valid, [key]: value }).success, false, key);
    }
  }
});

test('salary posts require salary but do not require a hidden unit', () => {
  for (const category of ['Need Worker', 'Need Job']) {
    assert.equal(postSchema.safeParse({ ...valid, category, unit: '' }).success, true);
    assert.equal(postSchema.safeParse({ ...valid, category, price: '' }).success, false);
  }
});

test('rejects invalid prices and units and requires one to three photos', () => {
  for (const price of [null, false, -1, 'NaN', 'Infinity', 'abc', 10000000000]) {
    assert.equal(postSchema.safeParse({ ...valid, price }).success, false);
  }
  assert.equal(postSchema.safeParse({ ...valid, unit: 'item' }).success, false);
  assert.equal(postPhotosSchema.safeParse([]).success, false);
  assert.equal(postPhotosSchema.safeParse([{}]).success, true);
  assert.equal(postPhotosSchema.safeParse([{}, {}, {}]).success, true);
  assert.equal(postPhotosSchema.safeParse([{}, {}, {}, {}]).success, false);
});
