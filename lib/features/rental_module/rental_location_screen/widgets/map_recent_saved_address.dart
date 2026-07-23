import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/controller/taxi_location_controller.dart';
import 'package:sixam_mart/features/rental_module/home/domain/models/vehicle_details_model.dart';
import 'package:sixam_mart/features/rental_module/rental_cart_screen/domain/models/car_cart_model.dart';
import 'package:sixam_mart/features/rental_module/rental_location_screen/taxi_location_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// Recent addresses · saved addresses · select-from-map — the Location page's
/// suggestion list. **MoonJoin premium restyle only**: section headers, tinted
/// leading glyphs and a green select-from-map row. Every `onTap` body, controller
/// call and navigation is the pre-existing production logic, unchanged. Used only
/// by `TaxiLocationSuggestionScreen`.
class MapRecentSavedAddress extends StatelessWidget {
  final GoogleMapController? mapController;
  final UserData? userData;
  final VehicleModel? vehicle;
  const MapRecentSavedAddress({super.key, this.mapController, this.userData, this.vehicle});

  @override
  Widget build(BuildContext context) {

    return SafeArea(
      child: GetBuilder<TaxiLocationController>(
        builder: (taxiLocationController) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              taxiLocationController.historyAddress != null && taxiLocationController.historyAddress!.isNotEmpty ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _sectionTitle(context, 'recent_address'.tr),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: taxiLocationController.historyAddress!.length,
                  padding: EdgeInsets.zero,
                  itemBuilder: (context, index) {
                    return CustomInkWell(
                      onTap: () async {
                        // Only return to the LIVE map when one exists (original flow:
                        // this list is reopened from the map). Entered from Vehicle
                        // Details there is no map yet - fill the field, wait for both,
                        // then confirm on the map like the old design.
                        if(userData != null && mapController != null) {
                          Get.back();
                        }
                        await taxiLocationController.setSuggestionAddress(taxiLocationController.historyAddress![index], mapController);

                        if(taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null) {
                          taxiLocationController.updateCameraMovingStatus(false);
                          if((userData == null && vehicle != null) || (userData != null && mapController == null)) {
                            // Cart-edit entered from Vehicle Details: REPLACE this page
                            // so the map confirm's single Get.back() lands on Vehicle Details.
                            Get.off(()=> TaxiLocationScreen(
                              fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
                              fromSuggestionScreen: false, userData: userData, vehicle: vehicle,
                            ));
                          } else {
                            Get.to(()=> TaxiLocationScreen(
                              fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
                              fromSuggestionScreen: userData == null, userData: userData, vehicle: vehicle,
                            ));
                          }
                        }
                      },
                      radius: Dimensions.radiusDefault,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                        child: Row(children: [

                          _leadingGlyph(context, icon: Icons.history),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            Text(taxiLocationController.historyAddress![index].addressType?.tr??'other'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                            Text(
                              taxiLocationController.historyAddress![index].address??'', maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5)),
                            ),
                          ])),
                        ]),
                      ),
                    );
                  },
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
              ]) : const SizedBox(),


              GetBuilder<AddressController>(
                builder: (addressController) {
                  return addressController.addressList != null && addressController.addressList!.isNotEmpty ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _sectionTitle(context, 'saved_address'.tr),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: addressController.addressList!.length,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        return CustomInkWell(
                          onTap: () async {
                            // Same rule as the recent list: only pop back to a LIVE map.
                            if(userData != null && mapController != null) {
                              Get.back();
                            }
                            await taxiLocationController.setSuggestionAddress(addressController.addressList![index], mapController);

                            if(taxiLocationController.fromAddress != null && taxiLocationController.toAddress != null) {
                              taxiLocationController.updateCameraMovingStatus(false);

                              if((userData == null && vehicle != null) || (userData != null && mapController == null)) {
                                Get.off(()=> TaxiLocationScreen(
                                  fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
                                  fromSuggestionScreen: false, userData: userData, vehicle: vehicle,
                                ));
                              } else {
                                Get.to(()=> TaxiLocationScreen(
                                  fromAddress: taxiLocationController.fromAddress, toAddress: taxiLocationController.toAddress,
                                  fromSuggestionScreen: userData == null, userData: userData, vehicle: vehicle,
                                ));
                              }
                            }
                          },
                          radius: Dimensions.radiusDefault,
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                          child: Row(children: [

                            _leadingGlyph(context,
                              image: addressController.addressList![index].addressType == 'home' ? Images.taxiHomeAddressIcon : addressController.addressList![index].addressType == 'office' ? Images.taxiOfficeAddressIcon : Images.taxiOtherAddressIcon,
                            ),
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                              Text('${addressController.addressList![index].addressType?.tr}', style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
                              Text(
                                addressController.addressList![index].address??'', maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5)),
                              ),
                            ])),
                          ]),
                        );
                      },
                    ),
                  ]) : const SizedBox();
                }
              ),

              Divider(color: Theme.of(context).disabledColor.withValues(alpha: 0.25), height: Dimensions.paddingSizeLarge),

              CustomInkWell(
                onTap: () {
                  if(userData != null && mapController != null) {
                    Get.back();
                  } else {
                    Get.to(()=> TaxiLocationScreen(
                      userData: userData, vehicle: vehicle, fromSuggestionMap: true, fromSuggestionScreen: userData == null,
                      fromAddress: taxiLocationController.isFormSelected ? null : taxiLocationController.fromAddress,
                      toAddress: taxiLocationController.isFormSelected ? taxiLocationController.toAddress : null,
                    ));
                  }
                },
                radius: Dimensions.radiusDefault,
                padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                child: Row(children: [
                  _leadingGlyph(context, icon: Icons.map_rounded, tinted: true),
                  const SizedBox(width: Dimensions.paddingSizeSmall),

                  Text('select_from_map'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor)),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Theme.of(context).primaryColor, size: 20),
                ]),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),

            ]),
          );
        }
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall, bottom: Dimensions.paddingSizeSmall),
      child: Text(title, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
    );
  }

  /// 36px tinted circular glyph — neutral for addresses, green for the map action.
  Widget _leadingGlyph(BuildContext context, {IconData? icon, String? image, bool tinted = false}) {
    final Color fg = tinted ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge!.color!;
    return Container(
      height: 36, width: 36, alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tinted ? Theme.of(context).primaryColor.withValues(alpha: 0.10) : Theme.of(context).disabledColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: icon != null
          ? Icon(icon, size: 18, color: fg)
          : Image.asset(image!, height: 18, width: 18, color: fg),
    );
  }
}
