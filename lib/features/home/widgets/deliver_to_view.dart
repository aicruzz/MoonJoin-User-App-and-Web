import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/moonjoin/moonjoin_components.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/home/widgets/module_view.dart' show AddressShimmer;
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// "Deliver to" quick address selector — a horizontal list of the user's saved
/// addresses that switches the active delivery address on tap. Presentation
/// only: it reuses the existing [AddressController] / [LocationController] logic
/// (unchanged) and the shared [AddressWidget]. Preserved from the pre-redesign
/// home so the address-switching feature stays accessible.
class DeliverToView extends StatelessWidget {
  const DeliverToView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AddressController>(builder: (addressController) {
      List<AddressModel?> addressList = [];
      if (AuthHelper.isLoggedIn() && addressController.addressList != null) {
        bool contain = false;
        if (AddressHelper.getUserAddressFromSharedPref()!.id != null) {
          for (int index = 0; index < addressController.addressList!.length; index++) {
            if (addressController.addressList![index].id == AddressHelper.getUserAddressFromSharedPref()!.id) {
              contain = true;
              break;
            }
          }
        }
        if (!contain) {
          addressList.add(AddressHelper.getUserAddressFromSharedPref());
        }
        addressList.addAll(addressController.addressList!);
      }

      if (!(!AuthHelper.isLoggedIn() || addressController.addressList != null)) {
        return AddressShimmer(isEnabled: AuthHelper.isLoggedIn() && addressController.addressList == null);
      }
      if (addressList.isEmpty) return const SizedBox();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
          child: SectionHeader(title: 'deliver_to'.tr),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: addressList.length,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                child: AddressWidget(
                  address: addressList[index],
                  fromAddress: false,
                  onTap: () {
                    if (AddressHelper.getUserAddressFromSharedPref()!.id != addressList[index]!.id) {
                      Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                      Get.find<LocationController>().saveAddressAndNavigate(
                        addressList[index], false, null, false, ResponsiveHelper.isDesktop(context),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ]);
    });
  }
}
