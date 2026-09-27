// Media 6V — focused tests for the LISTING/CARD variant call sites.
//
// The frozen selector itself is already covered by
// `test/item/image_variant_helper_test.dart`; that suite is untouched and is not
// duplicated here. What is new in Media 6V is *which box each listing renderer
// hands the selector*, so these tests pin exactly those boxes:
//
//   ItemWidget (mobile card)          90x90 / 100x90 / 120x120 (desktop)
//   ItemWidget (_premiumStoreDishCard) 122x122
//   WebItemWidget                     140x300 (desktop product) / 65x80, 100x80
//   ItemCardWidget / ItemCard /
//   ReviewItemCard                    LayoutBuilder constraints (dynamic)
//
// plus the degradation paths those call sites can actually hit at runtime:
// missing variants, an absent tier, and unbounded constraints.

import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/helper/image_variant_helper.dart';

const String kOriginal =
    'https://admin.moonjoin.com/storage/app/public/product/original.png';
const String kSm =
    'https://admin.moonjoin.com/storage/app/public/product/sm/x.webp';
const String kMd =
    'https://admin.moonjoin.com/storage/app/public/product/md/x.webp';
const String kLg =
    'https://admin.moonjoin.com/storage/app/public/product/lg/x.webp';

const Map<String, String> kAllTiers = <String, String>{
  'sm': kSm,
  'md': kMd,
  'lg': kLg,
};

/// Mirrors the call sites exactly: `pickImageUrl(...) ?? original`.
String select({
  required String? original,
  required Map<String, String>? variants,
  required double width,
  required double height,
  required double dpr,
}) {
  return pickImageUrl(
        original: original,
        variants: variants,
        logicalWidth: width,
        logicalHeight: height,
        devicePixelRatio: dpr,
      ) ??
      '$original';
}

void main() {
  group('ItemWidget — mobile product card (90x90 / 100x90)', () {
    test('picks sm at DPR 2 and DPR 3 when every tier exists', () {
      // 90 * 3 = 270px <= 320, so the smallest tier still covers the card.
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 90, height: 90, dpr: 3),
        kSm,
      );
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 90, height: 90, dpr: 2),
        kSm,
      );
    });

    test('length == null variant of the box (100 tall) still picks sm at DPR 3', () {
      // max(90, 100) * 3 = 300px <= 320.
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 90, height: 100, dpr: 3),
        kSm,
      );
    });

    test('desktop box (120x120) picks sm at DPR 1 and DPR 2', () {
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 120, height: 120, dpr: 1),
        kSm,
      );
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 120, height: 120, dpr: 2),
        kSm,
      );
    });
  });

  group('ItemWidget — premium store dish card (fixed 122x122)', () {
    test('picks sm at DPR 2 and steps up to md at DPR 3', () {
      // 122 * 2 = 244px <= 320 -> sm; 122 * 3 = 366px > 320 -> md.
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 122, height: 122, dpr: 2),
        kSm,
      );
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 122, height: 122, dpr: 3),
        kMd,
      );
    });

    test('falls back to the original when the item has no variants', () {
      expect(
        select(original: kOriginal, variants: null, width: 122, height: 122, dpr: 3),
        kOriginal,
      );
      expect(
        select(original: kOriginal, variants: const <String, String>{}, width: 122, height: 122, dpr: 3),
        kOriginal,
      );
    });
  });

  group('WebItemWidget — desktop product card (140x300)', () {
    test('picks sm at DPR 1 and md at DPR 2', () {
      // max(300, 140) * 1 = 300px <= 320 -> sm; * 2 = 600px -> md.
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 300, height: 140, dpr: 1),
        kSm,
      );
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 300, height: 140, dpr: 2),
        kMd,
      );
    });

    test('mobile boxes (80x65 and 80x100) pick sm at DPR 3', () {
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 80, height: 65, dpr: 3),
        kSm,
      );
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 80, height: 100, dpr: 3),
        kSm,
      );
    });
  });

  group('LayoutBuilder-driven cards (ItemCardWidget, ItemCard, ReviewItemCard)', () {
    test('a representative grid tile (159x150) picks sm at DPR 2 and md at DPR 3', () {
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 159, height: 150, dpr: 2),
        kSm,
      );
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 159, height: 150, dpr: 3),
        kMd,
      );
    });

    test('a carousel card slot (190x127) picks md at DPR 2', () {
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 190, height: 127, dpr: 2),
        kMd,
      );
    });

    test('unbounded constraints degrade to the original rather than guessing', () {
      // A LayoutBuilder in an unbounded parent reports infinite maxWidth/maxHeight;
      // the call sites must keep rendering exactly what they render today.
      expect(
        select(
          original: kOriginal,
          variants: kAllTiers,
          width: double.infinity,
          height: double.infinity,
          dpr: 3,
        ),
        kOriginal,
      );
    });

    test('a zero-sized slot (first layout pass) degrades to the original', () {
      expect(
        select(original: kOriginal, variants: kAllTiers, width: 0, height: 0, dpr: 3),
        kOriginal,
      );
    });
  });

  group('tier availability at listing sizes', () {
    test('only sm present, small box -> sm', () {
      expect(
        select(
          original: kOriginal,
          variants: const <String, String>{'sm': kSm},
          width: 90, height: 90, dpr: 3,
        ),
        kSm,
      );
    });

    test('only sm present, box needing md -> original (never upscale sm)', () {
      // 122 * 3 = 366px wants md; md and lg are absent, so the original stands.
      expect(
        select(
          original: kOriginal,
          variants: const <String, String>{'sm': kSm},
          width: 122, height: 122, dpr: 3,
        ),
        kOriginal,
      );
    });

    test('sm missing but md present, small box -> steps upward to md', () {
      expect(
        select(
          original: kOriginal,
          variants: const <String, String>{'md': kMd, 'lg': kLg},
          width: 90, height: 90, dpr: 2,
        ),
        kMd,
      );
    });
  });

  group('store-logo branch is never variant-selected', () {
    // ItemWidget/WebItemWidget gate on `isStore`: the store branch keeps its
    // untouched `store!.logoFullUrl` and never reaches the selector. There is no
    // Store-side variant map at all, so even if a logo URL were routed through
    // the product path it would resolve to exactly the URL rendered today.
    // (`Item.fromJson` variant parsing is covered by image_variant_helper_test.dart
    // and is deliberately not duplicated here.)
    const String kStoreLogo =
        'https://admin.moonjoin.com/storage/app/public/store/logo.png';

    test('a store logo with no variant map resolves to the untouched logo URL', () {
      expect(
        select(original: kStoreLogo, variants: null, width: 90, height: 90, dpr: 3),
        kStoreLogo,
      );
      expect(
        select(original: kStoreLogo, variants: null, width: 275, height: 140, dpr: 2),
        kStoreLogo,
      );
    });
  });
}
