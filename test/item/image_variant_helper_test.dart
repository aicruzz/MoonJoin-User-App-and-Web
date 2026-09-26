// Focused tests for the Media 6G product-image variant consumer.
//
// Two pure behaviours are covered:
//   1. `pickImageUrl` — chooses the smallest variant that is still big enough
//      for the physical render size, stepping upward only, and always falling
//      back to the original URL.
//   2. `Item.fromJson` — parses the additive `image_variants` field defensively,
//      so every endpoint that does not expose it keeps behaving exactly as before.

import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/helper/image_variant_helper.dart';

const String kOriginal =
    'https://admin.moonjoin.com/storage/app/public/product/original.png';
const String kSm =
    'https://admin.moonjoin.com/storage/app/public/product/sm/x.webp';
const String kMd =
    'https://admin.moonjoin.com/storage/app/public/product/md/x.webp';
const String kLg =
    'https://admin.moonjoin.com/storage/app/public/product/lg/x.webp';

Map<String, dynamic> _itemJson({dynamic variants, bool includeKey = true}) =>
    <String, dynamic>{
      'id': 1,
      'name': 'Test item',
      'price': 100,
      'discount': 0,
      'image_full_url': kOriginal,
      if (includeKey) 'image_variants': variants,
    };

void main() {
  group('pickImageUrl — fallback safety', () {
    test('A: null variants → original', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: null,
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
    });

    test('B: empty variants → original', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: const {},
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
    });

    test('O: null/empty original is returned untouched', () {
      expect(
        pickImageUrl(
          original: null,
          variants: const {'sm': kSm},
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 1,
        ),
        isNull,
      );
      expect(
        pickImageUrl(
          original: '',
          variants: const {'sm': kSm},
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 1,
        ),
        '',
      );
    });

    test('M/N: zero, negative and NaN dimensions → original', () {
      const Map<String, String> all = {'sm': kSm, 'md': kMd, 'lg': kLg};
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 0,
          logicalHeight: 0,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: -100,
          logicalHeight: -200,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 0,
        ),
        kOriginal,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: double.nan,
          logicalHeight: 0,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
    });
  });

  group('pickImageUrl — tier selection', () {
    const Map<String, String> all = {'sm': kSm, 'md': kMd, 'lg': kLg};

    test('C: target <= 320 → sm', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 3,
        ),
        kSm,
      );
    });

    test('D: target <= 720 → md', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 200,
          logicalHeight: 200,
          devicePixelRatio: 3,
        ),
        kMd,
      );
    });

    test('E: target <= 1440 → lg', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 390,
          logicalHeight: 200,
          devicePixelRatio: 3,
        ),
        kLg,
      );
    });

    test('F: target > 1440 → original (largest variant is only 1440)', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 800,
          logicalHeight: 200,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
    });

    test('exact tier boundaries select that tier', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 320,
          logicalHeight: 0,
          devicePixelRatio: 1,
        ),
        kSm,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 720,
          logicalHeight: 0,
          devicePixelRatio: 1,
        ),
        kMd,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 1440,
          logicalHeight: 0,
          devicePixelRatio: 1,
        ),
        kLg,
      );
    });

    test('K: devicePixelRatio changes the selection', () {
      const Map<String, String> v = {'sm': kSm, 'md': kMd, 'lg': kLg};
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: v,
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 1,
        ),
        kSm,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: v,
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 4,
        ),
        kMd,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: v,
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 8,
        ),
        kLg,
      );
    });

    test('L: uses max(width, height), not width alone', () {
      // Width alone (100 * 1) would pick sm; height 700 must drive md.
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: all,
          logicalWidth: 100,
          logicalHeight: 700,
          devicePixelRatio: 1,
        ),
        kMd,
      );
    });
  });

  group('pickImageUrl — missing tiers step upward only (never downscale)', () {
    test('G: wants sm, sm missing → md', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: const {'md': kMd, 'lg': kLg},
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 3,
        ),
        kMd,
      );
    });

    test('G2: wants sm, only lg exists → lg', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: const {'lg': kLg},
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 3,
        ),
        kLg,
      );
    });

    test('H: wants md, md missing → lg (never falls back down to sm)', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: const {'sm': kSm, 'lg': kLg},
          logicalWidth: 200,
          logicalHeight: 200,
          devicePixelRatio: 3,
        ),
        kLg,
      );
    });

    test('I: wants lg, lg missing → original (not the smaller sm/md)', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: const {'sm': kSm, 'md': kMd},
          logicalWidth: 390,
          logicalHeight: 200,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
    });

    test('J: map present but no usable tier → original', () {
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: const {'xl': 'https://example.test/xl.webp'},
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
      expect(
        pickImageUrl(
          original: kOriginal,
          variants: const {'sm': ''},
          logicalWidth: 100,
          logicalHeight: 100,
          devicePixelRatio: 3,
        ),
        kOriginal,
      );
    });
  });

  test('P: does not mutate the input variants map', () {
    final Map<String, String> variants = {'sm': kSm, 'md': kMd};
    final Map<String, String> before = Map<String, String>.from(variants);
    pickImageUrl(
      original: kOriginal,
      variants: variants,
      logicalWidth: 390,
      logicalHeight: 200,
      devicePixelRatio: 3,
    );
    expect(variants, before);
    expect(variants.length, 2);
  });

  group('Item.fromJson — additive image_variants parsing', () {
    test('missing image_variants → null (all current endpoints)', () {
      final Item item = Item.fromJson(_itemJson(includeKey: false));
      expect(item.imageVariants, isNull);
      expect(item.imageFullUrl, kOriginal);
    });

    test('null image_variants → null', () {
      expect(Item.fromJson(_itemJson(variants: null)).imageVariants, isNull);
    });

    test('empty image_variants {} → null', () {
      expect(
        Item.fromJson(_itemJson(variants: <String, dynamic>{})).imageVariants,
        isNull,
      );
    });

    test('non-map image_variants → null, does not throw', () {
      expect(
        Item.fromJson(_itemJson(variants: 'nonsense')).imageVariants,
        isNull,
      );
      expect(
        Item.fromJson(_itemJson(variants: <String>['sm'])).imageVariants,
        isNull,
      );
    });

    test('valid map → Map<String, String>', () {
      final Item item = Item.fromJson(
        _itemJson(variants: <String, dynamic>{'sm': kSm, 'md': kMd, 'lg': kLg}),
      );
      expect(item.imageVariants, <String, String>{
        'sm': kSm,
        'md': kMd,
        'lg': kLg,
      });
    });

    test('partial map keeps only the present tiers', () {
      expect(
        Item.fromJson(
          _itemJson(variants: <String, dynamic>{'sm': kSm}),
        ).imageVariants,
        <String, String>{'sm': kSm},
      );
    });

    test('non-string / empty values are dropped; all-unusable → null', () {
      final Item mixed = Item.fromJson(
        _itemJson(variants: <String, dynamic>{'sm': kSm, 'md': 42, 'lg': ''}),
      );
      expect(mixed.imageVariants, <String, String>{'sm': kSm});
      expect(
        Item.fromJson(
          _itemJson(variants: <String, dynamic>{'sm': null, 'md': 7}),
        ).imageVariants,
        isNull,
      );
    });

    test('imageFullUrl / imagesFullUrl are unaffected', () {
      final Map<String, dynamic> json =
          _itemJson(variants: <String, dynamic>{'sm': kSm})
            ..['images_full_url'] = <String>[
              'https://example.test/g1.png',
              'https://example.test/g2.png',
            ];
      final Item item = Item.fromJson(json);
      expect(item.imageFullUrl, kOriginal);
      expect(item.imagesFullUrl, <String>[
        'https://example.test/g1.png',
        'https://example.test/g2.png',
      ]);
      expect(item.toJson().containsKey('image_variants'), isFalse);
    });
  });
}
