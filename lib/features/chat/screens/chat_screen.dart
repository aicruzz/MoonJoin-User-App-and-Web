import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/hover/text_hover.dart';
import 'package:sixam_mart/features/chat/controllers/chat_controller.dart';
import 'package:sixam_mart/features/chat/domain/models/order_chat_model.dart';
import 'package:sixam_mart/features/chat/enums/user_type_enum.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/widgets/support_reason_bottom_sheet.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/features/chat/domain/models/conversation_model.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/common/widgets/paginated_list_view.dart';
import 'package:sixam_mart/common/widgets/web_menu_bar.dart';
import 'package:sixam_mart/features/chat/widgets/message_bubble_widget.dart';
import 'package:sixam_mart/features/profile/widgets/profile_page_header.dart';

class ChatScreen extends StatefulWidget {
  final NotificationBodyModel? notificationBody;
  final User? user;
  final int? conversationID;
  final int? index;
  final bool fromNotification;
  final OrderChatModel? orderChatModel;
  const ChatScreen({super.key, required this.notificationBody, required this.user, this.conversationID, this.index, this.fromNotification = false, this.orderChatModel});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputMessageController = TextEditingController();
  // Dedicated focus node for the composer field. Lets us restore focus after the
  // native image picker returns (iOS), reopening the keyboard through Flutter's
  // own focus→metrics pipeline so the composer never sits behind a keyboard that
  // iOS silently restored with a stale viewInsets.
  final FocusNode _inputFocusNode = FocusNode();
  StreamSubscription? _stream;

  // The conversation that OWNS this composer's draft — the chat route's existing
  // conversation identifier. Falls back to the notification target so admin /
  // notification-opened chats each own a distinct draft when conversationID is null.
  String get _draftOwnerKey {
    if(widget.conversationID != null) return 'c${widget.conversationID}';
    final nb = widget.notificationBody;
    if(nb == null || nb.adminId != null) return 'admin';
    if(nb.restaurantId != null) return 'v${nb.restaurantId}';
    if(nb.deliverymanId != null) return 'd${nb.deliverymanId}';
    if(widget.user != null) return 'u${widget.user!.id}';
    return 'default';
  }

  @override
  void initState() {
    super.initState();

    // Restore ONLY this conversation's own draft (text + selected images), owned by
    // the conversation identifier — never global. See ChatController draft maps.
    final String draft = Get.find<ChatController>().loadConversationDraft(_draftOwnerKey);
    if(draft.isNotEmpty) {
      _inputMessageController.text = draft;
      _inputMessageController.selection = TextSelection.fromPosition(TextPosition(offset: draft.length));
    }

    initCall();

  }

  void initCall(){

    if(AuthHelper.isLoggedIn()) {

      if(widget.orderChatModel != null) {
        Get.find<ChatController>().sendMessage(
          message: '${widget.orderChatModel!.reason!}\n${widget.orderChatModel!.customMessage!}',
          orderId: widget.orderChatModel!.orderId,
          notificationBody: widget.notificationBody,
          conversationID: widget.conversationID, index: widget.index,
        );
      }

      Get.find<ChatController>().getMessages(1, widget.notificationBody, widget.user, widget.conversationID, firstLoad: true);

      if(Get.find<ProfileController>().userInfoModel == null || Get.find<ProfileController>().userInfoModel!.userInfo == null) {
        Get.find<ProfileController>().getUserInfo();
      }

      if(widget.orderChatModel != null) {
        Get.find<OrderController>().getSupportReasons();
      }
    }
  }

  @override
  void dispose() {
    // Persist ONLY this conversation's own draft (text + selected images) before
    // leaving, keyed by its conversation identifier. A sent message already cleared
    // the field and images, so an empty draft is correctly discarded here.
    Get.find<ChatController>().saveConversationDraft(_draftOwnerKey, _inputMessageController.text);
    _inputFocusNode.dispose();
    _stream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatController>(builder: (chatController) {
      bool isLoggedIn = AuthHelper.isLoggedIn();

      return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async{
          if(widget.fromNotification) {
            Get.offAllNamed(RouteHelper.getInitialRoute());
          } else {
            return;
          }
        },
        child: Scaffold(
          endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
          // B1: mobile uses the frozen MoonJoin ProfilePageHeader inside the body
          // (rendered below); desktop keeps the legacy WebMenuBar unchanged.
          appBar: ResponsiveHelper.isDesktop(context) ? const WebMenuBar() : null,

          body: isLoggedIn ? ResponsiveHelper.isDesktop(context) ? Column(children: [

            Container(
              height: 64,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
              child: Center(child: Text('live_chat'.tr, style: robotoMedium)),
            ),

              Expanded(
                child: SingleChildScrollView(
                  child: FooterView(
                    child: Column(
                      children: [
                        const SizedBox(height:Dimensions.paddingSizeDefault),

                        Center(
                          child: SizedBox(
                            width: Dimensions.webMaxWidth,
                            child: Container(
                              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
                                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                              ),
                              child: Column(children: [
                                const SizedBox(height:Dimensions.paddingSizeSmall),

                                ResponsiveHelper.isDesktop(context) ? Container(
                                  color: Theme.of(context).cardColor,
                                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                                  child: Row(children: [

                                    ClipOval(child: CustomImage(
                                      image:'${chatController.messageModel != null ? chatController.messageModel!.conversation!.receiver!.imageFullUrl : ''}',
                                      fit: BoxFit.cover, height: 35, width: 35,
                                    )),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),

                                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                                      chatController.messageModel != null ? Text(
                                        '${chatController.messageModel!.conversation!.receiver!.fName}'
                                            ' ${chatController.messageModel!.conversation!.receiver!.lName}',
                                        style: robotoRegular,
                                      ) : Container(
                                        height: 20, width: 100, color: Theme.of(context).disabledColor,
                                      ),

                                      (chatController.messageModel != null && chatController.messageModel!.conversation!.receiver!.phone != null) ? Text(
                                        '${chatController.messageModel!.conversation!.receiver!.phone}',
                                        style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                                      ) : const SizedBox(),

                                    ]),

                                  ]),
                                ) : const SizedBox(),
                                const Divider(),

                                GetBuilder<ChatController>(builder: (chatController) {
                                  return SizedBox(
                                    height: 500,
                                    child: chatController.messageModel != null ? chatController.messageModel!.messages!.isNotEmpty ? SingleChildScrollView(
                                      controller: _scrollController,
                                      reverse: true,
                                      child: PaginatedListView(
                                        scrollController: _scrollController,
                                        reverse: true,
                                        totalSize: chatController.messageModel?.totalSize,
                                        offset: chatController.messageModel?.offset,
                                        onPaginate: (int? offset) async => await chatController.getMessages(
                                          offset!, widget.notificationBody, widget.user, widget.conversationID,
                                        ),
                                        itemView: ListView.builder(
                                          physics: const NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          reverse: true,
                                          itemCount: chatController.messageModel!.messages!.length,
                                          itemBuilder: (context, index) {
                                            return MessageBubbleWidget(
                                              message: chatController.messageModel!.messages![index],
                                              user: chatController.messageModel!.conversation!.receiver,
                                              userType: widget.notificationBody!.adminId != null ? UserType.admin.name
                                                  : widget.notificationBody!.deliverymanId != null ? UserType.delivery_man.name : UserType.vendor.name,
                                            );
                                          },
                                        ),
                                      ),
                                    ) : Center(child: Text('no_message_found'.tr)) : const Center(child: CircularProgressIndicator()),
                                  );
                                }),

                                (chatController.messageModel != null && (chatController.messageModel!.status! || chatController.messageModel!.messages!.isEmpty)) ? Container(
                                  padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.radiusDefault)),
                                    border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.6)),
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: Column(children: [

                                    GetBuilder<ChatController>(builder: (chatController) {

                                      return chatController.chatImage.isNotEmpty ? SizedBox(height: 100,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: chatController.chatImage.length,
                                          itemBuilder: (BuildContext context, index){
                                            return  chatController.chatImage.isNotEmpty ? Padding(
                                              padding: const EdgeInsets.all(8.0),
                                              child: Stack(clipBehavior: Clip.none, children: [

                                                Container(
                                                  width: 70, height: 90,
                                                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))),
                                                  child: ClipRRect(
                                                    borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeSmall)),
                                                    child: Image.memory(
                                                      chatController.chatRawImage[index], width: 70, height: 90, fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                ),

                                                Positioned(
                                                  top: -5, right: -5,
                                                  child: InkWell(
                                                    onTap : () => chatController.removeImage(index, _inputMessageController.text.trim()),
                                                    child: Container(
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xff9EADC1),
                                                        borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault)),
                                                      ),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(4.0),
                                                        child: Icon(Icons.clear, color: Colors.white, size: 15),
                                                      ),
                                                    ),
                                                  ),
                                                )],
                                              ),
                                            ) : const SizedBox();
                                          },
                                        ),
                                      ) : const SizedBox();
                                    }),

                                    Row(children: [

                                      InkWell(
                                        onTap: () async {
                                          Get.find<ChatController>().pickImage(false);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                          child: Image.asset(Images.image, width: 25, height: 25, color: Theme.of(context).primaryColor),
                                        ),
                                      ),

                                      /* SizedBox(
                                        height: 25,
                                        child: VerticalDivider(width: 0, thickness: 1, color: Theme.of(context).hintColor),
                                      ),*/
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                      Expanded(
                                        child: TextField(
                                          inputFormatters: [LengthLimitingTextInputFormatter(Dimensions.messageInputLength)],
                                          controller: _inputMessageController,
                                          textCapitalization: TextCapitalization.sentences,
                                          style: robotoRegular,
                                          keyboardType: TextInputType.multiline,
                                          maxLines: null,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'type_here'.tr,
                                            hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeLarge),
                                          ),
                                          onSubmitted: (String newText) {
                                            if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                                              Get.find<ChatController>().toggleSendButtonActivity();
                                            }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                                              Get.find<ChatController>().toggleSendButtonActivity();
                                            }
                                          },
                                          onChanged: (String newText) {
                                            if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                                              Get.find<ChatController>().toggleSendButtonActivity();
                                            }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                                              Get.find<ChatController>().toggleSendButtonActivity();
                                            }
                                          },
                                        ),
                                      ),

                                      GetBuilder<ChatController>(builder: (chatController) {
                                        bool showMessageSuggestion = (widget.orderChatModel != null && _inputMessageController.text.isEmpty&& chatController.chatImage.isEmpty
                                            && Get.find<OrderController>().supportReasons != null && Get.find<OrderController>().supportReasons!.isNotEmpty);

                                        return chatController.isLoading ? const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                          child: SizedBox(height: 25, width: 25, child: CircularProgressIndicator()),
                                        ) : InkWell(
                                          onTap: () async {
                                            if(showMessageSuggestion) {
                                              if(ResponsiveHelper.isDesktop(context)) {
                                                Get.dialog(const MessageSuggestionWidget(), barrierColor: Colors.transparent).then((value) async {
                                                  if(value != null) {
                                                    _inputMessageController.text = value;
                                                    chatController.toggleSendButtonActivity();
                                                  }
                                                });
                                              } else {
                                                Get.bottomSheet(const SupportReasonBottomSheet(orderId: null, fromChatPage: true),
                                                    backgroundColor: Colors.transparent, isScrollControlled: true).then((value) async {
                                                  if(value != null) {
                                                    _inputMessageController.text = value;
                                                    chatController.toggleSendButtonActivity();
                                                  }
                                                });
                                              }
                                            } else{
                                              if(chatController.isSendButtonActive) {
                                                await chatController.sendMessage(
                                                  message: _inputMessageController.text, notificationBody: widget.notificationBody,
                                                  conversationID: widget.conversationID, index: widget.index,
                                                );
                                                _inputMessageController.clear();
                                              }else {
                                                showCustomSnackBar('write_something'.tr);
                                              }
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                                            child: Image.asset(
                                              showMessageSuggestion ? Images.suggestionMessage : Images.send, width: 25, height: 25,
                                              color: chatController.isSendButtonActive || showMessageSuggestion ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
                                            ),
                                          ),
                                        );
                                      }),

                                    ]),
                                  ]),
                                ) : const SizedBox(),
                              ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ) : Column(children: [

            // MoonJoin thread header (B1) — reuses the frozen ProfilePageHeader to
            // match the Conversation List language. Title = receiver name, trailing
            // = receiver avatar. Existing back logic preserved verbatim.
            ProfilePageHeader(
              title: chatController.messageModel != null
                  ? '${chatController.messageModel!.conversation!.receiver!.fName} ${chatController.messageModel!.conversation!.receiver!.lName}'
                  : 'receiver_name'.tr,
              onBack: () {
                if(widget.fromNotification) {
                  Get.offAllNamed(RouteHelper.getInitialRoute());
                } else {
                  Get.back();
                }
              },
              trailing: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).cardColor, width: 1.5),
                ),
                child: ClipOval(child: CustomImage(
                  image: '${chatController.messageModel != null ? chatController.messageModel!.conversation!.receiver!.imageFullUrl : ''}',
                  fit: BoxFit.cover, height: 36, width: 36,
                )),
              ),
            ),

            Expanded(child: SafeArea(
              top: false,
              child: Center(
              child: SizedBox(
                width: ResponsiveHelper.isDesktop(context) ? Dimensions.webMaxWidth : MediaQuery.of(context).size.width,
                child: Column(children: [

                  SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeSmall : 0),

                  ResponsiveHelper.isDesktop(context) ? Container(
                    color: Theme.of(context).cardColor,
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeExtraSmall),
                    child: Row(children: [

                      ClipOval(child: CustomImage(
                        image:'${chatController.messageModel != null ? chatController.messageModel!.conversation!.receiver!.imageFullUrl : ''}',
                        fit: BoxFit.cover, height: 35, width: 35,
                      )),
                      const SizedBox(width: Dimensions.paddingSizeSmall),

                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        chatController.messageModel != null ? Text(
                          '${chatController.messageModel!.conversation!.receiver!.fName}'
                              ' ${chatController.messageModel!.conversation!.receiver!.lName}',
                          style: robotoRegular,
                        ) : Container(
                          height: 20, width: 100, color: Theme.of(context).disabledColor,
                        ),

                        (chatController.messageModel != null && chatController.messageModel!.conversation!.receiver!.phone != null) ? Text(
                          '${chatController.messageModel!.conversation!.receiver!.phone}',
                          style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
                        ) : const SizedBox(),

                      ]),

                    ]),
                  ) : const SizedBox(),

                  GetBuilder<ChatController>(builder: (chatController) {
                    return Expanded(child: chatController.messageModel != null ? chatController.messageModel!.messages!.isNotEmpty ? SingleChildScrollView(
                      controller: _scrollController,
                      reverse: true,
                      child: PaginatedListView(
                        scrollController: _scrollController,
                        reverse: true,
                        totalSize: chatController.messageModel?.totalSize,
                        offset: chatController.messageModel?.offset,
                        onPaginate: (int? offset) async => await chatController.getMessages(
                          offset!, widget.notificationBody, widget.user, widget.conversationID,
                        ),
                        itemView: ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          reverse: true,
                          itemCount: chatController.messageModel!.messages!.length,
                          itemBuilder: (context, index) {
                            return MessageBubbleWidget(
                              message: chatController.messageModel!.messages![index],
                              user: chatController.messageModel!.conversation!.receiver,
                              userType: widget.notificationBody!.adminId != null ? UserType.admin.name
                                  : widget.notificationBody!.deliverymanId != null ? UserType.delivery_man.name : UserType.vendor.name,
                            );
                          },
                        ),
                      ),
                    ) : Center(child: Text('no_message_found'.tr)) : const Center(child: CircularProgressIndicator()));
                  }),

                  (chatController.messageModel != null && (chatController.messageModel!.status! || chatController.messageModel!.messages!.isEmpty)) ? Container(
                    padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                    ),
                    child: Column(children: [

                      GetBuilder<ChatController>(builder: (chatController) {

                        return chatController.chatImage.isNotEmpty ? SizedBox(height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: chatController.chatImage.length,
                            itemBuilder: (BuildContext context, index){
                              return  chatController.chatImage.isNotEmpty ? Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Stack(clipBehavior: Clip.none, children: [

                                  Container(
                                    width: 70, height: 90,
                                    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(20))),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.all(Radius.circular(Dimensions.paddingSizeSmall)),
                                      child: Image.memory(
                                        chatController.chatRawImage[index], width: 70, height: 90, fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),

                                  Positioned(
                                    top: -5, right: -5,
                                    child: InkWell(
                                      onTap : () => chatController.removeImage(index, _inputMessageController.text.trim()),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xff9EADC1),
                                          borderRadius: BorderRadius.all(Radius.circular(Dimensions.paddingSizeDefault)),
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.clear, color: Colors.white, size: 15),
                                        ),
                                      ),
                                    ),
                                  )],
                                ),
                              ) : const SizedBox();
                            },
                          ),
                        ) : const SizedBox();
                      }),

                      Row(children: [

                        InkWell(
                          onTap: () async {
                            // iOS only: capture focus ownership, let Flutter dismiss the
                            // keyboard cleanly, then after the picker returns and the tree
                            // settles re-request focus so the keyboard reopens through
                            // Flutter (correct viewInsets) and the user keeps typing.
                            // Android/web behaviour is left exactly as before.
                            if(GetPlatform.isIOS) {
                              final bool hadFocus = _inputFocusNode.hasFocus;
                              _inputFocusNode.unfocus();
                              await Get.find<ChatController>().pickImage(false);
                              if(hadFocus && mounted) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if(mounted) _inputFocusNode.requestFocus();
                                });
                              }
                            } else {
                              Get.find<ChatController>().pickImage(false);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                            child: Image.asset(Images.image, width: 25, height: 25, color: Theme.of(context).primaryColor),
                          ),
                        ),

                       /* SizedBox(
                          height: 25,
                          child: VerticalDivider(width: 0, thickness: 1, color: Theme.of(context).hintColor),
                        ),*/
                        const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                        Expanded(
                          child: TextField(
                            inputFormatters: [LengthLimitingTextInputFormatter(Dimensions.messageInputLength)],
                            controller: _inputMessageController,
                            focusNode: _inputFocusNode,
                            textCapitalization: TextCapitalization.sentences,
                            style: robotoRegular,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'type_here'.tr,
                              hintStyle: robotoRegular.copyWith(color: Theme.of(context).hintColor, fontSize: Dimensions.fontSizeLarge),
                            ),
                            onSubmitted: (String newText) {
                              if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();
                              }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();
                              }
                            },
                            onChanged: (String newText) {
                              if(newText.trim().isNotEmpty && !Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();
                              }else if(newText.isEmpty && Get.find<ChatController>().isSendButtonActive) {
                                Get.find<ChatController>().toggleSendButtonActivity();
                              }
                            },
                          ),
                        ),

                        GetBuilder<ChatController>(builder: (chatController) {
                          bool showMessageSuggestion = (widget.orderChatModel != null && _inputMessageController.text.isEmpty&& chatController.chatImage.isEmpty
                              && Get.find<OrderController>().supportReasons != null && Get.find<OrderController>().supportReasons!.isNotEmpty);

                          return chatController.isLoading ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                            child: SizedBox(height: 25, width: 25, child: CircularProgressIndicator()),
                          ) : InkWell(
                            onTap: () async {
                              if(showMessageSuggestion) {
                                if(ResponsiveHelper.isDesktop(context)) {
                                  Get.dialog(const MessageSuggestionWidget(), barrierColor: Colors.transparent).then((value) async {
                                      if(value != null) {
                                        _inputMessageController.text = value;
                                        chatController.toggleSendButtonActivity();
                                      }
                                  });
                                } else {
                                  Get.bottomSheet(const SupportReasonBottomSheet(orderId: null, fromChatPage: true),
                                      backgroundColor: Colors.transparent, isScrollControlled: true).then((value) async {
                                        if(value != null) {
                                          _inputMessageController.text = value;
                                          chatController.toggleSendButtonActivity();
                                        }
                                  });
                                }
                              } else{
                                if(chatController.isSendButtonActive) {
                                  await chatController.sendMessage(
                                    message: _inputMessageController.text, notificationBody: widget.notificationBody,
                                    conversationID: widget.conversationID, index: widget.index,
                                  );
                                  _inputMessageController.clear();
                                }else {
                                  showCustomSnackBar('write_something'.tr);
                                }
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault),
                              child: Image.asset(
                               showMessageSuggestion ? Images.suggestionMessage : Images.send, width: 25, height: 25,
                                color: chatController.isSendButtonActive || showMessageSuggestion ? Theme.of(context).primaryColor : Theme.of(context).hintColor,
                              ),
                            ),
                          );
                        }),

                      ]),
                    ]),
                  ) : const SizedBox(),
                ],
                ),
              ),
            ),
          ))]) : NotLoggedInScreen(callBack: (value){
            initCall();
            setState(() {});
          }),
        ),
      );
    });
  }
}

class MessageSuggestionWidget extends StatelessWidget {
  const MessageSuggestionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<OrderController>(builder: (orderController) {
      bool isDesktop = ResponsiveHelper.isDesktop(context);

      return Container(
        width: Dimensions.webMaxWidth,
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: 50),
        alignment: Get.find<LocalizationController>().isLtr ? Alignment.bottomRight : Alignment.bottomLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [

            orderController.supportReasons!.isNotEmpty ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  constraints: BoxConstraints(maxHeight: context.height*0.5, minHeight: 30),
                  width: isDesktop ? 600 : context.width * 0.8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                  ),
                  margin: EdgeInsets.only(right: isDesktop ? context.width * 0.1 : 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const SizedBox(),

                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeDefault),
                          child: Text('choose_the_reason_for_support'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
                        ),

                        IconButton(onPressed: ()=> Get.back(), icon: const Icon(Icons.clear)),
                      ]),

                      Container(
                        constraints: BoxConstraints(maxHeight: context.height*0.3, minHeight: 30),
                        child: ListView.builder(
                            itemCount: orderController.supportReasons!.length,
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                            itemBuilder: (context, index) {
                              return InkWell(
                                onTap: (){
                                  Get.back(result: orderController.supportReasons![index]);
                                },
                                child: TextHover(
                                  builder: (isHovered) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                        border: Border.all(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), width: 0.3),
                                        boxShadow: isHovered ? [BoxShadow(color: Theme.of(context).disabledColor.withValues(alpha: 0.5), blurRadius: 10)] : null,
                                      ),
                                      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                      margin: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                      child: Text(orderController.supportReasons![index]??'', style: isHovered ? robotoMedium : robotoRegular),
                                    );
                                  }
                                ),
                              );
                            }),
                      ),
                    ],
                  ),
                ),
              ],
            ) : const SizedBox(),
          ],
        ),
      );
    });
  }
}
