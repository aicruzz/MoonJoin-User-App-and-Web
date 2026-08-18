import 'package:flutter/cupertino.dart';
import 'package:moonjoin/common/controllers/theme_controller.dart';
import 'package:moonjoin/common/widgets/custom_asset_image_widget.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/features/cart/controllers/cart_controller.dart';
import 'package:moonjoin/features/item/controllers/item_controller.dart';
import 'package:moonjoin/features/notification/controllers/notification_controller.dart';
import 'package:moonjoin/features/search/controllers/search_controller.dart' as search;
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/helper/address_helper.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_search_bar.dart';
import 'package:moonjoin/common/widgets/moonjoin/filter_chip_widget.dart';
import 'package:moonjoin/common/widgets/moonjoin/scope_selector.dart';
import 'package:moonjoin/features/search/domain/models/search_scope.dart';
import 'package:moonjoin/features/search/widgets/search_scope_sheet.dart';
import 'package:moonjoin/helper/voice_permission_handler.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/features/search/widgets/filter_widget.dart';
import 'package:moonjoin/features/search/widgets/search_field_widget.dart';
import 'package:moonjoin/features/search/widgets/search_result_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/store/widgets/bottom_cart_widget.dart';

class SearchScreen extends StatefulWidget {
  final String? queryText;
  const SearchScreen({super.key, required this.queryText});

  @override
  SearchScreenState createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> with TickerProviderStateMixin {
  TabController? _tabController;

  final TextEditingController _searchController = TextEditingController();
  late bool _isLoggedIn;

  List<String> _itemsAndStors = <String>[];
  bool _showSuggestion = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);
    _isLoggedIn = AuthHelper.isLoggedIn();
    Get.find<search.SearchController>().setSearchMode(true, canUpdate: false);
    Get.find<search.SearchController>().getPopularCategories();
    if(_isLoggedIn) {
      Get.find<search.SearchController>().getSuggestedItems();
    }
    Get.find<search.SearchController>().getHistoryList();
    // Resolve Search Scope (independent of Application Context). If none can be
    // resolved (fresh install / no module ever used), present the Module Scope
    // Sheet instead of ever leaking a "Module ID Required" error.
    final search.SearchController sc = Get.find<search.SearchController>();
    sc.resolveInitialScope();
    if(sc.searchScope == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) _openScopeSheet();
      });
    } else if(widget.queryText!.isNotEmpty) {
      _actionSearch(true, widget.queryText, true);
    }
  }

  // Present the MoonJoin Module Scope Sheet. Sets SEARCH SCOPE only — never
  // setModule (Application Context is untouched). Re-runs the active query scoped.
  void _openScopeSheet() {
    final search.SearchController sc = Get.find<search.SearchController>();
    SearchScopeSheet.show(
      context,
      recent: Get.find<SplashController>().cacheModule,
      onSelected: (module) {
        sc.setSearchScope(SearchScope.module(module), rerun: sc.searchText != null && sc.searchText!.isNotEmpty);
      },
    );
  }

  // Premium scope pill under the search field, shown in both landing and results
  // states (mobile). Reuses the design-system MoonJoinScopeSelector.
  Widget _scopePillRow(search.SearchController searchController) {
    final SearchScope? scope = searchController.searchScope;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: MoonJoinScopeSelector(
          leadingText: 'searching_in'.tr,
          label: scope?.label ?? 'select_module'.tr,
          iconUrl: scope?.iconUrl,
          onTap: () => _openScopeSheet(),
        ),
      ),
    );
  }

  Future<void> _searchSuggestions(String query) async {
    _itemsAndStors = [];
    if (query == '') {
      _showSuggestion = false;
      _itemsAndStors = [];
    } else {
      _showSuggestion = true;
      _itemsAndStors = await Get.find<search.SearchController>().getSearchSuggestions(query);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if(Get.find<search.SearchController>().isSearchMode) {
          return;
        }else {
          Get.find<search.SearchController>().setSearchMode(true);
        }
      },
      child: Scaffold(
        appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,
        endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
        body: SafeArea(top: false, child: Padding(
          padding: EdgeInsets.zero,
          child: GetBuilder<search.SearchController>(builder: (searchController) {
            if(!GetPlatform.isWeb) {
              _searchController.text = searchController.searchText!;
            }
            return Column(children: [
              ResponsiveHelper.isDesktop(context) ? Container(
                width : double.infinity,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                child: SizedBox(
                  width: Dimensions.webMaxWidth,
                  child: Column(
                    children: [
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text('search_items_and_stores'.tr, style: robotoMedium),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      SizedBox(width: Dimensions.webMaxWidth, child: GetBuilder<search.SearchController>(builder: (searchController) {
                        return SearchFieldWidget(
                          controller: _searchController,
                          radius: 50,
                          hint: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                              ? 'search_food_or_restaurant'.tr : 'search_item_or_store'.tr,
                          suffixIcon: searchController.searchHomeText!.isNotEmpty ? Icons.cancel : Icons.keyboard_voice_sharp,
                          iconColor: Theme.of(context).disabledColor,
                          filledColor: Theme.of(context).colorScheme.surface,
                          onChanged: (text) {
                            _searchSuggestions(text);
                            searchController.setSearchText(text);
                          },
                          iconPressed: () async {
                            if(searchController.searchHomeText!.isNotEmpty) {
                              _searchController.text = '';
                              _showSuggestion = false;
                              searchController.setSearchMode(true);
                              searchController.clearSearchHomeText();
                            }else {
                              // searchData();
                              await VoicePermissionHandler.openVoiceSearch(
                                context: context,
                                searchTextEditingController: _searchController,
                                isDesktop: ResponsiveHelper.isDesktop(context),
                              );
                            }
                          },
                          onSubmit: (text) => searchData(),
                        );
                      })),
                      const SizedBox(height: Dimensions.paddingSizeDefault),

                      !searchController.isSearchMode ?
                      Center(
                        child: SizedBox(
                          width: Dimensions.webMaxWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 200,
                                color: Colors.transparent,
                                child: TabBar(
                                  tabAlignment: TabAlignment.start,
                                  controller: _tabController,
                                  indicatorColor: Theme.of(context).primaryColor,
                                  indicatorWeight: 3,
                                  labelColor: Theme.of(context).primaryColor,
                                  unselectedLabelColor: Theme.of(context).disabledColor,
                                  unselectedLabelStyle: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall),
                                  labelStyle: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).primaryColor),
                                  labelPadding: const EdgeInsets.symmetric(horizontal: Dimensions.radiusDefault, vertical: 0 ),
                                  isScrollable: true,
                                  indicatorSize: TabBarIndicatorSize.tab,
                                  tabs: [
                                    Tab(text: 'item'.tr),
                                    Tab(text: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'restaurants'.tr : 'stores'.tr),
                                  ],
                                ),
                              ),
                              
                              InkWell(
                                onTap: () {
                                  _actionSearch(false, _searchController.text.trim(), false);
                                },
                                child: Image.asset(Images.filter, height: 28, width: 28))
                            ],
                          )
                        ),
                      ) : const SizedBox(),
                    ],
                  ),
                ),
              ) : const SizedBox(),

              // Mobile: green MoonJoin hero header when showing results; the search/back
              // row when on the suggestion landing. Desktop keeps its own layout above.
              ResponsiveHelper.isDesktop(context) ? const SizedBox()
                : searchController.isSearchMode ? SafeArea(bottom: false, child: Center(child: Container(
                    width: Dimensions.webMaxWidth,
                    decoration: BoxDecoration(
                      color: Get.find<ThemeController>().darkTheme ? Colors.black12 : Theme.of(context).cardColor,
                      boxShadow: Get.find<ThemeController>().darkTheme ? null : [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.2), blurRadius: 3, offset: const Offset(0, 5))]
                    ),
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(children: [

                    IconButton(
                      onPressed: (){
                        if(searchController.isSearchMode) {
                          Get.back();
                        } else {
                          _showSuggestion = false;
                          searchController.setSearchMode(true);
                          searchController.setStore(false);
                        }
                      },
                      icon: const Icon(Icons.arrow_back_ios_new),
                    ),

                    Expanded(child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.2), width: 1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: SearchFieldWidget(
                        controller: _searchController,
                        radius: 40,
                        filledColor: Theme.of(context).disabledColor.withValues(alpha: 0.05),
                        hint: Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
                            ? 'search_food_or_restaurant'.tr : 'search_item_or_store'.tr,
                        suffixIcon: _searchController.text.isNotEmpty ? Icons.clear : Icons.keyboard_voice_sharp,
                        prefixIcon: CupertinoIcons.search,
                        iconPressed: () async {
                          if(_searchController.text.isNotEmpty) {
                            _showSuggestion = false;
                            searchController.setSearchMode(true);
                            searchController.setStore(false);
                            if(GetPlatform.isWeb) {
                              _searchController.text = '';
                            }
                          } else {
                            // Voice must respect Search Scope — if none set, choose a module first.
                            if(searchController.searchScope == null) {
                              _openScopeSheet();
                              return;
                            }
                            await VoicePermissionHandler.openVoiceSearch(
                              context: context,
                              searchTextEditingController: _searchController,
                              isDesktop: ResponsiveHelper.isDesktop(context),
                            );
                          }

                        },
                        onChanged: (text) {
                          searchController.setSearchText(text);
                          _searchSuggestions(text);
                          // _searchController.text = searchController.searchText!;
                        },
                        onSubmit: (text) => _actionSearch(true, _searchController.text.trim(), false),
                      ),
                    )),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                  ])))) : _searchHeroHeader(context, searchController),

              // MoonJoin Search Scope pill (mobile) — below the header in both states.
              ResponsiveHelper.isDesktop(context) ? const SizedBox() : _scopePillRow(searchController),

              Expanded(child: searchController.isSearchMode ? _showSuggestion ? showSuggestions(
                context, searchController, _itemsAndStors,
              ) : SingleChildScrollView(
                padding: ResponsiveHelper.isDesktop(context) ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                child: FooterView(
                  child: SizedBox(width: Dimensions.webMaxWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                    searchController.historyList.isNotEmpty ? Padding(
                      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

                        Text(ResponsiveHelper.isDesktop(context) ? 'recent_searches'.tr : 'your_last_search'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge)),
                        InkWell(
                          onTap: () => searchController.clearSearchHistory(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: 4),
                            child: Text('clear_all'.tr, style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeDefault, color: Colors.red,
                            )),
                          ),
                        ),
                      ]),
                    ) : const SizedBox(),

                    ResponsiveHelper.isDesktop(context) ? SizedBox(
                      height: 36,
                      child: ListView.builder(
                        itemCount: searchController.historyList.length > 10 ? 10 : searchController.historyList.length,
                        physics: const NeverScrollableScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                             padding: const EdgeInsets.symmetric(horizontal : Dimensions.paddingSizeDefault),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
                                border: Border.all(color: Theme.of(context).primaryColor),
                                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                              ),
                              child: InkWell(
                                onTap: () {
                                  _searchController.text = searchController.historyList[index];
                                  searchController.searchData(searchController.historyList[index], false);
                                },
                                child: Row(
                                  children: [
                                    Text(searchController.historyList[index], style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),

                                    InkWell(
                                      onTap: () => searchController.removeHistory(index),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                                        child: Icon(Icons.close, color: Theme.of(context).primaryColor, size: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                        },
                      ),
                    ) : Wrap(
                      spacing: Dimensions.paddingSizeSmall,
                      runSpacing: Dimensions.paddingSizeSmall,
                      children: List.generate(
                        searchController.historyList.length > 10 ? 10 : searchController.historyList.length,
                        (index) {
                          final String term = searchController.historyList[index];
                          return InkWell(
                            onTap: () => searchController.searchData(term, false),
                            borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
                                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(CupertinoIcons.search, size: 14, color: Theme.of(context).hintColor),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                Text(term, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                                InkWell(
                                  onTap: () => searchController.removeHistory(index),
                                  child: Icon(Icons.close, size: 14, color: Theme.of(context).hintColor),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    (_isLoggedIn && searchController.suggestedItemList != null && searchController.suggestedItemList!.isNotEmpty) ? Text(
                      'suggestions'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                    ) : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    (_isLoggedIn && searchController.suggestedItemList != null && searchController.suggestedItemList!.isNotEmpty) ? GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 3, childAspectRatio:  ResponsiveHelper.isMobile(context) ? (1/ 0.4) : (1.8/ 0.3),
                        mainAxisSpacing: Dimensions.paddingSizeSmall, crossAxisSpacing: Dimensions.paddingSizeSmall,
                      ),
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: searchController.suggestedItemList!.length,
                      itemBuilder: (context, index) {
                        // MoonJoin premium suggestion card (rounded surface, soft
                        // shadow, chevron). navigateToItemPage + image + name preserved.
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: CustomInkWell(
                            onTap: () {
                              Get.find<ItemController>().navigateToItemPage(searchController.suggestedItemList![index], context);
                            },
                            radius: Dimensions.radiusLarge,
                            child: Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                              child: Row(children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                  child: CustomImage(
                                    image: '${searchController.suggestedItemList![index].imageFullUrl}',
                                    width: 45, height: 45, fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),
                                Expanded(child: Text(
                                  searchController.suggestedItemList![index].name!,
                                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                )),
                                Icon(Icons.chevron_right_rounded, size: 18, color: Theme.of(context).hintColor),
                              ]),
                            ),
                          ),
                        );
                      },
                    ) : const SizedBox(),

                    SizedBox(height: (_isLoggedIn && searchController.suggestedItemList != null) ? Dimensions.paddingSizeLarge : 0),

                    (searchController.popularCategoryList != null && searchController.popularCategoryList!.isNotEmpty) ? Text(
                      'popular_categories'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge),
                    ) : const SizedBox(),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    searchController.popularCategoryList != null && searchController.popularCategoryList!.isNotEmpty ? Wrap(
                      spacing: Dimensions.paddingSizeSmall,
                      runSpacing: Dimensions.paddingSizeSmall,
                      children: searchController.popularCategoryList!.map((category) {
                        return MoonjoinFilterChip(
                          label: category?.name ?? '',
                          onTap: () {
                            _searchController.text = category?.name ?? '';
                            searchController.searchData(category?.name ?? '', false);
                          },
                        );
                      }).toList(),
                    ) : const SizedBox(),

                  ])),
                ),
                ) : SearchResultWidget(searchText: _searchController.text.trim(), tabController: ResponsiveHelper.isDesktop(context) ? _tabController : null)),
            ]);
          }),
        )),

        bottomNavigationBar: GetBuilder<CartController>(builder: (cartController) {
          return cartController.cartList.isNotEmpty && !ResponsiveHelper.isDesktop(context) ? const BottomCartWidget() : const SizedBox();
        })
      ),
    );
  }

  /// Green MoonJoin hero header for the search RESULTS view (items_search_list.PNG):
  /// back + notification/cart badges, big query title, location, "N Restaurants
  /// Available", optional hero artwork, and the search bar. Presentation only —
  /// composes around the existing search logic (no shared row/card touched).
  Widget _searchHeroHeader(BuildContext context, search.SearchController searchController) {
    final Color green = Theme.of(context).primaryColor;
    final bool showRestaurant = Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!;
    final String query = (searchController.searchText?.isNotEmpty ?? false)
        ? searchController.searchText! : (widget.queryText ?? '');
    final String address = AddressHelper.getUserAddressFromSharedPref()?.address ?? '';
    final int storeCount = searchController.resultStoreCount;
    final String? heroImage = (searchController.searchItemList != null && searchController.searchItemList!.isNotEmpty)
        ? searchController.searchItemList!.first.imageFullUrl : null;

    return Container(
      color: green,
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          Row(children: [
            _circleButton(context, Icons.arrow_back, 0, () {
              if (searchController.isSearchMode) { Get.back(); }
              else { _showSuggestion = false; searchController.setSearchMode(true); searchController.setStore(false); }
            }),
            const Spacer(),
            _circleButton(context, Icons.notifications_none,
                Get.find<NotificationController>().notificationList?.length ?? 0,
                () => Get.toNamed(RouteHelper.getNotificationRoute())),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            _circleButton(context, Icons.shopping_cart_outlined,
                Get.find<CartController>().cartList.length,
                () => Get.toNamed(RouteHelper.getCartRoute())),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(query, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(color: Colors.white, fontSize: 30)),
              const SizedBox(height: 6),
              if (address.isNotEmpty) Row(children: [
                const Icon(Icons.location_on, color: Colors.white, size: 15),
                const SizedBox(width: 3),
                Flexible(child: Text(address, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall))),
              ]),
              const SizedBox(height: 6),
              Text('$storeCount ${showRestaurant ? 'restaurants'.tr : 'stores'.tr} ${'available'.tr}',
                  style: robotoBold.copyWith(color: const Color(0xFFFFC107), fontSize: Dimensions.fontSizeSmall)),
            ])),
            if (heroImage != null) Padding(
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                child: CustomImage(image: heroImage, width: 96, height: 96, fit: BoxFit.cover),
              ),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          MoonjoinSearchBar(
            controller: _searchController,
            hintText: showRestaurant ? 'search_food_or_restaurant'.tr : 'search_item_or_store'.tr,
            onChanged: (text) { searchController.setSearchText(text); _searchSuggestions(text); },
            onSubmitted: (text) => _actionSearch(true, _searchController.text.trim(), false),
            onFilterTap: () => _actionSearch(false, _searchController.text.trim(), false),
          ),
        ]),
      )),
    );
  }

  Widget _circleButton(BuildContext context, IconData icon, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(30),
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          height: 42, width: 42, alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 22),
        ),
        if (count > 0) Positioned(
          right: -2, top: -2,
          child: Container(
            height: 18, width: 18, alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
            child: Text(count > 9 ? '9+' : '$count', style: robotoBold.copyWith(color: Colors.white, fontSize: 9)),
          ),
        ),
      ]),
    );
  }

  void searchData() {
    if (_searchController.text.trim().isEmpty) {
      showCustomSnackBar(Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
        ? 'search_food_or_restaurant'.tr : 'search_item_or_store'.tr);
    } else {
      _actionSearch(true, _searchController.text, true);
    }
  }

  void _actionSearch(bool isSubmit, String? queryText, bool fromHome) {
    // A search can never fire without a Search Scope — choose a module first
    // instead of leaking a backend "Module ID Required" error.
    if(Get.find<search.SearchController>().searchScope == null) {
      _openScopeSheet();
      return;
    }
    if(Get.find<search.SearchController>().isSearchMode || isSubmit) {
      if(queryText!.isNotEmpty) {
        Get.find<search.SearchController>().searchData(queryText, fromHome);
      } else {
        showCustomSnackBar(Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText!
            ? 'search_food_or_restaurant'.tr : 'search_item_or_store'.tr);
      }
    } else {
      List<double?> prices = [];
      if(!Get.find<search.SearchController>().isStore) {
        for (var product in Get.find<search.SearchController>().allItemList!) {
          prices.add(product.price);
        }
        prices.sort();
      }
      double? maxValue = prices.isNotEmpty ? prices[prices.length-1] : 1000;
      Get.dialog(FilterWidget(maxValue: maxValue, isStore: Get.find<search.SearchController>().isStore));
    }
  }


  Widget showSuggestions(BuildContext context, search.SearchController searchController, List<String> foodsAndRestaurants) {
    return SingleChildScrollView(
      child: FooterView(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: foodsAndRestaurants.isNotEmpty ? ListView.builder(
            itemCount: foodsAndRestaurants.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final item = foodsAndRestaurants[index];
              final searchQuery = _searchController.text.trim();

              if(searchQuery.isNotEmpty && item.toLowerCase().contains(searchQuery.toLowerCase())){
                final startIndex = item.toLowerCase().indexOf(searchQuery.toLowerCase());
                final prefix = item.substring(0, startIndex);
                final suffix = item.substring(startIndex + searchQuery.length);
                return ListTile(
                  title: RichText(
                    text: TextSpan(
                      style: DefaultTextStyle.of(context).style,
                      children: <TextSpan>[
                        TextSpan(
                          text: prefix,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                        ),
                        TextSpan(
                          text: prefix.isEmpty ? searchQuery.capitalizeFirst : searchQuery,
                          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                        ),
                        TextSpan(
                          text: suffix,
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(Icons.north_west_rounded, color: Theme.of(context).disabledColor),
                  leading: Icon(Icons.search,color: Theme.of(context).disabledColor),
                  onTap: (){
                    FocusScope.of(context).unfocus();
                    _searchController.text = foodsAndRestaurants[index];
                    _actionSearch(true, _searchController.text.trim(), false);
                  },
                );

              }
              return ListTile(
                title: Text(foodsAndRestaurants[index], style: robotoRegular,),
                leading: Icon(CupertinoIcons.search, color: Theme.of(context).disabledColor),
                trailing: Icon(Icons.north_west, color: Theme.of(context).disabledColor),
                onTap: () async {
                  FocusScope.of(context).unfocus();
                  _searchController.text = foodsAndRestaurants[index];
                  _actionSearch(true, _searchController.text.trim(), false);
                },
              );
            },
          ) : Padding(
            padding: EdgeInsets.only(top: context.height * 0.2),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const CustomAssetImageWidget(Images.emptyBox, height: 100, width: 100),
              const SizedBox(height: Dimensions.paddingSizeLarge),

              Text('no_suggestions_found'.tr, style: robotoMedium.copyWith(color: Theme.of(context).hintColor)),
            ]),
          ),
        ),
      ),
    );
  }

}
