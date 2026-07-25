import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/notification/widgets/notification_bottom_sheet.dart';
import 'package:sixam_mart/features/profile/widgets/profile_page_header.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/notification/widgets/notification_dialog_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationScreen extends StatefulWidget {
  final bool fromNotification;
  const NotificationScreen({super.key, this.fromNotification = false});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  void _loadData() async {
    Get.find<NotificationController>().clearNotification();
    if(Get.find<SplashController>().configModel == null) {
      await Get.find<SplashController>().getConfigData();
    }
    if(AuthHelper.isLoggedIn()) {
      Get.find<NotificationController>().getNotificationList(true);
    }
  }

  @override
  void initState() {
    super.initState();

    _loadData();
  }

  void _handleBack() {
    if(widget.fromNotification) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if(widget.fromNotification) {
          Get.offAllNamed(RouteHelper.getInitialRoute());
        } else {
          return;
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: isDesktop ? const WebMenuBar() : null,
        endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
        body: Column(children: [

          if(!isDesktop) ProfilePageHeader(title: 'notification'.tr, onBack: _handleBack),

          Expanded(child: AuthHelper.isLoggedIn() ? GetBuilder<NotificationController>(builder: (notificationController) {
            if(notificationController.notificationList != null) {
              notificationController.saveSeenNotificationCount(notificationController.notificationList!.length);
            }
            List<DateTime> dateTimeList = [];
            return notificationController.notificationList != null ? notificationController.notificationList!.isNotEmpty ? RefreshIndicator(
              onRefresh: () async {
                await notificationController.getNotificationList(true);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: FooterView(
                  child: Column(children: [
                    WebScreenTitleWidget(title: 'notification'.tr),

                    Center(
                      child: SizedBox(width: Dimensions.webMaxWidth, child: ListView.builder(
                        itemCount: notificationController.notificationList!.length,
                        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final notification = notificationController.notificationList![index];
                          DateTime originalDateTime = DateConverter.dateTimeStringToDate(notification.createdAt!);
                          DateTime convertedDate = DateTime(originalDateTime.year, originalDateTime.month, originalDateTime.day);
                          bool addTitle = false;
                          if(!dateTimeList.contains(convertedDate)) {
                            addTitle = true;
                            dateTimeList.add(convertedDate);
                          }

                          bool isSeen = notificationController.getSeenNotificationIdList()!.contains(notification.id);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                              addTitle ? Padding(
                                padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall, left: 2),
                                child: Text(
                                  DateConverter.convertTodayYesterdayDate(notification.createdAt!),
                                  style: robotoBold.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeSmall),
                                ),
                              ) : const SizedBox(),

                              InkWell(
                                onTap: () {
                                  notificationController.addSeenNotificationId(notification.id!);

                                  ResponsiveHelper.isDesktop(context) ? showDialog(context: context, builder: (BuildContext context) {
                                    return NotificationDialogWidget(notificationModel: notification);
                                  }) : showModalBottomSheet(
                                    isScrollControlled: true, useRootNavigator: true, context: Get.context!,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(Dimensions.radiusExtraLarge), topRight: Radius.circular(Dimensions.radiusExtraLarge)),
                                    ),
                                    builder: (context) {
                                      return ConstrainedBox(
                                        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
                                        child: NotificationBottomSheet(notificationModel: notification),
                                      );
                                    },
                                  );
                                },
                                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                                child: _notificationCard(context, notification, isSeen),
                              ),

                            ]),
                          );
                        },
                      )),
                    ),
                  ]),
                ),
              ),
            ) : NoDataScreen(text: 'no_notification_found'.tr, showFooter: true) : const Center(child: CircularProgressIndicator());
          }) :  NotLoggedInScreen(callBack: (value){
            _loadData();
            setState(() {});
          })),

        ]),
      ),
    );
  }

  // MoonJoin premium notification card. Unread (not seen) → soft green tint +
  // green border + unread dot + bold title. Read → flat/muted. Presentation only.
  Widget _notificationCard(BuildContext context, notification, bool isSeen) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      decoration: BoxDecoration(
        color: isSeen ? Theme.of(context).cardColor : green.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        border: Border.all(color: isSeen ? Theme.of(context).disabledColor.withValues(alpha: 0.12) : green.withValues(alpha: 0.25)),
        boxShadow: isSeen ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Green icon chip (type-based icon preserved)
        Container(
          height: 46, width: 46, alignment: Alignment.center,
          decoration: BoxDecoration(color: green.withValues(alpha: 0.10), shape: BoxShape.circle),
          child: CustomAssetImageWidget(
            notification.data!.type == 'push_notification' ? Images.pushNotificationIcon
                : notification.data!.type == 'order_status' ? Images.orderConfirmIcon : Images.referEarnIcon,
            height: 24, width: 24, fit: BoxFit.contain,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            if(!isSeen) ...[
              Container(
                margin: const EdgeInsets.only(top: 6, right: Dimensions.paddingSizeExtraSmall),
                height: 8, width: 8,
                decoration: BoxDecoration(color: green, shape: BoxShape.circle),
              ),
            ],

            Expanded(
              child: Text(
                notification.data!.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(
                  color: isSeen ? Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.55) : Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: isSeen ? FontWeight.w500 : FontWeight.w700,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
              child: Text(
                DateConverter.dateTimeStringToFormattedTime(notification.createdAt!),
                style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeExtraSmall),
              ),
            ),

          ]),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(
                notification.data!.description ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: isSeen ? Theme.of(context).disabledColor : Theme.of(context).hintColor),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),

            notification.data!.type == 'push_notification' ? ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: notification.imageFullUrl != null ? CustomImage(
                image: '${notification.imageFullUrl}',
                height: 45, width: 75, fit: BoxFit.cover,
              ) : const SizedBox(),
            ) : const SizedBox.shrink(),

          ]),
        ])),

      ]),
    );
  }
}
