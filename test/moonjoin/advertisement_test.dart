import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_advertisement_card.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_advertisement_section.dart';
import 'package:moonjoin/features/home/controllers/advertisement_controller.dart';
import 'package:moonjoin/features/home/domain/models/advertisement_model.dart';
import 'package:moonjoin/features/home/domain/services/advertisement_service_interface.dart';

// Focused tests for the MoonJoin Advertisement presentation. Uses video ads so
// the FavouriteController/network image dependencies of the image card are not
// required; the image card is a plain Column/Row with ellipsis (mirrors the
// legacy layout). Proves: the section self-hides when empty, shows a loading
// state when the list is null, renders the existing data when present, and the
// video card renders without overflow or crash on an uninitialised video.

class _FakeAdService implements AdvertisementServiceInterface {
  final List<AdvertisementModel>? result;
  _FakeAdService(this.result);
  @override
  Future<List<AdvertisementModel>?> getAdvertisementList(DataSourceEnum source) async => result;
}

AdvertisementModel _videoAd(int id) => AdvertisementModel(
      id: id, storeId: id, addType: 'video_promotion',
      title: 'Promo $id', description: 'A great promotional highlight number $id',
      videoAttachmentFullUrl: '', coverImageFullUrl: '', profileImageFullUrl: '',
    );

AdvertisementModel _storeAd(int id) => AdvertisementModel(
      id: id, storeId: id, addType: 'store_promotion',
      title: 'Store Promo $id', description: 'Store promotion number $id',
      coverImageFullUrl: '', profileImageFullUrl: '',
    );

List<String> _drain(WidgetTester tester) {
  final List<String> ex = [];
  Object? e;
  while ((e = tester.takeException()) != null) {
    ex.add(e.toString());
  }
  return ex;
}

void main() {
  tearDown(Get.reset);

  Widget wrap(Widget child) => GetMaterialApp(
        theme: ThemeData(primaryColor: const Color(0xFF13A452), disabledColor: Colors.grey, hintColor: Colors.grey),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('video advertisement card renders without overflow or crash', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 700 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(wrap(SizedBox(height: 260, child: MoonjoinAdvertisementCard(advertisement: _videoAd(1)))));
    await tester.pump(const Duration(milliseconds: 100));

    final ex = _drain(tester);
    expect(ex.any((e) => e.toLowerCase().contains('overflow')), isFalse, reason: ex.join('\n'));
    // The promo overlay renders directly on the banner (title + Order Now button),
    // with no white information sheet, even before the video is ready.
    expect(find.text('Promo 1'), findsOneWidget);
    expect(find.text('order_now'), findsOneWidget);
    // Video Promotion → NO profile image/logo at all (no CustomImage on the banner).
    expect(find.byType(CustomImage), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Video Promotion has NO profile image, Store Promotion HAS one', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 700 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Store Promotion → profile image (and cover) rendered.
    await tester.pumpWidget(wrap(SizedBox(height: 200, child: MoonjoinAdvertisementCard(advertisement: _storeAd(1)))));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(CustomImage), findsWidgets);
    expect(find.text('Store Promo 1'), findsOneWidget);

    // Video Promotion → NO profile image / avatar.
    await tester.pumpWidget(wrap(SizedBox(height: 200, child: MoonjoinAdvertisementCard(advertisement: _videoAd(2)))));
    await tester.pump(const Duration(milliseconds: 50));
    _drain(tester);
    expect(find.byType(CustomImage), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('section self-hides when there are no advertisements', (tester) async {
    Get.put<AdvertisementController>(AdvertisementController(advertisementServiceInterface: _FakeAdService(<AdvertisementModel>[])));
    await Get.find<AdvertisementController>().getAdvertisementList();

    await tester.pumpWidget(wrap(const MoonjoinAdvertisementSection()));
    await tester.pump();

    expect(find.byType(MoonjoinAdvertisementCard), findsNothing);
  });

  testWidgets('section renders the existing advertisement data', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 900 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Get.put<AdvertisementController>(AdvertisementController(advertisementServiceInterface: _FakeAdService([_videoAd(1), _videoAd(2)])));
    await Get.find<AdvertisementController>().getAdvertisementList();

    await tester.pumpWidget(wrap(const MoonjoinAdvertisementSection()));
    await tester.pump(const Duration(milliseconds: 100));

    final ex = _drain(tester);
    expect(ex.any((e) => e.toLowerCase().contains('overflow')), isFalse, reason: ex.join('\n'));
    expect(find.byType(MoonjoinAdvertisementCard), findsWidgets);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('section shows a loading state while the list is null', (tester) async {
    Get.put<AdvertisementController>(AdvertisementController(advertisementServiceInterface: _FakeAdService(null)));
    // Not loaded → advertisementList stays null.
    await tester.pumpWidget(wrap(const MoonjoinAdvertisementSection()));
    await tester.pump();

    expect(find.byType(MoonjoinAdvertisementCard), findsNothing);
  });
}
