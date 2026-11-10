// Order details: "Your food will delivered within". When the store/Admin moves an
// order to processing, the backend saves the entered processing_time (minutes) and
// stamps the order's `processing` column at that moment (Admin/Vendor
// OrderController: `$order[$request->order_status] = now()`). The app added those
// minutes to created_at instead, so an order placed 40 minutes before Cooking was
// set with 30 minutes showed "1 - 5" (already past). The minutes now count from the
// `processing` timestamp; every other case is unchanged.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:moonjoin/common/models/config_model.dart';
import 'package:moonjoin/features/order/controllers/order_controller.dart';
import 'package:moonjoin/features/order/domain/models/order_details_model.dart';
import 'package:moonjoin/features/order/domain/models/order_model.dart';
import 'package:moonjoin/features/order/domain/services/order_service_interface.dart';
import 'package:moonjoin/features/order/widgets/order_banner_view_widget.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/splash/domain/services/splash_service_interface.dart';
import 'package:moonjoin/helper/date_converter.dart';

/// The backend's format for created_at (Order::getCreatedAtAttribute) and the
/// processing column: business-timezone wall time.
String _ago(int minutes) => DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().subtract(Duration(minutes: minutes)));

class _NoSuch {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(invocation.memberName.toString());
}

class _SplashService extends _NoSuch implements SplashServiceInterface {}

class _Splash extends SplashController {
  _Splash() : super(splashServiceInterface: _SplashService());
  @override
  Module getModuleConfig(String? moduleType) => Module(newVariation: true);
}

class _OrderService extends _NoSuch implements OrderServiceInterface {}

class _Orders extends OrderController {
  _Orders() : super(orderServiceInterface: _OrderService());
  @override
  List<OrderDetailsModel>? get orderDetails => <OrderDetailsModel>[];
}

/// The track payload's relevant part, as the customer app receives it.
OrderModel _order({required String status, required String createdAt, int? processingTime, String? processing, String? scheduleAt, String deliveryTime = '20-30 min'}) {
  return OrderModel.fromJson(<String, dynamic>{
    'id': 100010,
    'order_status': status,
    'created_at': createdAt,
    // Instant orders: the backend sets schedule_at = now() at placement (PlaceNewOrder).
    'schedule_at': scheduleAt ?? createdAt,
    'processing_time': processingTime,
    'processing': processing,
    'module_type': 'food',
    'order_amount': 5000, 'coupon_discount_amount': 0, 'total_tax_amount': 0, 'delivery_charge': 0, 'store_discount_amount': 0, 'dm_tips': 0,
    'store': <String, dynamic>{'id': 1, 'name': 'Perozona', 'delivery_time': deliveryTime, 'featured': 0},
  });
}

void main() {
  group('order payload', () {
    test('processing_time and the processing timestamp are parsed from the track payload', () {
      final String stamp = _ago(0);
      final OrderModel order = _order(status: 'processing', createdAt: _ago(40), processingTime: 30, processing: stamp);
      expect(order.processingTime, 30);
      expect(order.processing, stamp);
      expect(order.store!.deliveryTime, '20-30 min');
    });
  });

  group('DateConverter.differenceInMinute', () {
    test('processing with a processing time counts from when processing began (Order #100010 case)', () {
      final int minutes = DateConverter.differenceInMinute('20-30 min', _ago(40), 30, null, processingStartedAt: _ago(0));
      expect(minutes, inInclusiveRange(29, 30), reason: '30 minutes from now, not from when the order was placed');
    });

    test('the previous base (order time) is what produced "1 - 5"', () {
      final int minutes = DateConverter.differenceInMinute('20-30 min', _ago(40), 30, null);
      expect(minutes, lessThan(5));
    });

    test('a processing time set a while ago keeps counting down from that moment', () {
      final int minutes = DateConverter.differenceInMinute('20-30 min', _ago(60), 30, null, processingStartedAt: _ago(12));
      expect(minutes, inInclusiveRange(17, 18));
    });

    test('no processing time yet (pending/confirmed): store delivery time from the order time, processing stamp ignored', () {
      final int minutes = DateConverter.differenceInMinute('20-30 min', _ago(5), null, null, processingStartedAt: _ago(0));
      expect(minutes, inInclusiveRange(14, 15));
    });

    test('processing time without a usable processing timestamp falls back to the order time', () {
      expect(DateConverter.differenceInMinute('20-30 min', _ago(10), 30, null), inInclusiveRange(19, 20));
      expect(DateConverter.differenceInMinute('20-30 min', _ago(10), 30, null, processingStartedAt: ''), inInclusiveRange(19, 20));
      expect(DateConverter.differenceInMinute('20-30 min', _ago(10), 30, null, processingStartedAt: 'not a date'), inInclusiveRange(19, 20));
    });

    test('a scheduled order without processing still counts from the schedule time', () {
      final int minutes = DateConverter.differenceInMinute('20-30 min', _ago(90), null, _ago(5));
      expect(minutes, inInclusiveRange(14, 15));
    });
  });

  group('order details banner', () {
    setUp(() {
      Get.testMode = true;
      Get.put<SplashController>(_Splash());
    });

    tearDown(Get.reset);

    Future<void> pumpBanner(WidgetTester tester, OrderModel order) async {
      await tester.pumpWidget(GetMaterialApp(home: Scaffold(body: SingleChildScrollView(
        child: OrderBannerViewWidget(order: order, ongoing: true, parcel: false, prescriptionOrder: false, orderController: _Orders()),
      ))));
    }

    testWidgets('Cooking set to 30 minutes on an order placed 40 minutes ago shows 25 - 30 / 24 - 29, not 1 - 5', (WidgetTester tester) async {
      await pumpBanner(tester, _order(status: 'processing', createdAt: _ago(40), processingTime: 30, processing: _ago(0)));
      expect(find.text('1 - 5'), findsNothing);
      expect(find.byWidgetPredicate((Widget w) => w is Text && (w.data == '25 - 30' || w.data == '24 - 29')), findsOneWidget);
    });

    testWidgets('a processing time that has genuinely run out still shows 1 - 5', (WidgetTester tester) async {
      await pumpBanner(tester, _order(status: 'processing', createdAt: _ago(70), processingTime: 30, processing: _ago(40)));
      expect(find.text('1 - 5'), findsOneWidget);
    });

    testWidgets('pending order without a processing time is unchanged: store delivery time from the order time', (WidgetTester tester) async {
      await pumpBanner(tester, _order(status: 'pending', createdAt: _ago(5), deliveryTime: '20-30 min'));
      expect(find.byWidgetPredicate((Widget w) => w is Text && (w.data == '10 - 15' || w.data == '9 - 14')), findsOneWidget);
    });

    testWidgets('handover after processing keeps the processing-based estimate', (WidgetTester tester) async {
      await pumpBanner(tester, _order(status: 'handover', createdAt: _ago(50), processingTime: 30, processing: _ago(10)));
      expect(find.byWidgetPredicate((Widget w) => w is Text && (w.data == '15 - 20' || w.data == '14 - 19')), findsOneWidget);
    });
  });
}
