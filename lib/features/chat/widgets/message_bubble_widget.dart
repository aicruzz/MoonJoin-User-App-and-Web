import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/chat/widgets/image_file_view_widget.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/features/chat/domain/models/chat_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/moonjoin/status_badge.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Message message;
  final User? user;
  final String userType;
  const MessageBubbleWidget({super.key, required this.message, required this.user, required this.userType});

  @override
  Widget build(BuildContext context) {
    bool isReply = message.senderId != Get.find<ProfileController>().userInfoModel!.userInfo!.id;

    return (isReply) ? Container(
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(20.0),
            child: CustomImage(
              fit: BoxFit.cover, width: 40, height: 40,
              image: '${user != null ? user!.imageFullUrl : ''}',
            ),
          ),
          const SizedBox(width: 10),

          Flexible(
            child: Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [

              if(message.message != null) Flexible(
                child: Container(
                  // Received (theirs): neutral MoonJoin surface (theme token, no
                  // hardcoded color), dark/adaptive text, premium rounded shape
                  // with a small top-left tail toward the sender.
                  decoration: BoxDecoration(
                    color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(Dimensions.radiusSmall),
                      topRight: Radius.circular(Dimensions.radiusLarge),
                      bottomRight: Radius.circular(Dimensions.radiusLarge),
                      bottomLeft: Radius.circular(Dimensions.radiusLarge),
                    ),
                  ),
                  padding: EdgeInsets.all(message.message != null ? Dimensions.paddingSizeDefault : 0),
                  child: Text(message.message ?? '', style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color, fontSize: Dimensions.fontSizeSmall)),
                ),
              ),
              const SizedBox(height: 8.0),

              (message.fileFullUrl != null && message.fileFullUrl!.isNotEmpty) ? SizedBox(
                width: 200,
                child: ImageFileViewWidget(
                  currentMessage: message,
                  isRightMessage: true,
                  ),
                ) : const SizedBox(),
            ]),
          ),
        ]),
        const SizedBox(height: Dimensions.paddingSizeSmall),

        Text(
          DateConverter.convertTodayYesterdayFormat(message.createdAt!),
          style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
        ),
      ]),
    ) : Container(
      padding: const EdgeInsets.symmetric(horizontal:Dimensions.paddingSizeDefault),
      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall)),
      child: GetBuilder<ProfileController>(builder: (profileController) {

        return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [


          Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [

            Flexible(
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [

                message.order != null ? adminOrderMessage(context, message.order!) : const SizedBox(),

                (message.message != null && message.message!.isNotEmpty) ? Flexible(
                  child: Container(
                    // Sent (mine): MoonJoin medium brand-green fill (theme primary
                    // token — not a bright rectangle), white text, premium rounded
                    // shape with a small bottom-right tail. Content-hugging (Flexible).
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(Dimensions.radiusLarge),
                        topRight: Radius.circular(Dimensions.radiusLarge),
                        bottomLeft: Radius.circular(Dimensions.radiusLarge),
                        bottomRight: Radius.circular(Dimensions.radiusSmall),
                      ),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(message.message != null ? Dimensions.paddingSizeDefault : 0),
                      child: Text(message.message ?? '', style: robotoRegular.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),),
                    ),
                  ),
                ) : const SizedBox(),

                SizedBox(height: (message.message != null && message.message!.isNotEmpty) ? Dimensions.paddingSizeSmall : 0),

                (message.fileFullUrl != null && message.fileFullUrl!.isNotEmpty) ? Directionality(
                  textDirection: TextDirection.rtl,
                  child: SizedBox(
                    width: 200,
                    child: ImageFileViewWidget(
                      currentMessage: message,
                      isRightMessage: true,
                    ),
                  ),
                ) : const SizedBox(),
              ]),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            ClipRRect(
              borderRadius: BorderRadius.circular(20.0),
              child: CustomImage(
                fit: BoxFit.cover, width: 40, height: 40,
                image: profileController.userInfoModel != null ? '${profileController.userInfoModel!.imageFullUrl}' : '',
              ),
            ),

          ]),

          Icon(
            message.isSeen == 1 ? Icons.done_all : Icons.check,
            size: 12,
            color: message.isSeen == 1 ? Theme.of(context).primaryColor : Theme.of(context).disabledColor,
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Text(
            DateConverter.convertTodayYesterdayFormat(message.createdAt!),
            style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

        ]);
      }),
    );
  }

  Widget adminOrderMessage(BuildContext context, Order order) {
    return Container(
      width: ResponsiveHelper.isDesktop(context) ? 400 : 350,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).disabledColor, width: 0.5),
        borderRadius: const BorderRadius.all(
          Radius.circular(Dimensions.radiusDefault),
        ),
      ),
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Column(children: [

        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(Dimensions.radiusDefault),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Row(children: [
                  Text('${'order_id'.tr} ', style: robotoMedium),
                  Text('#${order.id}', style: robotoBold),
                ]),

                Text('${'total'.tr}: ${PriceConverter.convertPrice(order.orderAmount ?? 0)}', style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),

              ]),
            ),

            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Padding(
                  // In-thread order status → frozen MoonJoin StatusBadge language
                  // (replaces the legacy hardcoded deep-purple chip).
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StatusBadge(text: '${order.orderStatus}'.tr),
                ),

                Text(DateConverter.stringToLocalDateOnly(order.createdAt!), style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall)),
              ]),
            ),

          ]),
        ),

        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: Row(children: [

            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('delivery_address'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeSmall)),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                Text(order.deliveryAddress?.contactPersonNumber??'', style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall)),

                RichText(
                  textAlign: TextAlign.start, maxLines: 2, overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyMedium!.color, fontSize: Dimensions.fontSizeSmall,),
                    children: [
                      if(order.deliveryAddress != null && order.deliveryAddress!.house != null && order.deliveryAddress!.house!.isNotEmpty)
                      TextSpan(text: '${'house'.tr}:${order.deliveryAddress?.house ?? 0}, '),

                      if(order.deliveryAddress != null && order.deliveryAddress!.road != null && order.deliveryAddress!.road!.isNotEmpty)
                      TextSpan(text: '${'road'.tr}:${order.deliveryAddress?.road ?? 0}, '),

                      TextSpan(text: order.deliveryAddress?.address??''),
                    ],
                  ),
                ),
              ]),
            ),

            order.detailsCount != null && order.detailsCount! > 0 ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
              ),
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Column(children: [
                Text('items'.tr, style: robotoRegular),
                Text(order.detailsCount.toString(), style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeOverLarge)),
              ]),
            ) : const SizedBox(),

          ]),
        ),

      ]),
    );
  }
}
