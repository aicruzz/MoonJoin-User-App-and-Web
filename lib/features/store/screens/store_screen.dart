import 'package:flutter/rendering.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/category/controllers/category_controller.dart';
import 'package:moonjoin/features/checkout/controllers/checkout_controller.dart';
import 'package:moonjoin/features/store/controllers/store_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/category/domain/models/category_model.dart';
import 'package:moonjoin/features/item/domain/models/item_model.dart';
import 'package:moonjoin/features/store/domain/models/store_model.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/price_converter.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/item_view.dart';
import 'package:moonjoin/common/widgets/item_widget.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/paginated_list_view.dart';
import 'package:moonjoin/common/widgets/web_item_view.dart';
import 'package:moonjoin/common/widgets/web_item_widget.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_sub_category_bar.dart';
import 'package:moonjoin/features/checkout/screens/checkout_screen.dart';
import 'package:moonjoin/features/store/widgets/store_banner_widget.dart';
import 'package:moonjoin/features/store/widgets/store_description_view_widget.dart';
import 'package:moonjoin/features/store/widgets/store_hero_header.dart';
import 'package:moonjoin/features/store/widgets/store_map_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/store/widgets/store_details_screen_shimmer_widget.dart';
import 'package:moonjoin/features/store/widgets/bottom_cart_widget.dart';
import 'package:moonjoin/features/store/widgets/filter_widget.dart';

class StoreScreen extends StatefulWidget {
  final Store? store;
  final bool fromModule;
  final String slug;
  const StoreScreen({super.key, required this.store, required this.fromModule, this.slug = ''});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    initDataCall();
  }

  @override
  void dispose() {
    super.dispose();

    scrollController.dispose();
  }

  Future<void> initDataCall() async {
    Get.find<StoreController>().resetFilter(isUpdate: false);
    if(Get.find<StoreController>().isSearching) {
      Get.find<StoreController>().changeSearchStatus(isUpdate: false);
    }
    Get.find<StoreController>().hideAnimation();
    await Get.find<StoreController>().getStoreDetails(Store(id: widget.store!.id), widget.fromModule, slug: widget.slug).then((value) {
      Get.find<StoreController>().showButtonAnimation();
    });
    if(Get.find<CategoryController>().categoryList == null) {
      Get.find<CategoryController>().getCategoryList(true);
    }
    Get.find<StoreController>().getStoreBannerList(widget.store!.id ?? Get.find<StoreController>().store!.id);
    Get.find<StoreController>().getRestaurantRecommendedItemList(widget.store!.id ?? Get.find<StoreController>().store!.id, false);
    Get.find<StoreController>().getStoreItemList(widget.store!.id ?? Get.find<StoreController>().store!.id, 1, 'all', false);

    scrollController.addListener(() {
      if(scrollController.position.userScrollDirection == ScrollDirection.reverse){
        if(Get.find<StoreController>().showFavButton){
          Get.find<StoreController>().changeFavVisibility();
          Get.find<StoreController>().hideAnimation();
        }
      }else{
        if(!Get.find<StoreController>().showFavButton){
          Get.find<StoreController>().changeFavVisibility();
          Get.find<StoreController>().showButtonAnimation();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: GetBuilder<StoreController>(builder: (storeController) {
        return GetBuilder<CategoryController>(builder: (categoryController) {
          Store? store;
          if(storeController.store != null && storeController.store!.name != null && categoryController.categoryList != null) {
            store = storeController.store;
            storeController.setCategoryList();
          }

          return (storeController.store != null && storeController.store!.name != null && categoryController.categoryList != null) ? CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: scrollController,
            slivers: [

              ResponsiveHelper.isDesktop(context) ? SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFF171A29),
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  alignment: Alignment.center,
                  child: Center(child: SizedBox(width: Dimensions.webMaxWidth, child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                    child: Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                          child: Stack(
                            children: [
                              CustomImage(
                                fit: BoxFit.cover, height: 240, width: 590,
                                image: store?.coverPhotoFullUrl ?? '',
                              ),

                              store?.discount != null ? Positioned(
                                bottom: 0, left: 0, right: 0,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                  child: Text('${store?.discount!.discountType == 'percent' ? '${store?.discount!.discount}%'
                                      : PriceConverter.convertPrice(store?.discount!.discount)} '
                                      '${'discount_will_be_applicable_when_order_amount_exceeds_is_more_than'.tr} ${PriceConverter.convertPrice(store?.discount!.minPurchase)},'
                                      ' ${'Max'.tr}: ${PriceConverter.convertPrice(store?.discount!.maxDiscount)} ${'discount_is_applicable'.tr}',
                                    style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ) : const SizedBox(),

                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeLarge),

                      Expanded(child: StoreDescriptionViewWidget(store: store)),

                    ]),
                  ))),
                ),
              ) : SliverToBoxAdapter(child: StoreHeroHeader(store: store!)),

              (ResponsiveHelper.isDesktop(context)  && storeController.recommendedItemModel != null && storeController.recommendedItemModel!.items!.isNotEmpty)
              ? SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                  child: Center(
                    child: SizedBox(
                      width: Dimensions.webMaxWidth,
                      height: ResponsiveHelper.isDesktop(context) ? 325 : 125,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text('recommended_for_you'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, fontWeight: FontWeight.w700)),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Text('here_is_what_you_might_like'.tr, style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor)),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              shrinkWrap: true,
                              scrollDirection: Axis.horizontal,
                              itemCount: storeController.recommendedItemModel!.items!.length,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                              itemBuilder: (context, index) {
                                return Container(
                                  width:  225,
                                  padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeExtraSmall),
                                  margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                  child: WebItemWidget(
                                    isStore: false, item: storeController.recommendedItemModel!.items![index],
                                    store: null, index: index, length: null, isCampaign: false, inStore: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ): const SliverToBoxAdapter(child: SizedBox()),
              const SliverToBoxAdapter(child: SizedBox(height: Dimensions.paddingSizeSmall)),

              ///web view..
              ResponsiveHelper.isDesktop(context) ? SliverToBoxAdapter(
                child: FooterView(
                  child: SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 175,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: ListView.builder(
                                    shrinkWrap: true,
                                    scrollDirection: Axis.vertical,
                                    itemCount: storeController.categoryList!.length,
                                    padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      return InkWell(
                                        onTap: () {
                                          storeController.setCategoryIndex(index, itemSearching: storeController.isSearching);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomRight,
                                                end: Alignment.topLeft,
                                                colors: <Color>[
                                                  index == storeController.categoryIndex ? Theme.of(context).primaryColor.withValues(alpha: 0.50) : Colors.transparent,
                                                  index == storeController.categoryIndex ? Theme.of(context).cardColor : Colors.transparent,
                                                ]
                                              )
                                            ),
                                            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text(
                                                storeController.categoryList![index].name!,
                                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                                style: index == storeController.categoryIndex
                                                    ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)
                                                    : robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                                              ),
                                            ]),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                Container(
                                  height: storeController.categoryList!.length * 50, width: 1,
                                  color: Theme.of(context).disabledColor.withValues(alpha: 0.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeLarge),

                          Expanded(child: Column (
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                    height: 45,
                                    width: 430,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      color: Theme.of(context).cardColor,
                                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.40)),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            textInputAction: TextInputAction.search,
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                                              hintText: 'search_for_items'.tr,
                                              hintStyle: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), borderSide: BorderSide.none),
                                              filled: true, fillColor:Theme.of(context).cardColor,
                                              isDense: true,
                                              prefixIcon: Icon(Icons.search, color: Theme.of(context).primaryColor.withValues(alpha: 0.50)),
                                            ),
                                            onSubmitted: (String? value) {
                                              if(value!.isNotEmpty) {
                                                Get.find<StoreController>().getStoreSearchItemList(
                                                  _searchController.text.trim(), widget.store!.id.toString(), 1, storeController.type,
                                                );
                                              }
                                            } ,
                                            onChanged: (String? value) { } ,
                                          ),
                                        ),
                                        const SizedBox(width: Dimensions.paddingSizeSmall),

                                        !storeController.isSearching ? CustomButton(
                                          radius: Dimensions.radiusSmall,
                                          height: 40,
                                          width: 74,
                                          buttonText: 'search'.tr,
                                          isBold: false,
                                          fontSize: Dimensions.fontSizeSmall,
                                          onPressed: () {
                                            storeController.getStoreSearchItemList(
                                              _searchController.text.trim(), widget.store!.id.toString(), 1, storeController.type,
                                            );
                                          },
                                        ) : InkWell(onTap: () {
                                          _searchController.text = '';
                                          storeController.initSearchData();
                                          storeController.changeSearchStatus();
                                        },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall)
                                            ),
                                            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: Dimensions.paddingSizeSmall),
                                            child: const Icon(Icons.clear, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: Dimensions.paddingSizeDefault),

                                  InkWell(
                                    onTap: () {
                                      List<double?> prices = [];
                                      for (var product in Get.find<StoreController>().storeItemModel!.items!) {
                                        prices.add(product.price);
                                      }
                                      prices.sort();
                                      double? maxValue = prices.isNotEmpty ? prices[prices.length-1] : 1000;
                                      Get.dialog(FilterWidget(maxValue: maxValue));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                        color: Theme.of(context).cardColor,
                                        border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                                      ),
                                      padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                      child: Icon(Icons.filter_list, size: 24, color: Theme.of(context).primaryColor),
                                    ),
                                  ),

                                  /*(Get.find<SplashController>().configModel!.moduleConfig!.module!.vegNonVeg! && Get.find<SplashController>().configModel!.toggleVegNonVeg!)
                                  ? SizedBox(
                                    width: 300,
                                    height:  30,
                                    child:  ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: Get.find<ItemController>().itemTypeList.length,
                                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                          child:  CustomCheckBoxWidget(
                                            title: Get.find<ItemController>().itemTypeList[index].tr,
                                            value: storeController.type == Get.find<ItemController>().itemTypeList[index],
                                            onClick: () {
                                              if(storeController.isSearching){
                                                storeController.getStoreSearchItemList(
                                                  storeController.searchText, widget.store!.id.toString(), 1, Get.find<ItemController>().itemTypeList[index],
                                                );
                                              } else {
                                                storeController.getStoreItemList(storeController.store!.id, 1, Get.find<ItemController>().itemTypeList[index], true);
                                              }
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ) : const SizedBox(),*/
                                ],
                              ),
                              const SizedBox(height: Dimensions.paddingSizeSmall),

                              PaginatedListView(
                                scrollController: scrollController,
                                onPaginate: (int? offset) async {
                                  if(storeController.isSearching){
                                    await storeController.getStoreSearchItemList(
                                      storeController.searchText, widget.store!.id.toString(), offset!, storeController.type,
                                    );
                                  } else {
                                    await storeController.getStoreItemList(widget.store!.id ?? storeController.store!.id, offset!, storeController.type, false);
                                  }
                                },
                                totalSize: storeController.isSearching
                                    ? storeController.storeSearchItemModel?.totalSize
                                    : storeController.storeItemModel?.totalSize,
                                offset: storeController.isSearching
                                    ? storeController.storeSearchItemModel?.offset
                                    : storeController.storeItemModel?.offset,
                                itemView: WebItemsView(
                                  isStore: false, stores: null, fromStore: true,
                                  items: storeController.isSearching
                                      ? storeController.storeSearchItemModel?.items
                                      : (storeController.categoryList!.isNotEmpty && storeController.storeItemModel != null) ? storeController.storeItemModel!.items : null,
                                  inStorePage: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeSmall,
                                    vertical: Dimensions.paddingSizeSmall,
                                  ),
                                ),
                              ),
                            ],
                          ))

                        ],
                      ),
                    ),
                  ),
                ),
              ) : const SliverToBoxAdapter(child:SizedBox()),


              ///mobile view..
              ResponsiveHelper.isDesktop(context) ? const SliverToBoxAdapter(child:SizedBox()) :
              SliverToBoxAdapter(child: Center(child: Container(
                width: Dimensions.webMaxWidth,
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                color: Theme.of(context).cardColor,
                child: Column(children: [

                  // Store info (name/rating/location/delivery) now lives in the
                  // green hero header (StoreHeroHeader) on mobile.
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                  // NEW premium embedded store-location map — after the store info
                  // section, before Categories (shared across all storefront modules).
                  if (!ResponsiveHelper.isDesktop(context) && storeController.store != null)
                    StoreMapView(store: storeController.store!),

                  store?.announcementActive??false ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    child: Row(children: [
                      Image.asset(Images.announcement, height: 20, width: 20),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Flexible(child: Text(store?.announcementMessage??'', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))),
                    ]),
                  ) : const SizedBox(),

                  StoreBannerWidget(storeController: storeController),

                  const SizedBox(height: Dimensions.paddingSizeLarge),

                  (!ResponsiveHelper.isDesktop(context) && storeController.recommendedItemModel != null && storeController.recommendedItemModel!.items!.isNotEmpty) ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('recommended_for_you'.tr, style: robotoMedium),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                      SizedBox(
                        height: ResponsiveHelper.isDesktop(context) ? 150 : 130,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: storeController.recommendedItemModel!.items!.length,
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: ResponsiveHelper.isDesktop(context) ? const EdgeInsets.symmetric(vertical: 20) : const EdgeInsets.symmetric(vertical: 10) ,
                              child: Container(
                                width: ResponsiveHelper.isDesktop(context) ? 500 : 300,
                                padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeExtraSmall),
                                margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                                child: ItemWidget(
                                  isStore: false, item: storeController.recommendedItemModel!.items![index],
                                  store: null, index: index, length: null, isCampaign: false, inStore: true,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ) : const SizedBox(),
                ]),
              ))),

              ResponsiveHelper.isDesktop(context) ? const SliverToBoxAdapter(child:SizedBox()) :
              (storeController.categoryList!.isNotEmpty) ? SliverPersistentHeader(
                pinned: true,
                delegate: SliverDelegate(height: 112, child: Center(child: Container(
                  width: Dimensions.webMaxWidth,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                        child: Row(children: [
                          Text('all_products'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                          const Expanded(child: SizedBox()),

                          !ResponsiveHelper.isDesktop(context) ? InkWell(
                            onTap: ()=> Get.toNamed(RouteHelper.getSearchStoreItemRoute(store!.id)),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              ),
                              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              child: Icon(Icons.search, size: 28, color: Theme.of(context).primaryColor),
                            ),
                          ) : const SizedBox(),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          InkWell(
                            onTap: () {
                              List<double?> prices = [];
                              for (var product in Get.find<StoreController>().storeItemModel!.items!) {
                                prices.add(product.price);
                              }
                              prices.sort();
                              double? maxValue = prices.isNotEmpty ? prices[prices.length-1] : 1000;
                              Get.dialog(FilterWidget(maxValue: maxValue));
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                color: Theme.of(context).cardColor,
                                border: Border.all(color: Theme.of(context).primaryColor, width: 1),
                              ),
                              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              child: Icon(Icons.filter_list, size: 24, color: Theme.of(context).primaryColor),
                            ),
                          ),

                          /*storeController.type.isNotEmpty ? VegFilterWidget(
                              type: storeController.type,
                              onSelected: (String type) {
                                storeController.getStoreItemList(storeController.store!.id, 1,  true);
                              },
                          ) : const SizedBox(),*/

                        ]),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      // Store category-navigation chips → the frozen MoonjoinSubCategoryBar
                      // (single source of truth). Same categoryList + categoryIndex +
                      // setCategoryIndex; mobile only (desktop renders SizedBox above).
                      MoonjoinSubCategoryBar(
                        labels: storeController.categoryList!.map((e) => e.name ?? '').toList(),
                        selectedIndex: storeController.categoryIndex,
                        onSelected: (index) => storeController.setCategoryIndex(index),
                      ),
                    ],
                  ),
                ))),
              ) : const SliverToBoxAdapter(child: SizedBox()),

              ResponsiveHelper.isDesktop(context) ? const SliverToBoxAdapter(child:SizedBox()) :
              SliverToBoxAdapter(child: Container(
                width: Dimensions.webMaxWidth,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: PaginatedListView(
                  scrollController: scrollController,
                  onPaginate: (int? offset) async => await storeController.getStoreItemList(widget.store!.id ?? storeController.store!.id, offset!, storeController.type, false),
                  totalSize: storeController.storeItemModel?.totalSize,
                  offset: storeController.storeItemModel?.offset,
                  itemView: ItemsView(
                    isStore: false, stores: null,
                    items: (storeController.categoryList!.isNotEmpty && storeController.storeItemModel != null)
                        ? storeController.storeItemModel!.items : null,
                    inStorePage: true,
                    premiumStoreLayout: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeDefault,
                      vertical: Dimensions.paddingSizeSmall,
                    ),
                  ),
                ),
              )),
            ],
          ) : const StoreDetailsScreenShimmerWidget();
        });
      }),

      floatingActionButton: GetBuilder<StoreController>(
        builder: (storeController) {
          return Visibility(
            visible: storeController.showFavButton && Get.find<SplashController>().configModel!.moduleConfig!.module!.orderAttachment!
                && (storeController.store != null && storeController.store!.prescriptionOrder!)
                && Get.find<SplashController>().configModel!.prescriptionStatus! && AuthHelper.isLoggedIn(),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(2, 2))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [

                AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  width: storeController.currentState == true ? 0 : ResponsiveHelper.isDesktop(context) ? 180 : 150,
                  height: 30,
                  curve: Curves.linear,
                  child:  Center(
                    child: Text(
                      'prescription_order'.tr, textAlign: TextAlign.center,
                      style: robotoMedium.copyWith(color: Theme.of(context).primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                InkWell(
                  onTap: () {
                    Get.find<CheckoutController>().updateFirstTime();
                    Get.find<CheckoutController>().updateFirstTimeCodActive();
                    Get.toNamed(
                      RouteHelper.getCheckoutRoute('prescription', storeId: storeController.store!.id),
                      arguments: CheckoutScreen(fromCart: false, cartList: null, storeId: storeController.store!.id),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: Image.asset(Images.prescriptionIcon, height: 25, width: 25),
                  ),
                ),

              ]),
            ),
          );
        }
      ),

      bottomNavigationBar: GetBuilder<CartController>(builder: (cartController) {
        return cartController.cartList.isNotEmpty && !ResponsiveHelper.isDesktop(context) ? const BottomCartWidget() : const SizedBox();
      })
    );
  }
}

class SliverDelegate extends SliverPersistentHeaderDelegate {
  Widget child;
  double height;

  SliverDelegate({required this.child, this.height = 100});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverDelegate oldDelegate) {
    return oldDelegate.maxExtent != height || oldDelegate.minExtent != height || child != oldDelegate.child;
  }
}

class CategoryProduct {
  CategoryModel category;
  List<Item> products;
  CategoryProduct(this.category, this.products);
}

