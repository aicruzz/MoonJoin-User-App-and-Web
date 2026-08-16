import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_flash_deal_card.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_flash_deals_section.dart';
import 'package:sixam_mart/features/flash_sale/controllers/flash_sale_controller.dart';
import 'package:sixam_mart/features/flash_sale/domain/models/flash_sale_model.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/features/flash_sale/widgets/timer_widget.dart';

/// Module Flash Sale (Food/Grocery/Fashion/…) rendered with the approved
/// MoonJoin Flash Deals presentation (`MoonjoinFlashDealsSection` +
/// `MoonjoinFlashDealCard`). PRESENTATION ONLY — all data, discount, stock,
/// duration/countdown, pageIndex and navigation come from the unchanged
/// `FlashSaleController`/models exactly as before.
class FlashSaleViewWidget extends StatefulWidget {
  const FlashSaleViewWidget({super.key});

  @override
  State<FlashSaleViewWidget> createState() => _FlashSaleViewWidgetState();
}

class _FlashSaleViewWidgetState extends State<FlashSaleViewWidget> {

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FlashSaleController>(builder: (flashSaleController) {
      final FlashSaleModel? model = flashSaleController.flashSaleModel;
      if (model == null) return const FlashSaleShimmerView();

      final List<ActiveProducts>? products = model.activeProducts;
      if (products == null || products.isEmpty || (flashSaleController.duration?.inSeconds ?? 0) <= 1) {
        return const SizedBox();
      }

      return MoonjoinFlashDealsSection(
        title: 'flash_sale'.tr,
        subtitle: 'limited_time_offer'.tr,
        countdownDuration: flashSaleController.duration,
        onViewAll: () => Get.toNamed(RouteHelper.getFlashSaleDetailsScreen(products[0].flashSaleId!)),
        itemCount: products.length,
        initialPage: products.length > 1 ? 1 : 0,
        onPageChanged: (i) => flashSaleController.setPageIndex(i),
        itemBuilder: (context, index) => _card(context, products[index]),
      );
    });
  }

  Widget _card(BuildContext context, ActiveProducts activeProduct) {
    final Item item = activeProduct.item!;
    final double? startPrice = Get.find<ItemController>().getStartingPrice(item);
    final bool hasDiscount = item.discount != null && item.discount! > 0;
    final int stock = activeProduct.stock ?? 0;
    final int sold = activeProduct.sold ?? 0;
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
      onTap: () => Get.find<ItemController>().navigateToItemPage(item, context),
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
}

class FlashSaleShimmerView extends StatelessWidget {
  const FlashSaleShimmerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Get.width, height: ResponsiveHelper.isDesktop(context) ? 330 : 350,
      margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Shimmer(
        duration: const Duration(seconds: 2),
        enabled: true,
        child: Column(children: [

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('flash_sale'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                ResponsiveHelper.isDesktop(context) ? const SizedBox() : Text('limited_time_offer'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
              ],
              ),
              const Spacer(),

              Row(children: [

                TimerWidget(
                  timeCount: 00,
                  timeUnit: 'days'.tr,
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                TimerWidget(
                  timeCount: 00,
                  timeUnit: 'hours'.tr,
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                TimerWidget(
                  timeCount: 00,
                  timeUnit: 'mins'.tr,
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),

                TimerWidget(
                  timeCount: 00,
                  timeUnit: 'sec'.tr,
                ),

              ])
            ]),
          ),

          Container(
            height: ResponsiveHelper.isDesktop(context) ? 150 : 170, width: Get.width * 0.7,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Container(
            height: 10, width: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Container(
            height: 10, width: 200,
            color: Colors.grey[300],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Container(
            height: 10, width: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
        ),
      ),
    );
  }
}
