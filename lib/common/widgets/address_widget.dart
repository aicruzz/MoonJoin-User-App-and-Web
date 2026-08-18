import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddressWidget extends StatelessWidget {
  final AddressModel? address;
  final bool fromAddress;
  final bool fromCheckout;
  final Function? onRemovePressed;
  final Function? onEditPressed;
  final Function? onTap;
  final bool isSelected;
  final bool fromDashBoard;
  const AddressWidget({super.key, required this.address, required this.fromAddress, this.onRemovePressed, this.onEditPressed,
    this.onTap, this.fromCheckout = false, this.isSelected = false, this.fromDashBoard = false});

  @override
  Widget build(BuildContext context) {
    // MoonJoin Checkout address card (Figma): green-tinted card, icon chip, type + address.
    if(fromCheckout) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        ),
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        child: CustomInkWell(
          onTap: onTap as void Function()?,
          radius: Dimensions.radiusDefault,
          child: Row(children: [
            Container(
              height: 44, width: 44,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Image.asset(
                address!.addressType == 'home' ? Images.homeIcon : address!.addressType == 'office' ? Images.workIcon : Images.otherIcon,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(
                  address!.addressType!.tr,
                  style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 2),
                Text(
                  address!.address!,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.75)),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ]),
            ),
          ]),
        ),
      );
    }

    // MoonJoin My-Address list card (Phase 3): soft-green type chip + type label +
    // address, with edit/delete. Used ONLY by the My Address list (fromAddress:true);
    // Checkout (fromCheckout) and Dashboard (fromDashBoard) branches are untouched.
    if(fromAddress) {
      return Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
        ),
        child: CustomInkWell(
          onTap: onTap as void Function()?,
          radius: Dimensions.radiusLarge,
          child: Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(children: [

              Container(
                height: 46, width: 46, alignment: Alignment.center,
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withValues(alpha: 0.10), shape: BoxShape.circle),
                child: Image.asset(
                  address!.addressType == 'home' ? Images.homeIcon : address!.addressType == 'office' ? Images.workIcon : Images.otherIcon,
                  color: Theme.of(context).primaryColor, height: 22, width: 22,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),

              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(address!.addressType!.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault, color: Theme.of(context).textTheme.bodyLarge?.color)),
                const SizedBox(height: 3),
                Text(
                  address!.address ?? '',
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
              ])),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              _listActionButton(context, Icons.edit_outlined, Theme.of(context).primaryColor, onEditPressed),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              _listActionButton(context, Icons.delete_outline, Theme.of(context).colorScheme.error, onRemovePressed),
            ]),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: fromCheckout ? 0 : Dimensions.paddingSizeSmall),
      child: Container(
        decoration: fromDashBoard ? BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Colors.transparent, width: isSelected ? 1 : 0),
        ) : fromCheckout ? const BoxDecoration() : BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
          border: Border.all(color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).cardColor, width: isSelected ? 0.5 : 0),
          boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withValues(alpha: 0.1), blurRadius: 5, spreadRadius: 1)],
        ),
        child: CustomInkWell(
          onTap: onTap as void Function()?,
          radius: fromDashBoard ? Dimensions.radiusDefault : fromCheckout ? 0 : Dimensions.radiusSmall,
          child: Padding(
            padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeSmall),
            child: Row(mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Image.asset(
                        address!.addressType == 'home' ? Images.homeIcon : address!.addressType == 'office' ? Images.workIcon : Images.otherIcon,
                        color: Theme.of(context).primaryColor, height: ResponsiveHelper.isDesktop(context) ? 25 : 20, width: ResponsiveHelper.isDesktop(context) ? 25 : 20,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Text(
                        address!.addressType!.tr,
                        style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault),
                      ),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    Text(
                      address!.address!,
                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ]),
                ),

                fromAddress ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueGrey, size: 25),
                  onPressed: onEditPressed as void Function()?,
                ) : const SizedBox(),

                fromAddress ? IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 25),
                  onPressed: onRemovePressed as void Function()?,
                ) : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Soft-tinted circular icon button for the MoonJoin list card (edit / delete).
  Widget _listActionButton(BuildContext context, IconData icon, Color color, Function? onPressed) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed as void Function()?,
        child: SizedBox(height: 38, width: 38, child: Icon(icon, color: color, size: 20)),
      ),
    );
  }
}