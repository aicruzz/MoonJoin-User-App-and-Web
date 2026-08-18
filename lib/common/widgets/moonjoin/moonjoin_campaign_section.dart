import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_campaign_card.dart';
import 'package:moonjoin/features/item/controllers/campaign_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Campaigns section — the item-campaign promotion as a premium MoonJoin
/// promotional module (ui-designs/campaign.png): a pale-green organic surface with
/// a bold title + subtitle, a circular View All button, and a horizontal carousel
/// of large `MoonjoinCampaignCard` product cards (next card peeks).
///
/// PRESENTATION ONLY and SHARED by the Flutter User App (AllStoreScreen) and the
/// Web home (WebNewHomeScreen): it consumes the existing `CampaignController`
/// (`itemCampaignList`), self-hides when there are no active campaign items, shows
/// a shimmer while loading, and its View All keeps the existing
/// `RouteHelper.getItemCampaignRoute()` → `ItemCampaignScreen` flow. No fetch is
/// triggered here (the home lifecycle already loads it). Responsive card scale.
class MoonjoinCampaignSection extends StatelessWidget {
  const MoonjoinCampaignSection({super.key});

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    final double cardWidth = isDesktop ? 200 : 160;
    // Card height = square image (cardWidth) + store name + 2-line item name + price.
    final double carouselHeight = cardWidth + 96;

    return GetBuilder<CampaignController>(builder: (campaignController) {
      final List<Item>? items = campaignController.itemCampaignList;
      if (items != null && items.isEmpty) return const SizedBox();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
        child: Stack(children: [

          // Approved pale-green organic MoonJoin promotional surface.
          Positioned.fill(
            child: ClipPath(
              clipper: _CampaignClipper(),
              child: Container(color: green.withValues(alpha: 0.08)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 24, Dimensions.paddingSizeDefault, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

              _header(context, green),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              SizedBox(
                height: carouselHeight,
                child: items != null
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.zero,
                        clipBehavior: Clip.none,
                        itemCount: items.length > 10 ? 10 : items.length,
                        separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeDefault),
                        itemBuilder: (context, index) => MoonjoinCampaignCard(item: items[index], width: cardWidth),
                      )
                    : _CampaignShimmer(cardWidth: cardWidth),
              ),
            ]),
          ),
        ]),
      );
    });
  }

  Widget _header(BuildContext context, Color green) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('campaigns'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge)),
          Text('limited_time_offer'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
        ]),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      InkWell(
        onTap: () => Get.toNamed(RouteHelper.getItemCampaignRoute()),
        customBorder: const CircleBorder(),
        child: Container(
          height: 44, width: 44, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor, shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: Icon(Icons.arrow_forward, color: green, size: 20),
        ),
      ),
    ]);
  }
}

class _CampaignShimmer extends StatelessWidget {
  final double cardWidth;
  const _CampaignShimmer({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(width: Dimensions.paddingSizeDefault),
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: cardWidth, width: cardWidth,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Container(height: 10, width: cardWidth * 0.6, color: Colors.grey[300]),
          const SizedBox(height: 6),
          Container(height: 12, width: cardWidth * 0.85, color: Colors.grey[300]),
        ]),
      ),
    );
  }
}

/// Organic wavy background — the same soft MoonJoin promotional silhouette used by
/// the other promo modules, kept self-contained so no frozen component is touched.
class _CampaignClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width, h = size.height;
    const double r = 28, topWave = 14, botWave = 16;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..cubicTo(w * 0.30, 0, w * 0.34, topWave, w * 0.5, topWave)
      ..cubicTo(w * 0.66, topWave, w * 0.70, 0, w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..cubicTo(w * 0.70, h, w * 0.66, h - botWave, w * 0.5, h - botWave)
      ..cubicTo(w * 0.34, h - botWave, w * 0.30, h, r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
