import 'package:moonjoin/features/search/controllers/search_controller.dart' as search;
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/common/widgets/item_view.dart';
import 'package:moonjoin/common/widgets/web_item_view.dart';

class ItemViewWidget extends StatelessWidget {
  final bool isItem;
  const ItemViewWidget({super.key, required this.isItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<search.SearchController>(builder: (searchController) {
        return SingleChildScrollView(
          child: FooterView(
            child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: ResponsiveHelper.isDesktop(context) ? WebItemsView(
                  isStore: isItem, items: searchController.searchItemList, stores: searchController.searchStoreList,
                ) : ItemsView(
                  isStore: isItem, items: searchController.searchItemList, stores: searchController.searchStoreList,
                  // Search results SHOW the owning store/restaurant under the item
                  // title (product-owner request) — rendered by the frozen
                  // `item_widget` from the REAL `item.store_name`; when the backend
                  // omits it the widget hides it gracefully (never faked). Queue 20.
                  hideItemStoreName: false,
                ),
            ),
          ),
        );
      }),
    );
  }
}
