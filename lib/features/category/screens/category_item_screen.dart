import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/cart_widget.dart';
import 'package:sixam_mart/common/widgets/item_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/veg_filter_widget.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_search_bar.dart';
import 'package:sixam_mart/common/widgets/moonjoin/filter_chip_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_page_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryItemScreen extends StatefulWidget {
  final String? categoryID;
  final String categoryName;
  /// When true (only from the All Restaurants / Store List category chips), this
  /// screen shows ONLY matching stores/restaurants — the Item tab is hidden and
  /// the item list is never built. Every other category entry point keeps the
  /// standard Item + Store tabs (storesOnly defaults to false).
  final bool storesOnly;
  const CategoryItemScreen({super.key, required this.categoryID, required this.categoryName, this.storesOnly = false});

  @override
  CategoryItemScreenState createState() => CategoryItemScreenState();
}

class CategoryItemScreenState extends State<CategoryItemScreen> with TickerProviderStateMixin {
  final ScrollController scrollController = ScrollController();
  final ScrollController storeScrollController = ScrollController();
  TabController? _tabController;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: widget.storesOnly ? 1 : 2, initialIndex: 0, vsync: this);
    Get.find<CategoryController>().getSubCategoryList(widget.categoryID);

    // Store-list category filtering: force store mode so the veg filter / reloads
    // operate on stores and the item list is never fetched.
    if (widget.storesOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) => Get.find<CategoryController>().setRestaurant(true));
    }

    Get.find<CategoryController>().getCategoryStoreList(
      widget.categoryID, 1, Get.find<CategoryController>().type, false,
    );

    scrollController.addListener(() {
      if (scrollController.position.pixels == scrollController.position.maxScrollExtent
          && Get.find<CategoryController>().categoryItemList != null
          && !Get.find<CategoryController>().isLoading) {
        int pageSize = (Get.find<CategoryController>().pageSize! / 10).ceil();
        if (Get.find<CategoryController>().offset < pageSize) {
          if (kDebugMode) {
            print('end of the page');
          }
          Get.find<CategoryController>().showBottomLoader();
          Get.find<CategoryController>().getCategoryItemList(
            Get.find<CategoryController>().subCategoryIndex == 0 ? widget.categoryID
                : Get.find<CategoryController>().subCategoryList![Get.find<CategoryController>().subCategoryIndex].id.toString(),
            Get.find<CategoryController>().offset+1, Get.find<CategoryController>().type, false,
          );
        }
      }
    });
    storeScrollController.addListener(() {
      if (storeScrollController.position.pixels == storeScrollController.position.maxScrollExtent
          && Get.find<CategoryController>().categoryStoreList != null
          && !Get.find<CategoryController>().isLoading) {
        int pageSize = (Get.find<CategoryController>().restPageSize! / 10).ceil();
        if (Get.find<CategoryController>().offset < pageSize) {
          if (kDebugMode) {
            print('end of the page');
          }
          Get.find<CategoryController>().showBottomLoader();
          Get.find<CategoryController>().getCategoryStoreList(
            Get.find<CategoryController>().subCategoryIndex == 0 ? widget.categoryID
                : Get.find<CategoryController>().subCategoryList![Get.find<CategoryController>().subCategoryIndex].id.toString(),
            Get.find<CategoryController>().offset+1, Get.find<CategoryController>().type, false,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CategoryController>(builder: (catController) {
      List<Item>? item;
      List<Store>? stores;
      if(catController.isSearching ? catController.searchItemList != null : catController.categoryItemList != null) {
        item = [];
        if (catController.isSearching) {
          item.addAll(catController.searchItemList!);
        } else {
          item.addAll(catController.categoryItemList!);
        }
      }
      if(catController.isSearching ? catController.searchStoreList != null : catController.categoryStoreList != null) {
        stores = [];
        if (catController.isSearching) {
          stores.addAll(catController.searchStoreList!);
        } else {
          stores.addAll(catController.categoryStoreList!);
        }
      }

      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if(catController.isSearching) {
            catController.toggleSearch();
          }else {
            return;
          }
        },
        child: Scaffold(
          // B1: mobile uses the frozen ProfilePageHeader inside the body (rendered
          // below); desktop keeps the legacy WebMenuBar unchanged.
          appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
          endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
          body: ResponsiveHelper.isDesktop(context) ? SingleChildScrollView(
            child: FooterView(
              child: Center(child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: Column(children: [

                  (catController.subCategoryList != null && !catController.isSearching) ? Center(child: Container(
                    height: 40, width: Dimensions.webMaxWidth, color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                    child: ListView.builder(
                      key: scaffoldKey,
                      scrollDirection: Axis.horizontal,
                      itemCount: catController.subCategoryList!.length,
                      padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return InkWell(
                          onTap: () => catController.setSubCategoryIndex(index, widget.categoryID),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              color: index == catController.subCategoryIndex ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text(
                                catController.subCategoryList![index].name!,
                                style: index == catController.subCategoryIndex
                                    ? robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor)
                                    : robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  )) : const SizedBox(),

                  widget.storesOnly ? const SizedBox() : Center(child: Container(
                    width: Dimensions.webMaxWidth,
                    color: Theme.of(context).cardColor,
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Theme.of(context).primaryColor,
                      indicatorWeight: 3,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Theme.of(context).disabledColor,
                      unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                      labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                      tabs: [
                        Tab(text: 'item'.tr),
                        Tab(text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'restaurants'.tr : 'stores'.tr),
                      ],
                    ),
                  )),

                  SizedBox(
                    height: 600,
                    child: NotificationListener(
                      onNotification: (dynamic scrollNotification) {
                        if (scrollNotification is ScrollEndNotification) {
                          if((_tabController!.index == 1 && !catController.isStore) || _tabController!.index == 0 && catController.isStore) {
                            catController.setRestaurant(_tabController!.index == 1);
                            if(catController.isSearching) {
                              catController.searchData(
                                catController.searchText, catController.subCategoryIndex == 0 ? widget.categoryID
                                  : catController.subCategoryList![catController.subCategoryIndex].id.toString(), catController.type,
                              );
                            }else {
                              if(_tabController!.index == 1) {
                                catController.getCategoryStoreList(
                                  catController.subCategoryIndex == 0 ? widget.categoryID
                                      : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                                  1, catController.type, false,
                                );
                              }else {
                                catController.getCategoryItemList(
                                  catController.subCategoryIndex == 0 ? widget.categoryID
                                      : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                                  1, catController.type, false,
                                );
                              }
                            }
                          }
                        }
                        return false;
                      },
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          if (!widget.storesOnly) SingleChildScrollView(
                            controller: scrollController,
                            child: ItemsView(
                              isStore: false, items: item, stores: null, noDataText: 'no_category_item_found'.tr,
                            ),
                          ),
                          SingleChildScrollView(
                            controller: storeScrollController,
                            child: ItemsView(
                              isStore: true, items: null, stores: stores,
                              noDataText: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'no_category_restaurant_found'.tr : 'no_category_store_found'.tr,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  catController.isLoading ? Center(child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
                  )) : const SizedBox(),

                ]),
              )),
            ),
          ) : Column(children: [

            // B1: mobile legacy AppBar → frozen ProfilePageHeader (back + category
            // name + cart trailing) + search (frozen MoonjoinSearchBar) + preserved
            // VegFilterWidget. Desktop (WebMenuBar) branch untouched; all logic preserved.
            ProfilePageHeader(
              title: widget.categoryName,
              onBack: () {
                if(catController.isSearching) {
                  catController.toggleSearch();
                }else {
                  Get.back();
                }
              },
              trailing: InkWell(
                onTap: () => Get.toNamed(RouteHelper.getCartRoute()),
                child: CartWidget(color: Theme.of(context).cardColor, size: 25),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeExtraSmall),
              child: Row(children: [
                Expanded(child: MoonjoinSearchBar(
                  hintText: 'search'.tr,
                  controller: _searchController,
                  showFilter: false,
                  leading: catController.isSearching
                      ? InkWell(onTap: () { catController.toggleSearch(); _searchController.clear(); }, child: Icon(Icons.close, color: Theme.of(context).hintColor))
                      : Icon(Icons.search, color: Theme.of(context).hintColor),
                  onSubmitted: (String query) {
                    if(query.trim().isNotEmpty) {
                      catController.searchData(
                        query, catController.subCategoryIndex == 0 ? widget.categoryID
                          : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                        catController.type,
                      );
                    }
                  },
                )),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                VegFilterWidget(type: catController.type, fromAppBar: true, onSelected: (String type) {
                  if(catController.isSearching) {
                    catController.searchData(
                      catController.subCategoryIndex == 0 ? widget.categoryID
                          : catController.subCategoryList![catController.subCategoryIndex].id.toString(), '1', type,
                    );
                  }else {
                    if(catController.isStore) {
                      catController.getCategoryStoreList(
                        catController.subCategoryIndex == 0 ? widget.categoryID
                            : catController.subCategoryList![catController.subCategoryIndex].id.toString(), 1, type, true,
                      );
                    }else {
                      catController.getCategoryItemList(
                        catController.subCategoryIndex == 0 ? widget.categoryID
                            : catController.subCategoryList![catController.subCategoryIndex].id.toString(), 1, type, true,
                      );
                    }
                  }
                }),
              ]),
            ),

            Expanded(child: SizedBox(
              width: Dimensions.webMaxWidth,
              child: Column(children: [
              const SizedBox(height: 10),

              // B3: sub-category chips → frozen MoonJoin chip component (MoonjoinFilterChip).
              // Same horizontal scroll + setSubCategoryIndex + selected state; styling only.
              (catController.subCategoryList != null && !catController.isSearching) ? SizedBox(
                height: 52,
                child: ListView.builder(
                  key: scaffoldKey,
                  scrollDirection: Axis.horizontal,
                  itemCount: catController.subCategoryList!.length,
                  // Horizontal padding only. The list's vertical padding was shrinking
                  // the bar's content height below the chip's intrinsic height, capping
                  // the chip and clipping its label — removed so labels render fully.
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                      // Center lets the chip take its intrinsic height (avoids the
                      // horizontal ListView stretching it and clipping the label).
                      child: Center(child: MoonjoinFilterChip(
                        label: catController.subCategoryList![index].name!,
                        selected: index == catController.subCategoryIndex,
                        onTap: () => catController.setSubCategoryIndex(index, widget.categoryID),
                      )),
                    );
                  },
                ),
              ) : const SizedBox(),

              // B2: Item/Stores control → the frozen MoonJoin Favorites segmented pill
              // (single source of truth). Same _tabController + tabs; styling only.
              widget.storesOnly ? const SizedBox() : Padding(
                padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall),
                child: Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    splashBorderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                    labelColor: Colors.white,
                    unselectedLabelColor: Theme.of(context).hintColor,
                    labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
                    unselectedLabelStyle: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                    tabs: [
                      Tab(text: 'item'.tr),
                      Tab(text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'restaurants'.tr : 'stores'.tr),
                    ],
                  ),
                ),
              ),


              Expanded(child: NotificationListener(
                onNotification: (dynamic scrollNotification) {
                  if (scrollNotification is ScrollEndNotification) {
                    if((_tabController!.index == 1 && !catController.isStore) || _tabController!.index == 0 && catController.isStore) {
                      catController.setRestaurant(_tabController!.index == 1);
                      if(catController.isSearching) {
                        catController.searchData(
                          catController.searchText, catController.subCategoryIndex == 0 ? widget.categoryID
                            : catController.subCategoryList![catController.subCategoryIndex].id.toString(), catController.type,
                        );
                      }else {
                        if(_tabController!.index == 1) {
                          catController.getCategoryStoreList(
                            catController.subCategoryIndex == 0 ? widget.categoryID
                                : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                            1, catController.type, false,
                          );
                        }else {
                          catController.getCategoryItemList(
                            catController.subCategoryIndex == 0 ? widget.categoryID
                                : catController.subCategoryList![catController.subCategoryIndex].id.toString(),
                            1, catController.type, false,
                          );
                        }
                      }
                    }
                  }
                  return false;
                },
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    if (!widget.storesOnly) SingleChildScrollView(
                      controller: scrollController,
                      child: ItemsView(
                        isStore: false, items: item, stores: null, noDataText: 'no_category_item_found'.tr,
                      ),
                    ),
                    SingleChildScrollView(
                      controller: storeScrollController,
                      child: ItemsView(
                        isStore: true, items: null, stores: stores,
                        noDataText: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'no_category_restaurant_found'.tr : 'no_category_store_found'.tr,
                      ),
                    ),
                  ],
                ),
              )),

              catController.isLoading ? Center(child: Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
              )) : const SizedBox(),

            ]),
            ),
          ),
          ]),
        ),
      );
    });
  }
}
