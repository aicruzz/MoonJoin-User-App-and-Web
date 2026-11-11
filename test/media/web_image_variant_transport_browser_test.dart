// Web Performance Slice 3 — transport proof that needs a real web runtime.
//
// kIsWeb is a compile-time constant, so the VM suite cannot reach the web
// branches. Run with:  flutter test --platform chrome test/media/web_image_variant_transport_browser_test.dart
//
// Proves: (1) the default pickWebImageUrl (no isWeb override) selects a variant
// on the web; (2) the selected variant still goes through the EXISTING
// CustomImage /image-proxy wrapper, unchanged.
@TestOn('browser')
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/web_raster_image.dart';
import 'package:moonjoin/helper/image_variant_helper.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:octo_image/octo_image.dart';

const String _host = 'https://admin.moonjoin.com/storage/app/public';
const String kLogo = '$_host/store/logo.png';
const String kLogoSm = '$_host/store/sm/logo.webp';

void main() {
  test('runs on the web', () => expect(kIsWeb, isTrue));

  test('default pickWebImageUrl selects the variant on the web', () {
    expect(
      pickWebImageUrl(original: kLogo, variants: const <String, String>{'sm': kLogoSm},
          logicalWidth: 50, logicalHeight: 50, devicePixelRatio: 2),
      kLogoSm,
    );
  });

  testWidgets('selected variant still goes through the existing /image-proxy wrapper', (WidgetTester tester) async {
    final String chosen = pickWebImageUrl(original: kLogo, variants: const <String, String>{'sm': kLogoSm},
        logicalWidth: 50, logicalHeight: 50, devicePixelRatio: 2) ?? kLogo;
    await tester.pumpWidget(MaterialApp(home: CustomImage(image: chosen, height: 50, width: 50)));
    // Web renders through OctoImage + WebRasterImage (raster, not <img>).
    expect((tester.widget<OctoImage>(find.byType(OctoImage)).image as WebRasterImage).url,
        '${AppConstants.baseUrl}/image-proxy?url=$kLogoSm');
  });

  testWidgets('no variants → original still goes through the same wrapper', (WidgetTester tester) async {
    final String chosen = pickWebImageUrl(original: kLogo, variants: null,
        logicalWidth: 50, logicalHeight: 50, devicePixelRatio: 2) ?? kLogo;
    await tester.pumpWidget(MaterialApp(home: CustomImage(image: chosen, height: 50, width: 50)));
    // Web renders through OctoImage + WebRasterImage (raster, not <img>).
    expect((tester.widget<OctoImage>(find.byType(OctoImage)).image as WebRasterImage).url,
        '${AppConstants.baseUrl}/image-proxy?url=$kLogo');
  });
}
