// "You denied location permission forever" dialog — Settings button.
//
// Native: Settings still opens the app's OS settings, then closes the dialog.
// Web:    browsers have no API to open site/OS settings (geolocator_web throws
//         UnsupportedError from openAppSettings), so Settings must just close
//         the dialog instead of throwing and leaving it stuck open.
//
// VM run covers native; `flutter test --platform chrome <this file>` covers web.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/location/widgets/permission_dialog_widget.dart';

class _FakeGeolocator extends GeolocatorPlatform {
  int openAppSettingsCalls = 0;

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCalls++;
    // Mirror geolocator_web, which cannot open browser settings.
    if (kIsWeb) throw UnsupportedError('openAppSettings is not supported on the web');
    return true;
  }
}

void main() {
  testWidgets('Settings button: native opens app settings, web only closes; dialog always closes', (WidgetTester tester) async {
    final _FakeGeolocator fake = _FakeGeolocator();
    GeolocatorPlatform.instance = fake;

    await tester.pumpWidget(const GetMaterialApp(home: Scaffold(body: SizedBox())));
    Get.dialog(const PermissionDialogWidget());
    await tester.pumpAndSettle();
    expect(find.byType(PermissionDialogWidget), findsOneWidget);

    await tester.tap(find.text('settings'.tr));
    await tester.pumpAndSettle();

    expect(find.byType(PermissionDialogWidget), findsNothing);
    expect(fake.openAppSettingsCalls, kIsWeb ? 0 : 1);
    expect(tester.takeException(), isNull);
  });
}
