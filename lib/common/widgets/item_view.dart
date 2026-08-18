import 'package:moonjoin/common/models/module_model.dart';
import 'package:moonjoin/common/widgets/card_design/store_card_with_distance.dart';
import 'package:moonjoin/common/widgets/web_item_widget.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/features/store/widgets/moonjoin_store_card.dart';
import 'package:moonjoin/features/home/widgets/web/widgets/store_card_widget.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/common/widgets/no_data_screen.dart';
import 'package:moonjoin/common/widgets/item_shimmer.dart';
import 'package:moonjoin/common/widgets/item_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ItemsView extends StatefulWidget {
  final List<Item?>? items;
  final List<Store?>? stores;
  final bool isStore;
  final EdgeInsetsGeometry padding;
  final bool isScrollable;
  final int shimmerLength;
  final String? noDataText;
  final bool isCampaign;
  final bool inStorePage;
  final bool isFeatured;
  final bool? isFoodOrGrocery;
  /// Hide the store name under item titles (Item Search/List screen only).
  final bool hideItemStoreName;
  /// Render item cards in the premium Store-page dish layout (Store page only).
  final bool premiumStoreLayout;
  const ItemsView({super.key, required this.stores, required this.items, required this.isStore, this.isScrollable = false,
    this.shimmerLength = 20, this.padding = const EdgeInsets.all(Dimensions.paddingSizeDefault), this.noDataText,
    this.isCampaign = false, this.inStorePage = false, this.isFeatured = false,
    this.isFoodOrGrocery = true, this.hideItemStoreName = false, this.premiumStoreLayout = false});

  @override
  State<ItemsView> createState() => _ItemsViewState();
}

class _ItemsViewState extends State<ItemsView> {
  @override
  Widget build(BuildContext context) {
    bool isNull = true;
    int length = 0;
    if(widget.isStore) {
      isNull = widget.stores == null;
      if(!isNull) {
        length = widget.stores!.length;
      }
    }else {
      isNull = widget.items == null;
      if(!isNull) {
        length = widget.items!.length;
      }
    }

    return Column(children: [

      !isNull ? length > 0
      // Mobile store/restaurant lists reuse the approved All Restaurants card
      // ([MoonjoinStoreCard]) so every listing shares one visual implementation.
      // Desktop keeps its existing store cards; item lists are unchanged.
      ? (widget.isStore && widget.stores != null && !ResponsiveHelper.isDesktop(context))
        ? _moonjoinStoreList(context, length)
        // Premium Store-page dish list: intrinsic-height ItemWidget cards (no
        // fixed-grid clipping). Mobile item lists on the Store page only.
        : (widget.premiumStoreLayout && !widget.isStore && !ResponsiveHelper.isDesktop(context))
        ? _premiumItemList(context, length)
        : GridView.builder(
        key: UniqueKey(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtremeLarge : widget.stores != null ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeLarge,
          mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtremeLarge : widget.stores != null && widget.isStore ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
          mainAxisExtent: ResponsiveHelper.isDesktop(context) && widget.isStore ? 220
          : ResponsiveHelper.isMobile(context) ? widget.stores != null && widget.isStore ? 200 : 122
          : ResponsiveHelper.isDesktop(context) ? 300 : 122,
          crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : ResponsiveHelper.isDesktop(context) && widget.stores != null  ? 3 : ResponsiveHelper.isDesktop(context) ? 4 : 3,
        ),
        physics: widget.isScrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
        shrinkWrap: widget.isScrollable ? false : true,
        itemCount: length,
        padding: widget.padding,
        itemBuilder: (context, index) {
          return widget.stores != null && widget.isStore ?  widget.isFoodOrGrocery! && widget.isStore ? StoreCardWidget(store: widget.stores![index])
            : StoreCardWithDistance(store: widget.stores![index]!, fromAllStore: true)
            : !ResponsiveHelper.isDesktop(context) ? ItemWidget(
            isStore: widget.isStore, item: widget.isStore ? null : widget.items![index], isFeatured: widget.isFeatured,
            store: widget.isStore ? widget.stores![index] : null, index: index, length: length, isCampaign: widget.isCampaign,
            inStore: widget.inStorePage, hideItemStoreName: widget.hideItemStoreName, premiumStoreLayout: widget.premiumStoreLayout,
          ) : WebItemWidget(
            isStore: widget.isStore, item: widget.isStore ? null : widget.items![index], isFeatured: widget.isFeatured,
            store: widget.isStore ? widget.stores![index] : null, index: index, length: length, isCampaign: widget.isCampaign,
            inStore: widget.inStorePage,
          );
        },
      ) : NoDataScreen(
        text: widget.noDataText ?? (widget.isStore ? Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
            ? 'no_restaurant_available'.tr : 'no_store_available'.tr : 'no_item_available'.tr),
      ) : GridView.builder(
        key: UniqueKey(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeExtremeLarge : widget.stores != null ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeLarge,
          mainAxisSpacing: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : widget.stores != null ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall,
          mainAxisExtent: ResponsiveHelper.isDesktop(context) && widget.isStore ? 220 : ResponsiveHelper.isMobile(context) ? widget.isStore ? 200 : 110 : 110,
          crossAxisCount: ResponsiveHelper.isMobile(context) ? 1 : ResponsiveHelper.isDesktop(context) ? 3 : 3,
        ),
        physics: widget.isScrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
        shrinkWrap: widget.isScrollable ? false : true,
        itemCount: widget.shimmerLength,
        padding: widget.padding,
        itemBuilder: (context, index) {
          return widget.isStore ? widget.isFoodOrGrocery! ? const StoreCardShimmer()
          : const NewOnShimmerView()
          : ItemShimmer(isEnabled: isNull, isStore: widget.isStore, hasDivider: index != widget.shimmerLength-1);
        },
      ),

    ]);
  }

  /// Premium Store-page dish list: the shared [ItemWidget] in its
  /// `premiumStoreLayout` mode, in an intrinsic-height [ListView] (cards size to
  /// content — no fixed-grid overflow). Store page only; same widget, no fork.
  Widget _premiumItemList(BuildContext context, int length) {
    return ListView.separated(
      key: UniqueKey(),
      physics: widget.isScrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      shrinkWrap: !widget.isScrollable,
      itemCount: length,
      padding: widget.padding,
      separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
      itemBuilder: (context, index) {
        return ItemWidget(
          isStore: false, item: widget.items![index], store: null, index: index, length: length,
          isCampaign: widget.isCampaign, inStore: widget.inStorePage, premiumStoreLayout: true,
        );
      },
    );
  }

  /// Mobile store/restaurant list rendered with the shared [MoonjoinStoreCard]
  /// (intrinsic height like the All Restaurants list — no fixed-grid clipping).
  Widget _moonjoinStoreList(BuildContext context, int length) {
    // Open stores first, closed after (reuses the existing open/close calc).
    final List<Store> stores = Get.find<StoreController>().sortStoresOpenFirst(widget.stores!.whereType<Store>().toList());
    return ListView.separated(
      key: UniqueKey(),
      physics: widget.isScrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
      shrinkWrap: !widget.isScrollable,
      itemCount: stores.length,
      padding: widget.padding,
      separatorBuilder: (context, index) => const SizedBox(height: Dimensions.paddingSizeDefault),
      itemBuilder: (context, index) {
        final Store store = stores[index];
        return MoonjoinStoreCard(store: store, onTap: () => _openStore(store));
      },
    );
  }

  /// Open a store — activate its module first, then push its page. Mirrors the
  /// existing store-card navigation used across the app (no new behaviour).
  void _openStore(Store store) {
    for (ModuleModel module in Get.find<SplashController>().moduleList ?? []) {
      if (module.id == store.moduleId) {
        Get.find<SplashController>().setModule(module);
        break;
      }
    }
    Get.toNamed(RouteHelper.getStoreRoute(id: store.id, page: 'store'));
  }
}

class NewOnShimmerView extends StatelessWidget {
  const NewOnShimmerView({super.key, });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.zero,
      child: Stack(children: [
        Container(
          // width: fromAllStore ?  MediaQuery.of(context).size.width : 260,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Column(children: [
            Expanded(
              flex: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusDefault), topRight: Radius.circular(Dimensions.radiusDefault)),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    height: double.infinity, width: double.infinity,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  ),

                  Positioned(
                    top: 15, right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
                      ),
                      child: Icon(Icons.favorite_border, color: Theme.of(context).primaryColor, size: 20),
                    ),
                  ),
                ]),
              ),
            ),

            Expanded(
              flex: 1,
              child: Column(children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 95),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(
                        child: Container(
                          height: 5, width: 100,
                          color: Theme.of(context).cardColor,
                        ),
                      ),
                      const SizedBox(height: 2),

                      Row(children: [
                        const Icon(Icons.location_on_outlined, color: Colors.blue, size: 15),
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                        Expanded(
                          child: Container(
                            height: 10, width: 100,
                            color: Theme.of(context).cardColor,
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),

                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(
                        height: 10, width: 70,
                        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                        ),
                      ),

                      Container(
                        height: 20, width: 65,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          ]),
        ),

        Positioned(
          top: 60, left: 15,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 65, width: 65,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

