import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_top_brand_card.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// One presentation item for the shared Top Brands row. Each module maps its OWN
/// brand/store data onto this — the shared widget never reaches into any controller.
class MoonjoinTopBrandItem {
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;
  const MoonjoinTopBrandItem({required this.name, this.imageUrl, this.onTap});
}

/// The ONE approved MoonJoin **Top Brands presentation** (ui-designs/Top_Brands.png),
/// extracted from the frozen Food Top Brands so every module shares one visual:
/// compact **near-square rounded** brand cards whose surface is the vendor-uploaded
/// image (`BoxFit.cover`, rounded-clipped — no palette/generated colour), **exactly
/// four complete cards across a phone**, brand name at the bottom, a "Top Brands"
/// heading and an optional green "See all".
///
/// PRESENTATION ONLY. Callers pass their own [items] (name/image/onTap), [title] and
/// optional [onSeeAll]; this widget owns only card sizing, spacing, rounded corners,
/// name treatment, responsive layout, the header and the loading shimmer. It self-
/// hides on an empty list and shows a shimmer while [items] is null (loading).
class MoonjoinTopBrandsSection extends StatelessWidget {
  final String title;
  final List<MoonjoinTopBrandItem>? items; // null → loading shimmer
  final VoidCallback? onSeeAll;             // null → no "See all"
  const MoonjoinTopBrandsSection({super.key, required this.title, required this.items, this.onSeeAll});

  static const double _hPadding = Dimensions.paddingSizeDefault; // row side padding
  static const double _gap = Dimensions.paddingSizeSmall;        // gap between cards

  /// Compact card width: exactly FOUR complete cards across the viewport (4 cards +
  /// 3 gaps + 2 side paddings == width). Card is near-square (height == width).
  /// Capped so wide web layouts don't blow the cards up (there the row shows > 4).
  double _cardWidth(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;
    return ((w - (_hPadding * 2) - (_gap * 3)) / 4).clamp(70.0, 120.0);
  }

  @override
  Widget build(BuildContext context) {
    if (items != null && items!.isEmpty) return const SizedBox();
    final Color green = Theme.of(context).primaryColor;
    final double cardW = _cardWidth(context);
    final double rowH = cardW; // near-square card (ui-designs/Top_Brands.png)

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Padding(
        padding: const EdgeInsets.fromLTRB(_hPadding, Dimensions.paddingSizeSmall, _hPadding, Dimensions.paddingSizeSmall),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('see_all'.tr, style: robotoMedium.copyWith(color: green, fontSize: Dimensions.fontSizeSmall)),
                Icon(Icons.chevron_right, size: 18, color: green),
              ]),
            ),
        ]),
      ),

      SizedBox(
        height: rowH,
        child: items != null
            ? ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: _hPadding),
                itemCount: items!.length,
                separatorBuilder: (context, index) => const SizedBox(width: _gap),
                itemBuilder: (context, index) {
                  final MoonjoinTopBrandItem it = items![index];
                  return MoonjoinTopBrandCard(name: it.name, imageUrl: it.imageUrl, width: cardW, onTap: it.onTap);
                },
              )
            : _TopBrandsShimmer(cardWidth: cardW),
      ),
    ]);
  }
}

class _TopBrandsShimmer extends StatelessWidget {
  final double cardWidth;
  const _TopBrandsShimmer({required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(width: Dimensions.paddingSizeSmall),
      itemBuilder: (context, index) => Shimmer(
        duration: const Duration(seconds: 2),
        child: Container(
          width: cardWidth,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
        ),
      ),
    );
  }
}
