import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:moonjoin/common/widgets/custom_app_bar.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_flash_deal_card.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_flash_deals_section.dart';
import 'package:moonjoin/common/widgets/paginated_list_view.dart';
import 'package:moonjoin/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:moonjoin/features/flash_sale/domain/models/product_flash_sale.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/helper/price_converter.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';

/// View All Flash Sale page — redesigned to the MoonJoin Flash Deals design
/// language (premium pale-green header with the shared ticking countdown + a
/// responsive list of the approved `MoonjoinFlashDealCard`). PRESENTATION ONLY:
/// the controller, `getFlashSaleWithId` pagination, campaign end-time, discount/
/// stock/sold data and item navigation are all unchanged.
class FlashSaleDetailsScreen extends StatefulWidget {
  final int id;
  const FlashSaleDetailsScreen({super.key, required this.id});

  @override
  State<FlashSaleDetailsScreen> createState() => _FlashSaleDetailsScreenState();
}

class _FlashSaleDetailsScreenState extends State<FlashSaleDetailsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Get.find<FlashSaleController>().getFlashSaleWithId(1, false, widget.id);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      // Approved MoonJoin header language (same as the Favourite page): green
      // ProfilePageHeader on mobile, legacy CustomAppBar on desktop.
      appBar: isDesktop ? CustomAppBar(title: 'flash_sale'.tr) : null,
      body: Center(
        child: GetBuilder<FlashSaleController>(builder: (flashSaleController) {
          final ProductFlashSale? data = flashSaleController.productFlashSale;
          return Column(children: [

            if (!isDesktop) ProfilePageHeader(title: 'flash_sale'.tr, showBack: true),
            _countdownStrip(context, data),

            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: FooterView(
                  child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: PaginatedListView(
                      scrollController: _scrollController,
                      totalSize: data?.totalSize,
                      offset: data?.offset,
                      onPaginate: (int? offset) async => await flashSaleController.getFlashSaleWithId(offset!, false, widget.id),
                      itemView: data != null
                          ? GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: ResponsiveHelper.isDesktop(context) ? 2 : ResponsiveHelper.isTab(context) ? 2 : 1,
                                crossAxisSpacing: Dimensions.paddingSizeDefault,
                                mainAxisSpacing: Dimensions.paddingSizeDefault,
                                mainAxisExtent: 185,
                              ),
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: data.products!.length,
                              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                              itemBuilder: (context, index) => _card(context, data.products![index]),
                            )
                          : const _FlashListShimmer(),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        }),
      ),
    );
  }

  // Premium centred countdown strip under the MoonJoin green header — the SAME
  // ticking DAYS:HRS:MINS:SECS block used on the home Flash Deals section, driven
  // by the existing campaign end date (in sync with the home + controller).
  Widget _countdownStrip(BuildContext context, ProductFlashSale? data) {
    final DateTime? endTime = _campaignEnd(data?.flashSale?.endDate);
    if (endTime == null) return const SizedBox(height: Dimensions.paddingSizeSmall);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault, horizontal: Dimensions.paddingSizeLarge),
      child: Center(child: MoonjoinFlashCountdown(endTime: endTime)),
    );
  }

  Widget _card(BuildContext context, Products product) {
    final Item? item = product.item;
    if (item == null) return const SizedBox();
    final double? startPrice = Get.find<ItemController>().getStartingPrice(item);
    final bool hasDiscount = item.discount != null && item.discount! > 0;
    final int stock = product.stock ?? 0;
    final int sold = product.sold ?? 0;
    final int remaining = stock - sold;
    final int? soldPercent = stock > 0 ? ((sold / stock) * 100).round() : null;

    return MoonjoinFlashDealCard(
      image: item.imageFullUrl ?? '',
      badgeText: _badge(item),
      title: item.name ?? '',
      provider: item.storeName,
      flashPrice: PriceConverter.convertPrice(startPrice, discount: item.discount, discountType: item.discountType),
      originalPrice: hasDiscount ? PriceConverter.convertPrice(startPrice) : null,
      soldLabel: soldPercent != null ? '$soldPercent% ${'sold'.tr}' : null,
      soldFraction: stock > 0 ? (sold / stock) : null,
      onTap: remaining == 0 ? null : () => Get.find<ItemController>().navigateToItemPage(item, context),
    );
  }

  String _badge(Item item) {
    final double discount = item.discount ?? 0;
    if (discount <= 0) return 'flash_sale'.tr;
    if ((item.discountType ?? 'percent') == 'percent') {
      return '${discount.toStringAsFixed(0)}% ${'off'.tr}';
    }
    return '${PriceConverter.convertPrice(discount)} ${'off'.tr}';
  }

  /// The campaign end parsed exactly like FlashSaleController (UTC → local), so
  /// this page's countdown matches the home + controller semantics.
  DateTime? _campaignEnd(String? endDate) {
    if (endDate == null) return null;
    try {
      return DateFormat('yyyy-MM-ddTHH:mm:ss.SSS').parse(endDate, true).toLocal();
    } catch (_) {
      return DateTime.tryParse(endDate);
    }
  }
}

/// Premium loading state — a few wide flash-card placeholders matching the new
/// list layout.
class _FlashListShimmer extends StatelessWidget {
  const _FlashListShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveHelper.isDesktop(context) ? 2 : ResponsiveHelper.isTab(context) ? 2 : 1,
        crossAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisSpacing: Dimensions.paddingSizeDefault,
        mainAxisExtent: 185,
      ),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 6,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        enabled: true,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          ),
        ),
      ),
    );
  }
}
