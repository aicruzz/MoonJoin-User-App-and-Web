import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:moonjoin/features/chat/controllers/chat_controller.dart';
import 'package:moonjoin/features/chat/enums/user_type_enum.dart';
import 'package:moonjoin/features/chat/widgets/chat_serach_field_widget.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/notification/domain/models/notification_body_model.dart';
import 'package:moonjoin/features/chat/domain/models/conversation_model.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/date_converter.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/features/profile/widgets/profile_page_header.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/footer_view.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/common/widgets/no_data_screen.dart';
import 'package:moonjoin/common/widgets/not_logged_in_screen.dart';
import 'package:moonjoin/common/widgets/paginated_list_view.dart';
import 'package:moonjoin/common/widgets/web_menu_bar.dart';
import 'package:moonjoin/features/chat/widgets/web_chat_view_widget.dart';

class ConversationScreen extends StatefulWidget {
  final bool fromNavBar;
  const ConversationScreen({super.key, this.fromNavBar = false});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    initCall();
  }

  void initCall(){
    if(AuthHelper.isLoggedIn()) {
      Get.find<ProfileController>().getUserInfo();
      Get.find<ChatController>().getConversationList(1, type: ResponsiveHelper.isDesktop(Get.context) ? 'vendor1' : '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(builder: (chatController) {
      ConversationsModel? conversation;
      if(chatController.searchConversationModel != null) {
        conversation = chatController.searchConversationModel;
      }else {
        conversation = chatController.conversationModel;
      }

      final bool isDesktop = ResponsiveHelper.isDesktop(context);
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: isDesktop ? const WebMenuBar() : null,
        endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
        floatingActionButton: (chatController.conversationModel != null && !chatController.hasAdmin) && !ResponsiveHelper.isDesktop(context) ? FloatingActionButton.extended(
          label: SizedBox(
            width: context.width * 0.75,
            child: Text(
              '${'chat_with'.tr} ${Get.find<SplashController>().configModel!.businessName}',
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeLarge, color: Colors.white),
            ),
          ),
          icon: const Icon(Icons.chat, color: Colors.white),
          backgroundColor: Theme.of(context).primaryColor,
          onPressed: () => Get.toNamed(RouteHelper.getChatRoute(notificationBody: NotificationBodyModel(
            notificationType: NotificationType.message, adminId: 0,
          ))),
        ) : null,
        body: isDesktop ? WebChatViewWidget(
          scrollController: _scrollController,
          conversation: conversation,
          chatController: chatController,
          searchController: _searchController,
          initCall: initCall,
        ) : Column(children: [

          ProfilePageHeader(title: 'conversation_list'.tr, showBack: !widget.fromNavBar),

          Expanded(child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(children: [

            (AuthHelper.isLoggedIn() && conversation != null && conversation.conversations != null
            && chatController.conversationModel!.conversations!.isNotEmpty) ? Center(child: SizedBox(width: Dimensions.webMaxWidth, child: ChatSearchFieldWidget(
              controller: _searchController,
              hint: '${'search'.tr}...',
              suffixIcon: chatController.searchConversationModel != null ? Icons.close : Icons.search,
              onSubmit: (String text) {
                if(_searchController.text.trim().isNotEmpty) {
                  chatController.searchConversation(_searchController.text.trim());
                }else {
                  showCustomSnackBar('write_something'.tr);
                }
              },
              iconPressed: () {
                if(chatController.searchConversationModel != null) {
                  _searchController.text = '';
                  chatController.removeSearchMode();
                }else {
                  if(_searchController.text.trim().isNotEmpty) {
                    chatController.searchConversation(_searchController.text.trim());
                  }else {
                    showCustomSnackBar('write_something'.tr);
                  }
                }
              },
            ))) : const SizedBox(),
            SizedBox(height: (AuthHelper.isLoggedIn() && conversation != null && conversation.conversations != null
                && chatController.conversationModel!.conversations!.isNotEmpty) ? Dimensions.paddingSizeSmall : 0),

            Expanded(child: AuthHelper.isLoggedIn() ? (conversation != null && conversation.conversations != null)
            ? conversation.conversations!.isNotEmpty ? RefreshIndicator(
              onRefresh: () async {
                await Get.find<ChatController>().getConversationList(1);
              },
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.zero,
                child: FooterView(
                  child: SizedBox(width: Dimensions.webMaxWidth, child: PaginatedListView(
                    scrollController: _scrollController,
                    onPaginate: (int? offset) => chatController.getConversationList(offset!),
                    totalSize: conversation.totalSize,
                    offset: conversation.offset,
                    enabledPagination: chatController.searchConversationModel == null,
                    itemView: ListView.builder(
                      itemCount: conversation.conversations!.length,
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemBuilder: (context, index) {
                        User? user;
                        String? type;
                        if(conversation!.conversations![index]!.senderType == UserType.user.name
                            || conversation.conversations![index]!.senderType == UserType.customer.name) {
                          user = conversation.conversations![index]!.receiver;
                          type = conversation.conversations![index]!.receiverType;
                        }else {
                          user = conversation.conversations![index]!.sender;
                          type = conversation.conversations![index]!.senderType;
                        }

                        // MoonJoin premium conversation card. Generic layout (avatar ·
                        // name · subtitle · time · unread count) — no assumption about
                        // the REST backend; a future websocket/live-sync can feed the
                        // same shape without a UI redesign.
                        return Container(
                          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                            border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.12)),
                            boxShadow: const [BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5)],
                          ),
                          child: CustomInkWell(
                            onTap: () {
                              if(user != null) {
                                Get.toNamed(RouteHelper.getChatRoute(
                                  notificationBody: NotificationBodyModel(
                                    type: conversation!.conversations![index]!.senderType,
                                    notificationType: NotificationType.message,
                                    adminId: type == UserType.admin.name ? 0 : null,
                                    restaurantId: type == UserType.vendor.name ? user.id : null,
                                    deliverymanId: type == UserType.delivery_man.name ? user.id : null,
                                  ),
                                  conversationID: conversation.conversations![index]!.id,
                                  index: index,
                                ));
                              }else {
                                showCustomSnackBar('${type!.tr} ${'not_found'.tr}');
                              }
                            },
                            highlightColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.1),
                            radius: Dimensions.radiusLarge,
                            child: Padding(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                              child: Row(children: [

                                // Premium avatar (soft green ring)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25), width: 1.5),
                                  ),
                                  child: ClipOval(child: CustomImage(
                                    height: 50, width: 50,
                                    image: '${user != null ? user.imageFullUrl : ''}',
                                  )),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeDefault),

                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                  Row(children: [
                                    Expanded(child: user != null ? Text(
                                      '${user.fName} ${user.lName}', maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                                    ) : Text('${type!.tr} ${'deleted'.tr}', style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault))),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),
                                    Text(
                                      DateConverter.localDateToIsoStringAMPM(DateConverter.dateTimeStringToDate(
                                          conversation.conversations![index]!.lastMessageTime!)),
                                      style: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeExtraSmall),
                                    ),
                                  ]),
                                  const SizedBox(height: 3),

                                  Row(children: [
                                    Expanded(child: user != null ? Text(
                                      type!.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                                    ) : const SizedBox()),

                                    // Unread badge — exact condition preserved.
                                    GetBuilder<ProfileController>(builder: (profileController) {
                                      return (profileController.userInfoModel != null && profileController.userInfoModel!.userInfo != null
                                      && conversation!.conversations![index]!.lastMessage!.senderId != profileController.userInfoModel!.userInfo!.id
                                      && conversation.conversations![index]!.unreadMessageCount! > 0) ? Container(
                                        margin: const EdgeInsets.only(left: Dimensions.paddingSizeSmall),
                                        constraints: const BoxConstraints(minWidth: 20),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(color: Theme.of(context).primaryColor, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                                        child: Text(
                                          conversation.conversations![index]!.unreadMessageCount.toString(),
                                          style: robotoBold.copyWith(color: Theme.of(context).cardColor, fontSize: Dimensions.fontSizeExtraSmall),
                                        ),
                                      ) : const SizedBox();
                                    }),
                                  ]),
                                ])),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
                  )),
                ),
              ),
            ) : NoDataScreen(text: 'no_conversation_found'.tr) : const Center(child: CircularProgressIndicator()) :  NotLoggedInScreen(callBack: (value){
              initCall();
              setState(() {});
            })),

          ]),
        )),
        ]),
      );
    });
  }
}
