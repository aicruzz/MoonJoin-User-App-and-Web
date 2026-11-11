// Web Performance Slice 3 — Flutter Web consumption of the Slice 2 backend
// variant fields (Store logo/cover, Category, Banner, Module icon/thumbnail).
//
// Covers, without any network or timing assumption:
//   1. parseImageVariants — the shared defensive parser.
//   2. pickWebImageUrl on the web — delegates to the frozen pickImageUrl for the
//      real rendered boxes of every wired surface.
//   3. pickWebImageUrl off the web — the original *_full_url, exactly.
//   4. Model parsing of all six fields; *_full_url and toJson unchanged.
//   5. BannerController — the variant lists stay index-aligned with the
//      existing URL lists (campaigns first, duplicate-URL suffix included).
//   6. Rendered surfaces on mobile (the VM is non-web) still hand CustomImage
//      the exact existing URL even when variants are present.
// The web /image-proxy wrapping is proven separately in
// web_image_variant_transport_browser_test.dart (runs with --platform chrome).

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/features/banner/controllers/banner_controller.dart';
import 'package:moonjoin/features/banner/domain/models/banner_model.dart' as bm;
import 'package:moonjoin/features/banner/domain/services/banner_service_interface.dart';
import 'package:moonjoin/features/category/domain/models/category_model.dart';
import 'package:moonjoin/features/home/widgets/special_offers_view.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/helper/image_variant_helper.dart';

const String _host = 'https://admin.moonjoin.com/storage/app/public';
const String kLogo = '$_host/store/logo.png';
const String kLogoSm = '$_host/store/sm/logo.webp';
const String kLogoMd = '$_host/store/md/logo.webp';
const String kCover = '$_host/store/cover/cover.png';
const String kCoverSm = '$_host/store/cover/sm/cover.webp';
const String kCoverMd = '$_host/store/cover/md/cover.webp';
const String kCat = '$_host/category/cat.png';
const String kCatSm = '$_host/category/sm/cat.webp';
const String kBanner = '$_host/banner/b.png';
const String kBannerSm = '$_host/banner/sm/b.webp';
const String kBannerMd = '$_host/banner/md/b.webp';
const String kBannerLg = '$_host/banner/lg/b.webp';
const String kIcon = '$_host/module/icon.png';
const String kIconSm = '$_host/module/sm/icon.webp';
const String kThumb = '$_host/module/thumb.png';
const String kThumbSm = '$_host/module/sm/thumb.webp';
const String kThumbMd = '$_host/module/md/thumb.webp';

const Map<String, String> kAll = <String, String>{'sm': 'S', 'md': 'M', 'lg': 'L'};

String? _web(String? original, Map<String, String>? variants, double w, double h, double dpr) =>
    pickWebImageUrl(original: original, variants: variants, logicalWidth: w, logicalHeight: h, devicePixelRatio: dpr, isWeb: true);

String? _mobile(String? original, Map<String, String>? variants, double w, double h, double dpr) =>
    pickWebImageUrl(original: original, variants: variants, logicalWidth: w, logicalHeight: h, devicePixelRatio: dpr, isWeb: false);

class _FakeSplashService implements SplashServiceInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _FakeSplashService());
  @override
  ModuleModel? get module => null;
  @override
  Module getModuleConfig(String? moduleType) => Module(newVariation: false);
}

class _BannerService implements BannerServiceInterface {
  _BannerService(this.json);
  final Map<String, dynamic> json;
  @override
  Future<bm.BannerModel?> getBannerList({required DataSourceEnum source}) async => bm.BannerModel.fromJson(json);
  @override
  Future<bm.BannerModel?> getFeaturedBannerList() async => bm.BannerModel.fromJson(json);
  @override
  List<int?> moduleIdList() => <int?>[];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Two campaigns first, then: a banner with variants, a banner without, a
/// duplicate of the first banner's URL (gets the existing numeric suffix) and a
/// banner whose variants field is the backend's empty `[]`.
Map<String, dynamic> _bannerPayload() => <String, dynamic>{
  'campaigns': <dynamic>[
    <String, dynamic>{'id': 1, 'title': 'c1', 'image_full_url': '$_host/campaign/c1.png'},
    <String, dynamic>{'id': 2, 'title': 'c2', 'image_full_url': '$_host/campaign/c2.png'},
  ],
  'banners': <dynamic>[
    <String, dynamic>{'id': 10, 'type': 'default', 'link': 'https://x', 'image_full_url': kBanner,
      'image_variants': <String, dynamic>{'sm': kBannerSm, 'md': kBannerMd}},
    <String, dynamic>{'id': 11, 'type': 'default', 'link': 'https://y', 'image_full_url': '$_host/banner/plain.png'},
    <String, dynamic>{'id': 12, 'type': 'default', 'link': 'https://z', 'image_full_url': kBanner,
      'image_variants': <String, dynamic>{'sm': kBannerSm, 'md': kBannerMd}},
    <String, dynamic>{'id': 13, 'type': 'other', 'image_full_url': '$_host/banner/empty.png', 'image_variants': <dynamic>[]},
  ],
};

/// The URL list exactly as the pre-Slice-3 controller produced it.
const List<String> _expectedUrls = <String>[
  '$_host/campaign/c1.png',
  '$_host/campaign/c2.png',
  kBanner,
  '$_host/banner/plain.png',
  '${kBanner}2', // existing duplicate handling: URL + index within banners
  '$_host/banner/empty.png',
];
const List<Map<String, String>?> _expectedVariants = <Map<String, String>?>[
  null, null,
  <String, String>{'sm': kBannerSm, 'md': kBannerMd},
  null,
  <String, String>{'sm': kBannerSm, 'md': kBannerMd},
  null,
];

void main() {
  // ---------------------------------------------------------------------------
  group('parseImageVariants', () {
    test('valid map is kept', () {
      expect(parseImageVariants(<String, dynamic>{'sm': kLogoSm, 'md': kLogoMd}),
          <String, String>{'sm': kLogoSm, 'md': kLogoMd});
    });
    test('null → null', () => expect(parseImageVariants(null), isNull));
    test('backend empty [] → null', () => expect(parseImageVariants(<dynamic>[]), isNull));
    test('empty map {} → null', () => expect(parseImageVariants(<String, dynamic>{}), isNull));
    test('wrong top-level types → null', () {
      for (final dynamic v in <dynamic>['sm', 42, 1.5, true, <String>['sm'], <dynamic>[<String, String>{'sm': kLogoSm}]]) {
        expect(parseImageVariants(v), isNull, reason: '$v');
      }
    });
    test('malformed entries ignored (non-String values, non-String/empty keys)', () {
      expect(parseImageVariants(<dynamic, dynamic>{'sm': 1, 'md': null, 'lg': <String>['x'], 7: kLogoSm, '': kLogoSm}), isNull);
    });
    test('empty-string URLs ignored', () {
      expect(parseImageVariants(<String, dynamic>{'sm': '', 'md': ''}), isNull);
    });
    test('mixed valid/invalid keeps only the valid entries', () {
      expect(parseImageVariants(<dynamic, dynamic>{'sm': kLogoSm, 'md': '', 'lg': 3, 9: 'x'}),
          <String, String>{'sm': kLogoSm});
    });
    test('does not mutate its input', () {
      final Map<String, dynamic> input = <String, dynamic>{'sm': kLogoSm, 'md': ''};
      parseImageVariants(input);
      expect(input, <String, dynamic>{'sm': kLogoSm, 'md': ''});
    });
    test('same result as Item.fromJson rules for every sample', () {
      // Item keeps value is String && isNotEmpty; identical for String-keyed JSON maps.
      final Map<String, dynamic> sample = <String, dynamic>{'sm': kLogoSm, 'md': '', 'lg': 5};
      expect(parseImageVariants(sample), <String, String>{'sm': kLogoSm});
    });
  });

  // ---------------------------------------------------------------------------
  group('pickWebImageUrl — web delegates to the frozen pickImageUrl', () {
    test('identical to pickImageUrl over a grid of boxes, densities and variant sets', () {
      final List<Map<String, String>?> sets = <Map<String, String>?>[
        null, <String, String>{}, kAll, <String, String>{'sm': 'S'}, <String, String>{'md': 'M'},
        <String, String>{'lg': 'L'}, <String, String>{'sm': 'S', 'lg': 'L'}, <String, String>{'md': 'M', 'lg': 'L'},
      ];
      int checked = 0;
      for (final Map<String, String>? v in sets) {
        for (final double box in <double>[0, 30, 40, 54, 90, 120, 160, 170, 240, 320, 450, 590, 720, 1170, 1600, double.infinity]) {
          for (final double dpr in <double>[1, 1.5, 2, 3]) {
            expect(_web('O', v, box, box / 2, dpr),
                pickImageUrl(original: 'O', variants: v, logicalWidth: box, logicalHeight: box / 2, devicePixelRatio: dpr));
            checked++;
          }
        }
      }
      expect(checked, 8 * 16 * 4);
    });

    // Real rendered boxes of the wired surfaces, with variants for every size.
    final List<(String, double, double, double, String)> surfaces = <(String, double, double, double, String)>[
      ('store_card logo 50x50 @2', 50, 50, 2, 'S'),
      ('popular_store logo 40x40 @3', 40, 40, 3, 'S'),
      ('visit_again logo 54x54 @3', 54, 54, 3, 'S'),
      ('web new/top-offers logo 90x90 @2', 90, 90, 2, 'S'),
      ('store_description desktop logo 140x140 @2', 140, 140, 2, 'S'),
      ('store_description desktop logo 140x140 @3', 140, 140, 3, 'M'),
      ('category 50x50 @3', 50, 50, 3, 'S'),
      ('web category 120 tall, 160 wide @2', 160, 120, 2, 'S'),
      ('module icon 30x30 @3', 30, 30, 3, 'S'),
      ('module dialog icon 80x80 @3', 80, 80, 3, 'S'),
      ('store hero cover 104x104 @3', 104, 104, 3, 'S'),
      ('popular_store cover 300x170 @2', 300, 170, 2, 'M'),
      ('store_screen desktop cover 590x240 @1', 590, 240, 1, 'M'),
      ('store_screen desktop cover 590x240 @2', 590, 240, 2, 'L'),
      ('landing thumbnail 450x450 @1', 450, 450, 1, 'M'),
      ('landing thumbnail 450x450 @2', 450, 450, 2, 'L'),
      ('desktop banner 1170x314 @1', 1170, 314, 1, 'L'),
      ('desktop banner 1170x314 @2', 1170, 314, 2, 'O'),
    ];
    for (final (String name, double w, double h, double dpr, String want) in surfaces) {
      test('$name → $want', () => expect(_web('O', kAll, w, h, dpr), want));
    }

    test('never smaller than the box: sm-only variant is not used for a 450px box', () {
      expect(_web(kThumb, <String, String>{'sm': kThumbSm}, 450, 450, 1), kThumb);
    });
    test('missing preferred size steps upward (sm wanted, only md exists)', () {
      expect(_web(kThumb, <String, String>{'md': kThumbMd}, 45, 45, 1), kThumbMd);
    });
    test('large desktop banner with only sm/md published → original', () {
      expect(_web(kBanner, <String, String>{'sm': kBannerSm, 'md': kBannerMd}, 1170, 314, 1), kBanner);
    });
    test('large desktop banner with lg published → lg', () {
      expect(_web(kBanner, <String, String>{'sm': kBannerSm, 'md': kBannerMd, 'lg': kBannerLg}, 1170, 314, 1), kBannerLg);
    });
    test('no variants → original', () => expect(_web(kCover, null, 104, 104, 3), kCover));
    test('invalid variants (parsed to null) → original', () {
      expect(_web(kCover, parseImageVariants(<String, dynamic>{'sm': ''}), 104, 104, 3), kCover);
      expect(_web(kCover, parseImageVariants(<dynamic>[]), 104, 104, 3), kCover);
    });
    test('unbounded box (LayoutBuilder in an unbounded axis) → original', () {
      expect(_web(kCover, kAll, double.infinity, 120, 2), kCover);
    });
    test('null / empty original passes through', () {
      expect(_web(null, kAll, 50, 50, 2), isNull);
      expect(_web('', kAll, 50, 50, 2), '');
    });
  });

  // ---------------------------------------------------------------------------
  group('pickWebImageUrl — mobile returns the original exactly', () {
    test('isWeb:false ignores variants for every surface box', () {
      for (final double box in <double>[30, 50, 90, 170, 450, 590, 1170]) {
        for (final double dpr in <double>[1, 2, 3]) {
          expect(_mobile(kLogo, kAll, box, box, dpr), same(kLogo));
        }
      }
    });
    test('isWeb:false keeps null and empty originals', () {
      expect(_mobile(null, kAll, 50, 50, 2), isNull);
      expect(_mobile('', kAll, 50, 50, 2), '');
    });
    test('default isWeb is kIsWeb (false in this VM) → original', () {
      expect(pickWebImageUrl(original: kCover, variants: kAll, logicalWidth: 104, logicalHeight: 104, devicePixelRatio: 3), same(kCover));
    });
    test('the frozen product picker is still platform-agnostic (unchanged)', () {
      expect(pickImageUrl(original: kLogo, variants: kAll, logicalWidth: 50, logicalHeight: 50, devicePixelRatio: 2), 'S');
    });
  });

  // ---------------------------------------------------------------------------
  group('model parsing', () {
    test('Store logo_variants and cover_photo_variants (independent)', () {
      final Store s = Store.fromJson(<String, dynamic>{
        'id': 1, 'featured': 0, 'logo_full_url': kLogo, 'cover_photo_full_url': kCover,
        'logo_variants': <String, dynamic>{'sm': kLogoSm},
        'cover_photo_variants': <String, dynamic>{'sm': kCoverSm, 'md': kCoverMd},
      });
      expect(s.logoVariants, <String, String>{'sm': kLogoSm});
      expect(s.coverPhotoVariants, <String, String>{'sm': kCoverSm, 'md': kCoverMd});
      expect(s.logoFullUrl, kLogo);
      expect(s.coverPhotoFullUrl, kCover);
    });
    test('Store without the fields (every current production payload) → null, URLs unchanged', () {
      final Store s = Store.fromJson(<String, dynamic>{'id': 1, 'featured': 0, 'logo_full_url': kLogo, 'cover_photo_full_url': kCover});
      expect(s.logoVariants, isNull);
      expect(s.coverPhotoVariants, isNull);
      expect(s.logoFullUrl, kLogo);
      expect(s.coverPhotoFullUrl, kCover);
    });
    test('Store keeps its existing "" default when URLs are absent', () {
      final Store s = Store.fromJson(<String, dynamic>{'id': 1, 'featured': 0, 'logo_variants': <dynamic>[]});
      expect(s.logoFullUrl, '');
      expect(s.coverPhotoFullUrl, '');
      expect(s.logoVariants, isNull);
    });
    test('Category image_variants; [] → null', () {
      expect(CategoryModel.fromJson(<String, dynamic>{'id': 1, 'image_full_url': kCat, 'image_variants': <String, dynamic>{'sm': kCatSm}}).imageVariants,
          <String, String>{'sm': kCatSm});
      final CategoryModel empty = CategoryModel.fromJson(<String, dynamic>{'id': 2, 'image_full_url': kCat, 'image_variants': <dynamic>[]});
      expect(empty.imageVariants, isNull);
      expect(empty.imageFullUrl, kCat);
    });
    test('Banner image_variants, and its nested store parses its own variants', () {
      final bm.Banner b = bm.Banner.fromJson(<String, dynamic>{
        'id': 1, 'image_full_url': kBanner, 'image_variants': <String, dynamic>{'sm': kBannerSm},
        'store': <String, dynamic>{'id': 3, 'featured': 0, 'logo_full_url': kLogo, 'logo_variants': <String, dynamic>{'sm': kLogoSm}},
      });
      expect(b.imageVariants, <String, String>{'sm': kBannerSm});
      expect(b.imageFullUrl, kBanner);
      expect(b.store!.logoVariants, <String, String>{'sm': kLogoSm});
    });
    test('Module icon_variants and thumbnail_variants are independent', () {
      final ModuleModel m = ModuleModel.fromJson(<String, dynamic>{
        'id': 3, 'module_type': 'food', 'icon_full_url': kIcon, 'thumbnail_full_url': kThumb,
        'icon_variants': <String, dynamic>{'sm': kIconSm},
        'thumbnail_variants': <String, dynamic>{'sm': kThumbSm, 'md': kThumbMd},
      });
      expect(m.iconVariants, <String, String>{'sm': kIconSm});
      expect(m.thumbnailVariants, <String, String>{'sm': kThumbSm, 'md': kThumbMd});
      expect(m.iconFullUrl, kIcon);
      expect(m.thumbnailFullUrl, kThumb);
    });
    test('Module restored from saved settings (its own toJson) parses with no variants', () {
      final ModuleModel m = ModuleModel.fromJson(<String, dynamic>{
        'id': 3, 'icon_full_url': kIcon, 'icon_variants': <String, dynamic>{'sm': kIconSm},
      });
      final ModuleModel restored = ModuleModel.fromJson(m.toJson());
      expect(restored.iconVariants, isNull);
      expect(restored.iconFullUrl, kIcon);
    });
    test('existing constructors still compile and default the new fields to null', () {
      expect(ModuleModel(id: 1).iconVariants, isNull);
      expect(CategoryModel(id: 1).imageVariants, isNull);
      expect(bm.Banner(id: 1).imageVariants, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('serialization unchanged', () {
    final Map<String, dynamic> withVariants = <String, dynamic>{'sm': kLogoSm};
    test('Store.toJson emits no variant key and the same *_full_url', () {
      final Map<String, dynamic> j = Store.fromJson(<String, dynamic>{
        'id': 1, 'featured': 0, 'logo_full_url': kLogo, 'cover_photo_full_url': kCover,
        'logo_variants': withVariants, 'cover_photo_variants': withVariants,
      }).toJson();
      expect(j.keys.where((String k) => k.contains('variants')), isEmpty);
      expect(j['logo_full_url'], kLogo);
      expect(j['cover_photo_full_url'], kCover);
    });
    test('Category / Banner / Module toJson emit no variant key', () {
      final Map<String, dynamic> c = CategoryModel.fromJson(<String, dynamic>{'id': 1, 'image_full_url': kCat, 'image_variants': withVariants}).toJson();
      final Map<String, dynamic> b = bm.Banner.fromJson(<String, dynamic>{'id': 1, 'image_full_url': kBanner, 'image_variants': withVariants}).toJson();
      final Map<String, dynamic> m = ModuleModel.fromJson(<String, dynamic>{
        'id': 1, 'icon_full_url': kIcon, 'thumbnail_full_url': kThumb, 'icon_variants': withVariants, 'thumbnail_variants': withVariants,
      }).toJson();
      for (final Map<String, dynamic> j in <Map<String, dynamic>>[c, b, m]) {
        expect(j.keys.where((String k) => k.contains('variants')), isEmpty);
      }
      expect(c['image_full_url'], kCat);
      expect(b['image_full_url'], kBanner);
      expect(m['icon_full_url'], kIcon);
      expect(m['thumbnail_full_url'], kThumb);
    });
  });

  // ---------------------------------------------------------------------------
  group('BannerController — variant lists aligned with the URL lists', () {
    setUp(() {
      Get.testMode = true;
      Get.put<SplashController>(_Splash());
    });
    tearDown(Get.reset);

    test('home banners: URLs exactly as before, variants aligned, campaigns null', () async {
      final BannerController c = BannerController(bannerServiceInterface: _BannerService(_bannerPayload()));
      await c.getBannerList(true, dataSource: DataSourceEnum.client);
      expect(c.bannerImageList, _expectedUrls);
      expect(c.bannerVariantList, _expectedVariants);
      expect(c.bannerVariantList!.length, c.bannerImageList!.length);
      expect(c.bannerDataList!.length, c.bannerImageList!.length);
    });

    test('featured banners: URLs exactly as before, variants aligned', () async {
      final BannerController c = BannerController(bannerServiceInterface: _BannerService(_bannerPayload()));
      await c.getFeaturedBanner();
      expect(c.featuredBannerList, _expectedUrls);
      expect(c.featuredBannerVariantList, _expectedVariants);
      expect(c.featuredBannerDataList!.length, c.featuredBannerList!.length);
    });

    test('duplicate-suffixed entry keeps its own banner variants and its suffixed fallback', () async {
      final BannerController c = BannerController(bannerServiceInterface: _BannerService(_bannerPayload()));
      await c.getBannerList(true, dataSource: DataSourceEnum.client);
      const int dup = 4;
      expect(c.bannerImageList![dup], '${kBanner}2');
      // mobile: the existing (suffixed) entry, byte for byte
      expect(_mobile(c.bannerImageList![dup], c.bannerVariantList![dup], 300, 126, 2), '${kBanner}2');
      // web, 300x126 card @2 = 600px: the published md variant
      expect(_web(c.bannerImageList![dup], c.bannerVariantList![dup], 300, 126, 2), kBannerMd);
      // web, 150x63 card @2 = 300px: the published sm variant
      expect(_web(c.bannerImageList![dup], c.bannerVariantList![dup], 150, 63, 2), kBannerSm);
      // web, desktop carousel with no big-enough variant: the existing entry
      expect(_web(c.bannerImageList![dup], c.bannerVariantList![dup], 1170, 314, 1), '${kBanner}2');
    });

    test('rebuilding replaces the variant list (no stale entries) and clearBanner clears it', () async {
      final Map<String, dynamic> payload = _bannerPayload();
      final BannerController c = BannerController(bannerServiceInterface: _BannerService(payload));
      await c.getBannerList(true, dataSource: DataSourceEnum.client);
      payload['campaigns'] = <dynamic>[];
      payload['banners'] = (payload['banners'] as List<dynamic>).sublist(0, 1);
      await c.getBannerList(true, dataSource: DataSourceEnum.client);
      expect(c.bannerImageList, <String>[kBanner]);
      expect(c.bannerVariantList, <Map<String, String>?>[<String, String>{'sm': kBannerSm, 'md': kBannerMd}]);
      c.clearBanner();
      expect(c.bannerImageList, isNull);
      expect(c.bannerVariantList, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  group('rendered surfaces on mobile keep the exact existing URL', () {
    setUp(() {
      Get.testMode = true;
      Get.put<SplashController>(_Splash());
    });
    tearDown(Get.reset);

    testWidgets('SpecialOffersView hands CustomImage the existing featured entries', (WidgetTester tester) async {
      final BannerController c = BannerController(bannerServiceInterface: _BannerService(_bannerPayload()));
      Get.put<BannerController>(c);
      await c.getFeaturedBanner();
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SpecialOffersView())));
      await tester.pump();
      final List<String> rendered = tester.widgetList<CustomImage>(find.byType(CustomImage)).map((CustomImage i) => i.image).toList();
      expect(rendered, isNotEmpty);
      expect(rendered, _expectedUrls.sublist(0, rendered.length));
      // and CachedNetworkImage receives the same string on mobile (no proxy)
      final List<String> loaded = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage)).map((CachedNetworkImage i) => i.imageUrl).toList();
      expect(loaded, rendered);
    });

    testWidgets('CustomImage on mobile passes a selected variant URL through unchanged', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: CustomImage(image: kLogoSm, height: 50, width: 50)));
      expect(tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage)).imageUrl, kLogoSm);
    });
  });
}
