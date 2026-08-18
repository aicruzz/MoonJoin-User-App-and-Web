import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/features/rental_module/provider_adapter/rental_provider_adapter.dart';
import 'package:moonjoin/features/rental_module/rental_favourite/controllers/taxi_favourite_controller.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// **Rental Provider banner — a visual clone of the approved `MoonjoinStoreCard`.**
///
/// This is an ADAPTER, not a new design. Every visual value here is copied from the
/// approved store/restaurant card so the two are pixel-identical: card radius
/// (`radiusExtraLarge`), shadow (black @6%, blur 10, offset 0,4), cover
/// `AspectRatio(2.55)`, badge geometry and colours, 42px circular logo at
/// `paddingSizeSmall` top-right, info-row padding, name/rating typography and colours,
/// and the bookmark in the same trailing position. No new styling values, no second
/// design language.
///
/// Only the BUSINESS DATA differs: `MoonjoinStoreCard` renders delivery concepts
/// (delivery time, free delivery, opening hours, closed state) which do not exist for
/// a rental provider. Those are replaced by the provider's real vehicle **feature
/// badges** (AC, Luxury, Petrol, Automatic, SUV, 5 Seats …), aggregated by
/// [RentalProviderAdapter] from real backend vehicle fields — never hardcoded.
///
/// The frozen `MoonjoinStoreCard` is NOT modified and Food is unaffected.
///
/// Permanent component: when the backend ships a Provider List endpoint, only the
/// adapter feeding this card changes. **This UI must not change.**
class RentalProviderCard extends StatelessWidget {
  final RentalProvider provider;
  final VoidCallback? onTap;
  const RentalProviderCard({super.key, required this.provider, this.onTap});

  // Same values as the approved MoonjoinStoreCard.
  static const Color _nameColor = Color(0xFF3F4044);
  static const Color _metaColor = Color(0xFFA9A9AC);

  String? _discountText() {
    final d = provider.discount;
    if (d == null || (d.discount ?? 0) <= 0) return null;
    if (d.discountType == 'percent') return '-${d.discount!.toStringAsFixed(0)}% OFF';
    return '-${d.discount!.toStringAsFixed(0)} OFF';
  }

  @override
  Widget build(BuildContext context) {
    final String? discount = _discountText();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

          /// Cover image + overlays — identical geometry to the approved card.
          AspectRatio(
            aspectRatio: 2.55,
            child: Stack(fit: StackFit.expand, children: [
              (provider.coverPhotoFullUrl != null && provider.coverPhotoFullUrl!.isNotEmpty)
                  ? CustomImage(image: provider.coverPhotoFullUrl!, fit: BoxFit.cover)
                  : Container(color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),

              // Discount badge (top-left)
              if (discount != null)
                Positioned(
                  top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall, right: 56,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _badge(discount, const Color(0xFF038840), Colors.white),
                  ]),
                ),

              // Logo (top-right)
              if (provider.logoFullUrl != null && provider.logoFullUrl!.isNotEmpty)
                Positioned(
                  top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
                  child: Container(
                    height: 42, width: 42,
                    decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                    padding: const EdgeInsets.all(2),
                    child: ClipOval(child: CustomImage(image: provider.logoFullUrl!, fit: BoxFit.cover)),
                  ),
                ),
            ]),
          ),

          /// Info row — name, rating, bookmark (approved layout/typography).
          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(provider.name, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: _nameColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  Row(children: [
                    Icon(Icons.star, size: 15, color: Colors.amber.shade600),
                    const SizedBox(width: 3),
                    Text('${provider.avgRating?.toStringAsFixed(1) ?? '0.0'}(${provider.ratingCount ?? 0}+)',
                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: _metaColor)),
                  ]),
                ]),
              ),
              _ProviderBookmarkButton(providerId: provider.id),
            ]),
          ),

          /// Feature badges — replaces the store card's delivery meta. Values come
          /// from the provider's real vehicles; the row is omitted when empty.
          if (provider.featureBadges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 0, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
              child: Wrap(
                spacing: Dimensions.paddingSizeExtraSmall,
                runSpacing: Dimensions.paddingSizeExtraSmall,
                children: provider.featureBadges.map((b) => _featureBadge(context, b)).toList(),
              ),
            ),
        ]),
      ),
    );
  }

  // Same badge geometry as the approved card.
  Widget _badge(String text, Color color, Color textColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(Dimensions.radiusMedium)),
    child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(color: textColor, fontSize: Dimensions.fontSizeSmall)),
  );

  Widget _featureBadge(BuildContext context, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: 5),
    decoration: BoxDecoration(
      color: Theme.of(context).disabledColor.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(Dimensions.radiusMedium),
    ),
    child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: _metaColor)),
  );
}

/// Bookmark toggle in the approved position, reusing the EXISTING rental provider
/// wish-list logic (`TaxiFavouriteController`, `isProvider: true`). No new logic.
class _ProviderBookmarkButton extends StatelessWidget {
  final int providerId;
  const _ProviderBookmarkButton({required this.providerId});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<TaxiFavouriteController>(builder: (favouriteController) {
      final bool isWished = favouriteController.wishProviderIdList.contains(providerId);
      return InkWell(
        onTap: () {
          if (isWished) {
            favouriteController.removeFromFavouriteList(providerId, true);
          } else {
            favouriteController.addToFavouriteList(vehicle: null, providerId: providerId, isProvider: true);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            isWished ? Icons.bookmark : Icons.bookmark_border,
            color: isWished ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
            size: 24,
          ),
        ),
      );
    });
  }
}
