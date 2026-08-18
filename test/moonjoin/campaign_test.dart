import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/enums/data_source_enum.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_campaign_card.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_campaign_section.dart';
import 'package:moonjoin/features/item/controllers/campaign_controller.dart';
import 'package:moonjoin/features/item/domain/models/basic_campaign_model.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/item/domain/services/campaign_service_interface.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';

// Behavioural guards for the shared MoonJoin Campaign section: it self-hides when
// there are no active campaign items and shows a loading state while the list is
// null (matching the other MoonJoin promotional modules). Card pricing/rendering
// reuses the existing ItemController + PriceConverter and is verified on device/web.

class _FakeCampaignService implements CampaignServiceInterface {
  final List<Item>? items;
  _FakeCampaignService(this.items);
  @override
  Future<List<Item>?> getItemCampaignList(DataSourceEnum dataSource) async => items;
  @override
  Future<List<BasicCampaignModel>?> getBasicCampaignList(DataSourceEnum source) async => null;
  @override
  Future<BasicCampaignModel?> getCampaignDetails(String campaignID) async => null;
}

void main() {
  tearDown(Get.reset);

  group('Item campaign.store parsing (backend with(store) contract)', () {
    test('parses nested store (id/name/logo) when present', () {
      final item = Item.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Papas', 'price': 2000, 'discount': 20, 'discount_type': 'percent',
        'store_id': 7, 'store_name': 'Bukka Hut',
        'store': {'id': 7, 'name': 'Bukka Hut', 'logo_full_url': 'https://x/logo.png', 'featured': 1},
      });
      expect(item.store, isNotNull);
      expect(item.store!.id, 7);
      expect(item.store!.logoFullUrl, 'https://x/logo.png');
    });

    test('a malformed/partial store never breaks item parsing (defensive)', () {
      // Missing `featured` → Store.fromJson would throw; item.store must be null,
      // and the rest of the item must still parse.
      final item = Item.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Papas', 'price': 2000, 'discount': 20, 'discount_type': 'percent',
        'store_id': 7, 'store_name': 'Bukka Hut', 'store': {'id': 7, 'name': 'Bukka Hut'},
      });
      expect(item.store, isNull);
      expect(item.name, 'Papas');
      expect(item.storeName, 'Bukka Hut');
    });

    test('store is null (defensive) when the response omits it', () {
      final item = Item.fromJson(<String, dynamic>{
        'id': 1, 'name': 'Papas', 'price': 2000, 'discount': 20, 'discount_type': 'percent',
        'store_id': 7, 'store_name': 'Bukka Hut',
      });
      expect(item.store, isNull);
      expect(item.storeName, 'Bukka Hut'); // flat field still works
    });
  });

  group('campaign store-logo resolution (owning store → real logo)', () {
    Store store(int id, String? logo) => Store(id: id, logoFullUrl: logo);

    test('prefers campaign.store logo (primary/forward-looking source)', () {
      final logo = resolveCampaignStoreLogo(
        directLogo: 'https://x/campaign-store.png', storeId: 7,
        loadedStores: [[store(7, 'https://x/loaded.png')]],
      );
      expect(logo, 'https://x/campaign-store.png');
    });

    test('falls back to the loaded owning store matched by storeId', () {
      final logo = resolveCampaignStoreLogo(
        directLogo: null, storeId: 7,
        loadedStores: [[store(3, 'https://x/other.png')], [store(7, 'https://x/bukka.png')]],
      );
      expect(logo, 'https://x/bukka.png');
    });

    test('returns null (badge omitted) when no store matches and no direct logo', () {
      final logo = resolveCampaignStoreLogo(
        directLogo: null, storeId: 99,
        loadedStores: [[store(3, 'https://x/other.png')], null],
      );
      expect(logo, isNull);
    });

    test('never fabricates a logo when the matched store has none', () {
      final logo = resolveCampaignStoreLogo(
        directLogo: null, storeId: 7, loadedStores: [[store(7, '')]],
      );
      expect(logo, isNull);
    });
  });

  Widget wrap(Widget child) => GetMaterialApp(
        theme: ThemeData(primaryColor: const Color(0xFF13A452), disabledColor: Colors.grey),
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );

  testWidgets('section self-hides when there are no active campaign items', (tester) async {
    Get.put<CampaignController>(CampaignController(campaignServiceInterface: _FakeCampaignService(<Item>[])));
    await Get.find<CampaignController>().getItemCampaignList(false);

    await tester.pumpWidget(wrap(const MoonjoinCampaignSection()));
    await tester.pump();

    expect(find.byType(MoonjoinCampaignCard), findsNothing);
    expect(find.text('campaigns'), findsNothing); // no header when self-hidden
  });

  testWidgets('section shows a loading state while the list is null', (tester) async {
    Get.put<CampaignController>(CampaignController(campaignServiceInterface: _FakeCampaignService(null)));
    // Not loaded → itemCampaignList stays null → header + shimmer, no cards.
    await tester.pumpWidget(wrap(const MoonjoinCampaignSection()));
    await tester.pump();

    expect(find.byType(MoonjoinCampaignCard), findsNothing);
    expect(find.text('campaigns'), findsOneWidget); // header shows; shimmer below
  });
}
