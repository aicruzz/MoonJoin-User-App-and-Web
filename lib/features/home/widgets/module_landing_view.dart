import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_availability.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_components.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/home/widgets/module_view.dart' show ModuleShimmer;
import 'package:sixam_mart/features/home/widgets/special_offers_view.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// MoonJoin module-landing Home — a faithful reproduction of
/// `ui-designs/.../home.png`. Presentation only: every controller / repository /
/// service / route is reused unchanged.
///
/// Layout (top → bottom): green wavy header (greeting, location, notification,
/// cart, search) with the two featured modules straddling the wave → the
/// remaining modules in the design's 3·2·3… grouping → the "some items
/// unavailable" card (shown only for a real running order the vendor flagged) →
/// "Special Offers for You". Background is the design's pale-green `#F6F8F0`.
class ModuleLandingView extends StatelessWidget {
  final ScrollController? scrollController;
  const ModuleLandingView({super.key, this.scrollController});

  // Body background sampled from home.png.
  static const Color _bg = Color(0xFFF6F8F0);

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double topPad = MediaQuery.of(context).padding.top;
    final double greenHeight = topPad + 268;
    final double featuredSize = (width * 0.30).clamp(112.0, 150.0);
    final double normalSize = (width * 0.23).clamp(88.0, 112.0);
    // Vertical overflow of the featured tiles below the green header.
    final double featuredOverflow = featuredSize * 0.55 + 26;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: ColoredBox(
        color: _bg,
        child: GetBuilder<SplashController>(builder: (splashController) {
          final List<ModuleModel> modules = splashController.moduleList ?? [];
          final List<ModuleModel> featured = modules.take(2).toList();
          final List<ModuleModel> rest = modules.length > 2 ? modules.sublist(2) : [];
          final List<int> shapes = _assignShapes(modules);
          final List<int> restShapes = shapes.length > 2 ? shapes.sublist(2) : <int>[];

          return SingleChildScrollView(
            controller: scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              /// Green header + the two featured tiles straddling the wave
              Stack(clipBehavior: Clip.none, children: [
                _header(context, splashController, greenHeight),
                if (featured.isNotEmpty)
                  Positioned(
                    left: Dimensions.paddingSizeDefault, right: Dimensions.paddingSizeDefault,
                    top: greenHeight - featuredSize * 0.5 - 18,
                    child: _RowOfTiles(
                      modules: featured, baseIndex: 0, size: featuredSize,
                      gap: width * 0.08, splashController: splashController,
                      shapeIndices: shapes.take(2).toList(),
                      artworkFraction: 0.93,
                    ),
                  ),
                if (modules.isEmpty)
                  Positioned(left: 0, right: 0, top: greenHeight + 10, child: ModuleShimmer(isEnabled: true)),
              ]),

              SizedBox(height: featuredOverflow),

              /// Remaining modules in the design's 3·2·3… grouping
              ..._buildRestRows(context, rest, restShapes, normalSize, width, splashController),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              /// "Some items are unavailable" — real running-order flag only
              _unavailableCard(),

              /// Special Offers
              Padding(
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
                child: SectionHeader(
                  title: 'special_offers_for_you'.tr,
                  actionText: 'see_all'.tr,
                  onActionTap: () => Get.toNamed(RouteHelper.getCouponRoute()),
                ),
              ),
              const SpecialOffersView(),

              const SizedBox(height: 110),
            ]),
          );
        }),
      ),
    );
  }

  Widget _header(BuildContext context, SplashController splashController, double height) {
    return GetBuilder<NotificationController>(builder: (notificationController) {
      return GetBuilder<CartController>(builder: (cartController) {
        final hour = DateTime.now().hour;
        final greeting = hour < 12 ? 'good_morning'.tr : hour < 17 ? 'good_afternoon'.tr : 'good_evening'.tr;
        final name = AuthHelper.isLoggedIn() ? (Get.find<ProfileController>().userInfoModel?.fName ?? '') : 'guest'.tr;
        final address = AddressHelper.getUserAddressFromSharedPref()?.address ?? 'your_location'.tr;

        return MoonjoinModuleHeader(
          height: height,
          notchCenters: const [0.29, 0.71],
          greeting: '$greeting,',
          userName: '$name 👋',
          locationText: address,
          onLocationTap: () => Get.find<LocationController>().navigateToLocationScreen('home'),
          notificationCount: notificationController.notificationList?.length ?? 0,
          cartCount: cartController.cartList.length,
          onNotificationTap: () => Get.toNamed(RouteHelper.getNotificationRoute()),
          onCartTap: () => Get.toNamed(RouteHelper.getCartRoute()),
          searchBar: MoonjoinSearchBar(
            hintText: 'search_for_food_groceries_shops'.tr,
            readOnly: true,
            onTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
            onFilterTap: () => Get.toNamed(RouteHelper.getSearchRoute()),
          ),
        );
      });
    });
  }

  /// Groups the remaining modules into rows sized 3, 2, 3, 2, … (the design's
  /// grouping after the two featured modules).
  List<Widget> _buildRestRows(BuildContext context, List<ModuleModel> rest, List<int> restShapes, double size, double width, SplashController splashController) {
    final List<Widget> rows = [];
    int i = 0;
    bool three = true; // first row after featured is 3-wide
    int baseIndex = 2;
    while (i < rest.length) {
      final int count = three ? 3 : 2;
      final int end = (i + count).clamp(0, rest.length);
      final chunk = rest.sublist(i, end);
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeExtraLarge),
        child: _RowOfTiles(
          modules: chunk, baseIndex: baseIndex, size: size,
          gap: width * 0.10, splashController: splashController,
          shapeIndices: restShapes.sublist(i, end),
        ),
      ));
      i += chunk.length;
      baseIndex += chunk.length;
      three = !three;
    }
    return rows;
  }

  /// Deterministically assigns a stable organic shape to each module (by id),
  /// never repeating the shape of the immediately-preceding module.
  List<int> _assignShapes(List<ModuleModel> modules) {
    final List<int> result = [];
    for (final m in modules) {
      int idx = (m.id ?? result.length).abs() % OrganicModuleIcon.shapeCount;
      if (result.isNotEmpty && idx == result.last) {
        idx = (idx + 1) % OrganicModuleIcon.shapeCount;
      }
      result.add(idx);
    }
    return result;
  }

  Widget _unavailableCard() {
    return GetBuilder<OrderController>(builder: (orderController) {
      OrderModel? flagged;
      final orders = orderController.runningOrderModel?.orders;
      if (orders != null) {
        for (final o in orders) {
          // Reviewable = a still-pending order the vendor flagged with an
          // unavailable-item note. Resolved/advanced orders drop off automatically.
          if (o.orderStatus == 'pending' && (o.unavailableItemNote ?? '').trim().isNotEmpty) { flagged = o; break; }
        }
      }
      if (flagged == null) return const SizedBox();
      final int? orderId = flagged.id;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
        child: _UnavailableItemsCard(
          onReview: () => Get.toNamed(RouteHelper.getOrderDetailsRoute(orderId)),
        ),
      );
    });
  }
}

/// Staggered entrance animation for a module tile: fade in + scale 0.92→1.0 +
/// rise ~8px, ease-out. Fires once on first build (when Home opens after an
/// address is selected, or on reopening Home) with a per-index delay so tiles
/// appear left→right, top→bottom. State persists across GetBuilder rebuilds, so
/// it does not replay while scrolling.
class _AnimatedTile extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedTile({required this.index, required this.child});

  @override
  State<_AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<_AnimatedTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 280),
  );

  @override
  void initState() {
    super.initState();
    // Per-tile delay (~48ms) → total for 10 tiles ≈ 9*48 + 280 ≈ 692ms (<700ms).
    Future.delayed(Duration(milliseconds: widget.index * 48), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = Curves.easeOut.transform(_controller.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - t)),
            child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// A single row of module tiles: 3-wide rows spread evenly, 2-wide rows centred
/// as a pair — matching the reference.
class _RowOfTiles extends StatelessWidget {
  final List<ModuleModel> modules;
  final int baseIndex;
  final double size;
  final double gap;
  final SplashController splashController;
  final List<int> shapeIndices;
  final double artworkFraction;
  const _RowOfTiles({required this.modules, required this.baseIndex, required this.size, required this.gap, required this.splashController, required this.shapeIndices, this.artworkFraction = 0.89});

  @override
  Widget build(BuildContext context) {
    final tiles = List.generate(modules.length, (i) {
      final m = modules[i];
      return _AnimatedTile(
        index: baseIndex + i,
        child: CategoryTile(
          label: m.moduleName ?? '',
          imageUrl: m.iconFullUrl,
          iconSize: size,
          shapeIndex: i < shapeIndices.length ? shapeIndices[i] : 0,
          artworkFraction: artworkFraction,
          availability: resolveModuleAvailability(m),
          onTap: () => _openModule(m, baseIndex + i),
        ),
      );
    });

    if (modules.length >= 3) {
      return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: tiles);
    }
    return _pairRow(tiles);
  }

  /// Storefront modules (food/grocery/pharmacy/ecommerce) open directly into the
  /// All Restaurants / All Stores list (the frozen AllStoreScreen) instead of the
  /// legacy promotional module home. Parcel and Rental keep their own homes.
  /// Module selection + data loading is the existing [SplashController.switchModule];
  /// only the landing destination changes (presentation/navigation, no logic added).
  Future<void> _openModule(ModuleModel m, int index) async {
    await splashController.switchModule(index, true);
    final String type = (m.moduleType ?? '').toLowerCase();
    const storefront = [AppConstants.food, AppConstants.grocery, AppConstants.pharmacy, AppConstants.ecommerce];
    if (storefront.contains(type)) {
      Get.toNamed(RouteHelper.getAllStoreRoute('all'));
    }
  }

  Widget _pairRow(List<Widget> tiles) {
    // 2 (or 1) tiles → centred as a pair with a fixed gap
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (int i = 0; i < tiles.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        tiles[i],
      ],
    ]);
  }
}

/// The "Some items are unavailable" notice card (reference: home.png / the
/// Edit-Unavailable-Items workflow). Cream surface, kraft-box icon with a red
/// badge, title + subtitle, and a green "Review Items" button.
class _UnavailableItemsCard extends StatelessWidget {
  final VoidCallback onReview;
  const _UnavailableItemsCard({required this.onReview});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: const Color(0xFFFBF3E2),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          const Icon(Icons.inventory_2_rounded, size: 40, color: Color(0xFFC98B3E)),
          Positioned(
            bottom: -2, left: -2,
            child: Container(
              height: 18, width: 18,
              decoration: const BoxDecoration(color: Color(0xFFE84D4F), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('some_items_are_unavailable'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall)),
            const SizedBox(height: 2),
            Text('review_and_edit_your_order_to_continue'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).hintColor)),
          ]),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        InkWell(
          onTap: onReview,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('review_items'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
              const Icon(Icons.chevron_right, color: Colors.white, size: 18),
            ]),
          ),
        ),
      ]),
    );
  }
}
