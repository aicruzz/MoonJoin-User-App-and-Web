import 'package:flutter/material.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

class DetailsWidget extends StatelessWidget {
  final String title;
  final AddressModel? address;
  const DetailsWidget({super.key, required this.title, required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      Text(title, style: robotoSemiBold),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

        // Leading avatar square (matches the design)
        Container(
          height: 46, width: 46, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          ),
          child: Icon(Icons.person_outline, color: Theme.of(context).primaryColor, size: 24),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [

          Row(
            children: [
              Icon(Icons.person_2_outlined, size: 16, color: Theme.of(context).primaryColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  address?.contactPersonName ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoSemiBold.copyWith(color: Theme.of(context).hintColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(
            children: [
              Icon(Icons.phone_enabled_outlined, size: 14, color: Theme.of(context).primaryColor),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  address!.contactPersonNumber ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
              ),
            ],
          ),

          AuthHelper.isGuestLoggedIn() && address!.email != null && address!.email!.isNotEmpty ? Padding(
            padding: const EdgeInsets.only(top: Dimensions.paddingSizeExtraSmall),
            child: Row(
              children: [
                Icon(Icons.email_outlined, size: 14, color: Theme.of(context).primaryColor),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Expanded(
                  child: Text(
                    address?.email ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                  ),
                ),
              ],
            ),
          ) : const SizedBox(),

        ])),
      ]),

    ]);
  }
}
