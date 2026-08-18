import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/features/address/controllers/address_controller.dart';
import 'package:moonjoin/features/address/widgets/address_confirmation_dialogue.dart';
import 'package:moonjoin/common/widgets/address_widget.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/no_data_screen.dart';
import 'package:moonjoin/common/widgets/not_logged_in_screen.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/common/widgets/web_page_title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressScreen extends StatefulWidget {
  final bool fromDashboard;
  const AddressScreen({super.key, this.fromDashboard = false});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    initCall();
  }

  void initCall(){
    if(AuthHelper.isLoggedIn()) {
      Get.find<AddressController>().getAddressList();
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isLoggedIn = AuthHelper.isLoggedIn();
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return GetBuilder<AddressController>(
      builder: (addressController) {
        return Scaffold(
          appBar: isDesktop ? const WebMenuBar() : null,
          endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: isLoggedIn
              ? (isDesktop ? _desktopBody(context, addressController) : _mobileBody(context, addressController))
              : Column(children: [
                  if(!isDesktop) ProfilePageHeader(title: 'my_address'.tr, showBack: !widget.fromDashboard),
                  Expanded(child: NotLoggedInScreen(callBack: (value) { initCall(); setState(() {}); })),
                ]),
          bottomNavigationBar: widget.fromDashboard ? Container(height: GetPlatform.isIOS ? 80 : 65) : const SizedBox(),
        );
      }
    );
  }

  // ── Mobile (MoonJoin) — reuses ProfilePageHeader, the shared AddressWidget list
  // card, NoDataScreen, and CustomButton. Navigation / delete logic unchanged. ──
  Widget _mobileBody(BuildContext context, AddressController addressController) {
    return Column(children: [

      ProfilePageHeader(title: 'my_address'.tr, showBack: !widget.fromDashboard),

      Expanded(child: RefreshIndicator(
        onRefresh: () async => addressController.getAddressList(),
        child: addressController.addressList == null
            ? ListView(children: const [SizedBox(height: 280), Center(child: CircularProgressIndicator())])
            : addressController.addressList!.isEmpty
                ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                    const SizedBox(height: Dimensions.paddingSizeExtremeLarge),
                    NoDataScreen(text: 'no_saved_address_found'.tr, fromAddress: true),
                  ])
                : ListView.builder(
                    controller: scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, Dimensions.paddingSizeSmall),
                    itemCount: addressController.addressList!.length,
                    itemBuilder: (context, index) => AddressWidget(
                      address: addressController.addressList![index], fromAddress: true,
                      onTap: () => Get.toNamed(RouteHelper.getMapRoute(addressController.addressList![index], 'address', false)),
                      onEditPressed: () => Get.toNamed(RouteHelper.getEditAddressRoute(addressController.addressList![index])),
                      onRemovePressed: () => _confirmDelete(addressController, index),
                    ),
                  ),
      )),

      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: CustomButton(
            buttonText: 'add_new_address'.tr,
            icon: Icons.add,
            onPressed: () => Get.toNamed(RouteHelper.getAddAddressRoute(false, false, 0, isNavbar: true)),
          ),
        ),
      ),

    ]);
  }

  void _confirmDelete(AddressController addressController, int index) {
    if(Get.isSnackbarOpen) {
      Get.back();
    }
    Get.dialog(AddressConfirmDialogue(
      icon: Images.locationConfirm,
      title: 'are_you_sure'.tr,
      description: 'you_want_to_delete_this_location'.tr,
      onYesPressed: () {
        addressController.deleteUserAddressByID(addressController.addressList![index].id, index).then((response) {
          Get.back();
          showCustomSnackBar(response.message, isError: !response.isSuccess);
        });
      }),
    );
  }

  // ── Desktop — existing grid preserved (city background removed; WebMenuBar app bar). ──
  Widget _desktopBody(BuildContext context, AddressController addressController) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(children: [
        WebScreenTitleWidget(title: 'address'.tr),
        Center(child: FooterView(
          minHeight: 0.45,
          child: SizedBox(
            width: Dimensions.webMaxWidth,
            child: Column(children: [
              const SizedBox(height: Dimensions.paddingSizeSmall),

              addressController.addressList != null ? addressController.addressList!.isNotEmpty ?
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: Dimensions.paddingSizeLarge,
                  mainAxisSpacing: Dimensions.paddingSizeLarge,
                  childAspectRatio: 4,
                  crossAxisCount: 3,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: addressController.addressList!.length + 1,
                itemBuilder: (context, index) {
                  return (index == addressController.addressList!.length) ?
                  Container(
                      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                      decoration:  BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
                      ),
                      child: CustomInkWell(
                        onTap: () => Get.toNamed(RouteHelper.getAddAddressRoute(false, false, 0)),
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        radius: Dimensions.radiusDefault,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.add_circle_outline, color: Theme.of(context).primaryColor),
                            const SizedBox(height: Dimensions.paddingSizeSmall),
                            Text('add_new_address'.tr, style: robotoRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall)),
                          ],
                        ),
                      )
                  ) :
                  AddressWidget(
                    address: addressController.addressList![index], fromAddress: true,
                    onTap: () => Get.toNamed(RouteHelper.getMapRoute(addressController.addressList![index], 'address', false)),
                    onEditPressed: () => Get.toNamed(RouteHelper.getEditAddressRoute(addressController.addressList![index])),
                    onRemovePressed: () => _confirmDelete(addressController, index),
                  );
                },
              ) : NoDataScreen(text: 'no_saved_address_found'.tr, fromAddress: true) : const Center(child: CircularProgressIndicator()),
            ]),
          ),
        )),
      ]),
    );
  }
}
