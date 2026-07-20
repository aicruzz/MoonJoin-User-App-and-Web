import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_tool_tip_widget.dart';
import 'package:sixam_mart/features/checkout/widgets/guest_create_account.dart';
import 'package:sixam_mart/features/parcel/widgets/from_to_address_card.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/parcel/controllers/parcel_controller.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/module_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/checkout/widgets/condition_check_box.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_section.dart';
import 'package:sixam_mart/features/checkout/widgets/tips_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/card_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/delivery_instruction_bottom_sheet_widget.dart';
import 'package:sixam_mart/features/parcel/widgets/details_widget.dart';

class ParcelRequestScreen extends StatefulWidget {
  final ParcelCategoryModel parcelCategory;
  final AddressModel pickedUpAddress;
  final AddressModel destinationAddress;
  const ParcelRequestScreen({super.key, required this.parcelCategory, required this.pickedUpAddress, required this.destinationAddress});

  @override
  State<ParcelRequestScreen> createState() => _ParcelRequestScreenState();
}

class _ParcelRequestScreenState extends State<ParcelRequestScreen> {
  final TextEditingController _tipController = TextEditingController();
  final TextEditingController _packageValueController = TextEditingController();
  final TextEditingController _guestPasswordController = TextEditingController();
  final TextEditingController _guestConfirmPasswordController = TextEditingController();
  final FocusNode _guestPasswordNode = FocusNode();
  final FocusNode _guestConfirmPasswordNode = FocusNode();
  final FocusNode _packageValueNode = FocusNode();
  bool _isLoggedIn = AuthHelper.isLoggedIn();
  bool? _isCashOnDeliveryActive = false;
  bool? _isDigitalPaymentActive = false;
  bool _isOfflinePaymentActive = false;
  bool canCheckSmall = false;

  @override
  void initState() {
    super.initState();

    initCall();
  }

  void initCall(){

    Get.find<CheckoutController>().resetOrderTax();
    Get.find<ParcelController>().getOfflineMethodList();
    Get.find<ParcelController>().getDmTipMostTapped();
    Get.find<ParcelController>().setPaymentIndex(-1, false);
    // Shared payment component drives selection via CheckoutController.
    Get.find<CheckoutController>().setPaymentMethod(-1, isUpdate: false);
    Get.find<CheckoutController>().getOfflineMethodList();
    Get.find<ParcelController>().getDistance(widget.pickedUpAddress, widget.destinationAddress);
    Get.find<CheckoutController>().getSurgePrice(
      zoneId: widget.pickedUpAddress.zoneId.toString(), moduleId: ModuleHelper.getModule()?.id.toString() ?? (ModuleHelper.getCacheModule()?.id.toString() ?? '0'),
      dateTime: DateConverter.dateToDateTime(DateTime.now()), guestId: AuthHelper.getGuestId(),
    );
    Get.find<ParcelController>().setPayerIndex(0, false);
    Get.find<ParcelController>().startLoader(false, canUpdate: false);
      for(ZoneData zData in widget.pickedUpAddress.zoneData!){
        if(zData.id == AddressHelper.getUserAddressFromSharedPref()!.zoneId){
          _isCashOnDeliveryActive = zData.cashOnDelivery! && Get.find<SplashController>().configModel!.cashOnDelivery!;
          _isDigitalPaymentActive = zData.digitalPayment! && Get.find<SplashController>().configModel!.digitalPayment!;
          _isOfflinePaymentActive = zData.offlinePayment! && Get.find<SplashController>().configModel!.offlinePaymentStatus!;
          break;
        }
      }
      if (Get.find<ProfileController>().userInfoModel == null && _isLoggedIn) {
        Get.find<ProfileController>().getUserInfo();
      }
      Get.find<ParcelController>().updateTips(
        Get.find<AuthController>().getDmTipIndex().isNotEmpty ? int.parse(Get.find<AuthController>().getDmTipIndex()) : 0, notify: false,
      );

    if(Get.find<CheckoutController>().isCreateAccount) {
      Get.find<CheckoutController>().toggleCreateAccount(willUpdate: false);
    }

    Get.find<ParcelController>().setInstructionSelectedIndex(-1, notify: false);
    Get.find<ParcelController>().setCustomNoteController('', notify: false);
    Get.find<ParcelController>().setSelectedIndex(-1);
    Get.find<ParcelController>().setCustomNote('');
    Get.find<ParcelController>().resetPackageProtection();
    _packageValueController.clear();
  }

  @override
  Widget build(BuildContext context) {

    _isLoggedIn = AuthHelper.isLoggedIn();
    bool isGuestLoggedIn = AuthHelper.isGuestLoggedIn();
    bool guestCheckoutPermission = AuthHelper.isGuestLoggedIn() && Get.find<SplashController>().configModel!.guestCheckoutStatus!;

    return Scaffold(
      appBar: CustomAppBar(title: 'parcel_request'.tr),
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<CheckoutController>(builder: (checkoutController) {
        return SafeArea(
          child: guestCheckoutPermission || _isLoggedIn ? GetBuilder<ParcelController>(builder: (parcelController) {
            double charge = -1;
            double total = 0;
            double dmTips = 0;
            double additionalCharge =  Get.find<SplashController>().configModel!.additionalChargeStatus! ? Get.find<SplashController>().configModel!.additionCharge! : 0;

            if(parcelController.distance != -1 && parcelController.extraCharge != null) {
              charge = _calculateParcelDeliveryCharge(parcelController: parcelController, parcelCategory: widget.parcelCategory, zoneId: widget.pickedUpAddress.zoneId!);

              if(checkoutController.isFirstTime){

                PlaceOrderBodyModel placeOrderBody = PlaceOrderBodyModel(
                  cart: [], couponDiscountAmount: null, distance: parcelController.distance, scheduleAt: null,
                  orderAmount: charge, orderNote: '', orderType: 'parcel', receiverDetails: widget.destinationAddress,
                  paymentMethod: parcelController.paymentIndex == 0 ? 'cash_on_delivery'
                      : parcelController.paymentIndex == 1 ? 'wallet'
                      : parcelController.paymentIndex == 2 ? 'digital_payment' : 'offline_payment',
                  couponCode: null, storeId: null, address: widget.pickedUpAddress.address, latitude: widget.pickedUpAddress.latitude,
                  longitude: widget.pickedUpAddress.longitude, senderZoneId: widget.pickedUpAddress.zoneId,
                  addressType: widget.pickedUpAddress.addressType,
                  contactPersonName: widget.pickedUpAddress.contactPersonName ?? '',
                  contactPersonNumber: widget.pickedUpAddress.contactPersonNumber ?? '',
                  streetNumber: widget.pickedUpAddress.streetNumber ?? '', house: widget.pickedUpAddress.house ?? '',
                  floor: widget.pickedUpAddress.floor ?? '',
                  discountAmount: 0, parcelCategoryId: widget.parcelCategory.id.toString(),
                  chargePayer: parcelController.payerTypes[parcelController.payerIndex], dmTips: parcelController.tips.toString(),
                  cutlery: 0, unavailableItemNote: '',
                  partialPayment: 0, guestId: AuthHelper.isGuestLoggedIn() ? int.parse(AuthHelper.getGuestId()) : 0, isBuyNow: 0,
                  guestEmail: widget.pickedUpAddress.email ?? '', extraPackagingAmount: null,
                  createNewUser: checkoutController.isCreateAccount ? 1 : 0, password: _guestPasswordController.text,
                );

                checkoutController.getOrderTax(placeOrderBody);

              }

              dmTips = parcelController.tips;
              total = charge + dmTips + additionalCharge + checkoutController.orderTax! + parcelController.protectionFee;
            }

            return GetBuilder<CheckoutController>(builder: (checkoutController) {
              return Column(children: [

                Expanded(child: SingleChildScrollView(
                  padding: ResponsiveHelper.isDesktop(context) ? null : const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  child: FooterView(child: SizedBox(width: Dimensions.webMaxWidth, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ResponsiveHelper.isDesktop(context) ? const SizedBox(height: Dimensions.paddingSizeSmall) : const SizedBox(),

                    DottedBorder(
                      options: RoundedRectDottedBorderOptions(
                        color: Theme.of(context).disabledColor,
                        strokeWidth: 1.5,
                        dashPattern: const [5, 5],
                        radius: const Radius.circular(Dimensions.radiusDefault),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        ),
                        child: Row(children: [

                          ClipRRect(
                            borderRadius: BorderRadius.circular(200),
                            child: CustomImage(
                              image: '${widget.parcelCategory.imageFullUrl}',
                              height: 60, width: 60,
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(widget.parcelCategory.name!, style: robotoBold.copyWith(color: Theme.of(context).primaryColor)),
                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                            Text(
                              widget.parcelCategory.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: robotoRegular.copyWith(color: Theme.of(context).disabledColor),
                            ),
                          ])),

                        ]),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    CardWidget(child: DetailsWidget(title: 'sender_details'.tr, address: widget.pickedUpAddress)),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    CardWidget(child: DetailsWidget(title: 'receiver_details'.tr, address: widget.destinationAddress)),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    CardWidget(child: TripFromToCard(pickUpAddress: widget.pickedUpAddress, destinationAddress: widget.destinationAddress)),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    CardWidget(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [

                      Row(children: [
                        Image.asset(Images.distance, height: 30, width: 30),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            parcelController.distance == -1 ? 'calculating'.tr : '${parcelController.distance!.toStringAsFixed(2)} ${'km'.tr}',
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                          ),
                          Text('distance'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
                        ]),
                      ]),
                      // const Spacer(),

                      Container(
                        height: 40, width: 1,
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.2),
                      ),
                      // const Spacer(),

                      Row(children: [
                        Image.asset(Images.delivery, height: 30, width: 30),
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            parcelController.distance == -1 ? 'calculating'.tr : PriceConverter.convertPrice(charge),
                            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge, color: Theme.of(context).primaryColor), textDirection: TextDirection.ltr,
                          ),
                          Text('delivery_fee'.tr, style: robotoRegular.copyWith(color: Theme.of(context).textTheme.bodyLarge!.color!.withValues(alpha: 0.5))),
                        ]),
                      ])
                    ])),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    CardWidget(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                        child: Column(children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Text("add_more_delivery_instruction".tr, style: robotoMedium),

                            InkWell(
                              onTap: () {
                                !ResponsiveHelper.isDesktop(context) ? Get.bottomSheet(
                                  const DeliveryInstructionBottomSheetWidget(),
                                  backgroundColor: Colors.transparent, isScrollControlled: true,
                                ) : showDialog(context: context,
                                  builder: (context) {
                                    return const Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Dimensions.radiusDefault))),
                                      child: DeliveryInstructionBottomSheetWidget(),
                                    );
                                  },
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(left: Dimensions.paddingSizeDefault),
                                child: Icon(CupertinoIcons.add, size: 20),
                              ),
                            ),
                          ]),
                          SizedBox(height: parcelController.selectedIndexNote != -1 || parcelController.customNote!.isNotEmpty ? Dimensions.paddingSizeSmall : 0),

                          (parcelController.selectedIndexNote != -1 || parcelController.customNote!.isNotEmpty) ? Row(children: [

                            Image.asset(Images.parcelInstructionIcon, height: 30, width: 30),
                            const SizedBox(width: Dimensions.paddingSizeSmall),

                            Flexible(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [

                                parcelController.selectedIndexNote != -1 ? Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        parcelController.parcelInstructionList![parcelController.selectedIndexNote!].instruction ?? '',
                                        style: robotoMedium.copyWith(color: Theme.of(context).primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: Dimensions.paddingSizeSmall),

                                    InkWell(
                                      onTap: () {
                                        parcelController.setInstructionSelectedIndex(-1, notify: false);
                                        parcelController.setCustomNoteController('');
                                        Get.find<ParcelController>().setSelectedIndex(-1);
                                        Get.find<ParcelController>().setCustomNote('');
                                      },
                                      child: Icon(Icons.clear, color: Theme.of(context).disabledColor, size: 20),
                                    ),
                                  ],
                                ) : const SizedBox(),

                                parcelController.customNote!.isNotEmpty ? Text(
                                  parcelController.customNote ?? '',
                                  style: robotoMedium.copyWith(color: Theme.of(context).disabledColor),
                                ) : const SizedBox(),

                              ]),
                            ),
                          ]) : const SizedBox(),

                        ]),
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeDefault),

                    isGuestLoggedIn ? GuestCreateAccount(
                      guestPasswordController: _guestPasswordController, guestConfirmPasswordController: _guestConfirmPasswordController,
                      guestPasswordNode: _guestPasswordNode, guestConfirmPasswordNode: _guestConfirmPasswordNode,
                      fromParcel: true,
                    ): const SizedBox(),

                    SizedBox(height: isGuestLoggedIn ? Dimensions.paddingSizeDefault : Dimensions.paddingSizeExtraSmall),

                    (Get.find<SplashController>().configModel!.dmTipsStatus == 1) ? CardWidget(
                      // color: Theme.of(context).cardColor,
                      // padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeLarge, horizontal: Dimensions.paddingSizeSmall),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        Text('delivery_man_tips'.tr, style: robotoMedium),
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        SizedBox(
                          height: (parcelController.selectedTips == AppConstants.tips.length-1) && parcelController.canShowTipsField ? 0 : 66,
                          child: (parcelController.selectedTips == AppConstants.tips.length-1) && parcelController.canShowTipsField ? const SizedBox() : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: AppConstants.tips.length,
                            itemBuilder: (context, index) {
                              return TipsWidget(
                                title: AppConstants.tips[index] == '0' ? 'not_now'.tr : (index != AppConstants.tips.length -1)
                                    ? PriceConverter.convertPrice(double.parse(AppConstants.tips[index].toString()), forDM: true)
                                    : AppConstants.tips[index].tr,
                                isSelected: parcelController.selectedTips == index,
                                isSuggested: index != 0 && AppConstants.tips[index] == parcelController.mostDmTipAmount.toString(),
                                onTap: () {
                                  parcelController.updateTips(index);
                                  if(parcelController.selectedTips != 0 && parcelController.selectedTips != AppConstants.tips.length-1){
                                    parcelController.addTips(double.parse(AppConstants.tips[index]));
                                  }
                                  if(parcelController.selectedTips == AppConstants.tips.length-1){
                                    parcelController.showTipsField();
                                  }
                                  _tipController.text = parcelController.tips.toString();
                                },
                              );
                            },
                          ),
                        ),
                        SizedBox(height: (parcelController.selectedTips == AppConstants.tips.length-1) && parcelController.canShowTipsField ? Dimensions.paddingSizeExtraSmall : 0),

                        parcelController.selectedTips == AppConstants.tips.length-1 ? const SizedBox() : ListTile(
                          onTap: () => parcelController.toggleDmTipSave(),
                          leading: Checkbox(
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            activeColor: Theme.of(context).primaryColor,
                            value: parcelController.isDmTipSave,
                            onChanged: (bool? isChecked) => parcelController.toggleDmTipSave(),
                          ),
                          title: Text('save_for_later'.tr, style: robotoMedium.copyWith(color: Theme.of(context).primaryColor)),
                          contentPadding: EdgeInsets.zero,
                          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                          dense: true,
                          horizontalTitleGap: 0,
                        ),
                        SizedBox(height: parcelController.selectedTips == AppConstants.tips.length-1 ? Dimensions.paddingSizeDefault : 0),

                        parcelController.selectedTips == AppConstants.tips.length-1 ? Row(children: [
                          Expanded(
                            child: CustomTextField(
                              titleText: 'enter_amount'.tr,
                              controller: _tipController,
                              inputAction: TextInputAction.done,
                              inputType: TextInputType.number,
                              onSubmit: (value) {
                                if(value.isNotEmpty){
                                  if(double.parse(value) >= 0) {
                                    parcelController.addTips(double.parse(value));
                                  }else {
                                    showCustomSnackBar('tips_can_not_be_negative'.tr);
                                  }
                                }else{
                                  parcelController.addTips(0.0);
                                }
                              },
                              onChanged: (String value) {
                                if(value.isNotEmpty) {
                                  if(double.parse(value) >= 0) {
                                    parcelController.addTips(double.parse(value));
                                  }else{
                                    showCustomSnackBar('tips_can_not_be_negative'.tr);
                                  }
                                }else{
                                  parcelController.addTips(0.0);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),

                          InkWell(
                            onTap: (){
                              parcelController.updateTips(0);
                              parcelController.showTipsField();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                              child: const Icon(Icons.clear),
                            ),
                          ),

                        ]) : const SizedBox(),

                      ]),
                    ) : const SizedBox.shrink(),
                    SizedBox(height: (Get.find<SplashController>().configModel!.dmTipsStatus == 1) ? Dimensions.paddingSizeDefault : 0),

                    parcelController.packageProtectionEnabled
                        ? _packageProtectionSection(context, parcelController) : const SizedBox(),

                    Text('charge_pay_by'.tr, style: robotoMedium),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                    Row(children: [
                      Expanded(child: InkWell(
                        onTap: () => _setPayer(parcelController, 0),
                        child: Row(children: [
                          RadioGroup<String>(
                            groupValue: parcelController.payerTypes[parcelController.payerIndex],
                            onChanged: (String? payerType) => _setPayer(parcelController, 0),
                            child: Radio<String>(
                              value: parcelController.payerTypes[0],
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(parcelController.payerTypes[0].tr, style: robotoRegular),
                        ]),
                      )),
                      _isCashOnDeliveryActive! ? Expanded(child: InkWell(
                        onTap: () => _setPayer(parcelController, 1),
                        child: Row(children: [
                          RadioGroup<String>(
                            groupValue: parcelController.payerTypes[parcelController.payerIndex],
                            onChanged: (String? payerType) => _setPayer(parcelController, 1),
                            child: Radio<String>(
                              value: parcelController.payerTypes[1],
                              activeColor: Theme.of(context).primaryColor,
                            ),
                          ),
                          Text(parcelController.payerTypes[1].tr, style: robotoRegular),
                        ]),
                      )) : const SizedBox(),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeLarge),

                    // Shared MoonJoin "Choose Payment Method" card (same component/controller/bottom-sheet
                    // as Food/Grocery/Pharmacy/Ecommerce checkout). Charge Pay By above gates availability:
                    // when the Receiver pays, only Cash on Delivery is offered.
                    PaymentSection(
                      checkoutController: checkoutController,
                      total: total,
                      isCashOnDeliveryActive: _isCashOnDeliveryActive!,
                      isDigitalPaymentActive: _isDigitalPaymentActive! && parcelController.payerIndex == 0,
                      isWalletActive: Get.find<SplashController>().configModel!.customerWalletStatus == 1 && parcelController.payerIndex == 0 && !isGuestLoggedIn,
                      isOfflinePaymentActive: _isOfflinePaymentActive && parcelController.payerIndex == 0,
                    ),

                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Text('order_summary'.tr, style: robotoMedium),
                    const SizedBox(height: Dimensions.paddingSizeSmall),

                    Row(children: [
                      Text('delivery_fee'.tr, style: robotoRegular),

                      checkoutController.surgePrice?.customerNoteStatus == 1 ? CustomToolTip(
                        message: checkoutController.surgePrice?.customerNote ?? '',
                      ) : const SizedBox(),

                      const Spacer(),

                      Text(
                        parcelController.distance == -1 ? 'calculating'.tr : PriceConverter.convertPrice(charge),
                        style: robotoRegular.copyWith(color: parcelController.distance == -1 ? Colors.red : Theme.of(context).textTheme.bodyMedium!.color),
                      ),
                    ]),
                    SizedBox(height: Get.find<SplashController>().configModel!.dmTipsStatus == 1 ? Dimensions.paddingSizeSmall : 0.0),

                    (Get.find<SplashController>().configModel!.dmTipsStatus == 1) ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('delivery_man_tips'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverter.convertPrice(dmTips)}', style: robotoRegular, textDirection: TextDirection.ltr),
                      ],
                    ) : const SizedBox.shrink(),
                    SizedBox(height: Get.find<SplashController>().configModel!.dmTipsStatus == 1 ? Dimensions.paddingSizeSmall : 0),

                    // Package Protection fee — appears only when protection is selected.
                    parcelController.protectionFee > 0 ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('package_protection'.tr, style: robotoRegular),
                        Text('(+) ${PriceConverter.convertPrice(parcelController.protectionFee)}', style: robotoRegular, textDirection: TextDirection.ltr),
                      ],
                    ) : const SizedBox.shrink(),
                    SizedBox(height: parcelController.protectionFee > 0 ? Dimensions.paddingSizeSmall : 0),

                    SizedBox(height: Get.find<SplashController>().configModel!.additionalChargeStatus! ? Dimensions.paddingSizeSmall : 0),

                    ((checkoutController.taxIncluded == null) || (checkoutController.taxIncluded == 1)) ? const SizedBox() : Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('vat_tax'.tr, style: robotoRegular),
                      Text(('(+) ') + PriceConverter.convertPrice(checkoutController.orderTax), style: robotoRegular, textDirection: TextDirection.ltr),
                    ]),
                    SizedBox(height: ((checkoutController.taxIncluded == null) || (checkoutController.taxIncluded == 1)) ? 0 : Dimensions.paddingSizeSmall),

                    Get.find<SplashController>().configModel!.additionalChargeStatus! ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Expanded(child: Text(Get.find<SplashController>().configModel!.additionalChargeName!, style: robotoRegular, overflow: TextOverflow.ellipsis, maxLines: 1)),
                      SizedBox(width: Dimensions.paddingSizeSmall),

                      Text(
                        '(+) ${PriceConverter.convertPrice(Get.find<SplashController>().configModel!.additionCharge)}',
                        style: robotoRegular, textDirection: TextDirection.ltr,
                      ),
                    ]) : const SizedBox(),

                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
                      child: Divider(thickness: 1, color: Theme.of(context).hintColor.withValues(alpha: 0.5)),
                    ),

                    Row(children: [
                      Text('total_amount'.tr, style: robotoMedium),

                      checkoutController.taxIncluded == 1  ? Text(' ${'vat_tax_inc'.tr}', style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).primaryColor,
                      )) : const SizedBox(),

                      const Expanded(child: SizedBox()),

                      PriceConverter.convertAnimationPrice(total, textStyle: robotoMedium),
                    ]),

                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                    const CheckoutCondition(isParcel: true),

                    SizedBox(height: ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeLarge : 0),
                    ResponsiveHelper.isDesktop(context) ? _bottomButton(parcelController, total, isGuestLoggedIn: isGuestLoggedIn) : const SizedBox(),

                  ]))),
                )),

                ResponsiveHelper.isDesktop(context) ? const SizedBox() : _bottomButton(parcelController, total, isGuestLoggedIn: isGuestLoggedIn),

              ]);
            });
          }) : NotLoggedInScreen(callBack: (value){
            initCall();
            setState(() {});
          }),
        );
      }),
    );
  }

  /// Package Protection (new feature). Premium card with a Select/Unselect button
  /// that expands a declared-value field + fee summary. The Protection Fee is a
  /// percentage of the declared value (percentage sourced from ParcelController's
  /// config-ready placeholder — never hardcoded here). Reuses CardWidget,
  /// CustomTextField and PriceConverter; no frozen component touched.
  Widget _packageProtectionSection(BuildContext context, ParcelController parcelController) {
    final bool selected = parcelController.packageProtectionSelected;
    final Color green = Theme.of(context).primaryColor;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('package_protection'.tr, style: robotoMedium),
      const SizedBox(height: Dimensions.paddingSizeSmall),

      CardWidget(child: Column(children: [

        Row(children: [
          Container(
            height: 44, width: 44, alignment: Alignment.center,
            decoration: BoxDecoration(color: green.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
            child: Icon(Icons.shield_outlined, color: green, size: 24),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('apply_package_protection'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeDefault)),
            const SizedBox(height: 2),
            Text('package_protection_description'.tr, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
          ])),
          const SizedBox(width: Dimensions.paddingSizeSmall),

          InkWell(
            onTap: () {
              parcelController.togglePackageProtection();
              if (parcelController.packageProtectionSelected) {
                // UX: focus the amount field + open the numeric keyboard immediately.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) FocusScope.of(context).requestFocus(_packageValueNode);
                });
              } else {
                // Clear the entered amount; the fee is already removed by the controller.
                _packageValueController.clear();
              }
            },
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: selected ? Colors.transparent : green,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                border: Border.all(color: green, width: 1.2),
              ),
              child: Text(selected ? 'unselect'.tr : 'select'.tr,
                  style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall, color: selected ? green : Colors.white)),
            ),
          ),
        ]),

        // Smooth expand / collapse — no page refresh.
        AnimatedSize(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut, alignment: Alignment.topCenter,
          child: selected ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
              child: Divider(height: 1, color: Theme.of(context).disabledColor.withValues(alpha: 0.15)),
            ),

            Row(children: [
              Text('how_much_is_the_package_worth'.tr, style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall)),
              Text(' *', style: robotoMedium.copyWith(color: Theme.of(context).colorScheme.error)),
            ]),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            CustomTextField(
              hintText: 'enter_package_value'.tr,
              controller: _packageValueController,
              focusNode: _packageValueNode,
              inputType: TextInputType.number,
              isAmount: true,
              showTitle: false,
              inputAction: TextInputAction.done,
              onChanged: (String value) {
                parcelController.setPackageValue(double.tryParse(value) ?? 0);
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(color: green.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(Dimensions.radiusDefault)),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('package_value'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                  Text(PriceConverter.convertPrice(parcelController.packageValue), style: robotoMedium, textDirection: TextDirection.ltr),
                ]),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('protection_fee'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor)),
                  Text(PriceConverter.convertPrice(parcelController.protectionFee), style: robotoMedium.copyWith(color: green), textDirection: TextDirection.ltr),
                ]),
              ]),
            ),
          ]) : const SizedBox(width: double.infinity),
        ),
      ])),
      const SizedBox(height: Dimensions.paddingSizeDefault),
    ]);
  }

  /// Charge Pay By. When the Receiver pays, the parcel is Cash on Delivery
  /// (collected by the delivery man on delivery), so COD is auto-selected and no
  /// payment method needs choosing. When the Sender pays, a method is required.
  void _setPayer(ParcelController parcelController, int index) {
    parcelController.setPayerIndex(index, true);
    Get.find<CheckoutController>().setPaymentMethod(index == 1 ? 0 : -1);
  }

  Widget _bottomButton(ParcelController parcelController, double charge, {bool isGuestLoggedIn = false}) {

    bool isInstructionSelected = parcelController.selectedIndexNote != -1;
    bool isCustomNote = parcelController.customNote!.isNotEmpty;

    return CustomButton(
      buttonText: 'confirm_parcel_request'.tr,
      isLoading: parcelController.isLoading,
      margin: ResponsiveHelper.isDesktop(context) ? null : const EdgeInsets.all(Dimensions.paddingSizeSmall),
      onPressed: parcelController.acceptTerms ? () {
        if(parcelController.distance == -1) {
          showCustomSnackBar('delivery_fee_not_set_yet'.tr);
        }else if(parcelController.tips < 0) {
          showCustomSnackBar('tips_can_not_be_negative'.tr);
        }else if(Get.find<CheckoutController>().paymentMethodIndex == -1) {
          showCustomSnackBar('please_select_payment_method_first'.tr);
        }else if(parcelController.packageProtectionSelected && parcelController.packageValue <= 0) {
          showCustomSnackBar('please_enter_package_value'.tr);
        }else if(isGuestLoggedIn && Get.find<CheckoutController>().isCreateAccount && _guestPasswordController.text.isEmpty) {
          showCustomSnackBar('enter_password'.tr);
        }else if(isGuestLoggedIn && Get.find<CheckoutController>().isCreateAccount && _guestConfirmPasswordController.text.isEmpty) {
          showCustomSnackBar('enter_confirm_password'.tr);
        }else if(isGuestLoggedIn && Get.find<CheckoutController>().isCreateAccount && (_guestPasswordController.text != _guestConfirmPasswordController.text)) {
          showCustomSnackBar('confirm_password_does_not_matched'.tr);
        }else {

          // Sync the shared payment selection into ParcelController so the existing
          // placeOrder / parcelCallback (which read parcelController.paymentIndex) stay unchanged.
          parcelController.setPaymentIndex(Get.find<CheckoutController>().paymentMethodIndex, false);
          parcelController.changeDigitalPaymentName(Get.find<CheckoutController>().digitalPaymentName ?? '');

          // ── PACKAGE PROTECTION — BACKEND INTEGRATION POINT (placeholder) ──
          // Frontend is ready: parcelController.packageProtectionEnabled / packageProtectionPercentage
          // (from ConfigModel) + packageProtectionSelected / packageValue / protectionFee.
          // When the backend adds Package Protection to the parcel place-order API, send here — via
          // THIS existing parcel order flow / PlaceOrderBodyModel (no new order/payment system) — exactly:
          //   "package_protection":     parcelController.packageProtectionSelected,   // true/false
          //   "package_value":          parcelController.packageValue,                // e.g. 100000
          //   "package_protection_fee": parcelController.protectionFee,               // e.g. 1000
          // and add protectionFee to `orderAmount`. PlaceOrderBodyModel already exposes the unused
          // `extraPackagingAmount` (null for parcel) as an alternative channel if the backend prefers it.
          // Nothing is sent yet — the fee is display-only, so existing parcel ordering is unaffected and
          // no API contract is changed.

          PlaceOrderBodyModel placeOrderBody = PlaceOrderBodyModel(
            cart: [], couponDiscountAmount: null, distance: parcelController.distance, scheduleAt: null,
            orderAmount: charge, orderNote: '', orderType: 'parcel', receiverDetails: widget.destinationAddress,
            paymentMethod: parcelController.paymentIndex == 0 ? 'cash_on_delivery'
                : parcelController.paymentIndex == 1 ? 'wallet'
                : parcelController.paymentIndex == 2 ? 'digital_payment' : 'offline_payment',
            couponCode: null, storeId: null, address: widget.pickedUpAddress.address, latitude: widget.pickedUpAddress.latitude,
            longitude: widget.pickedUpAddress.longitude, senderZoneId: widget.pickedUpAddress.zoneId,
            addressType: widget.pickedUpAddress.addressType,
            contactPersonName: widget.pickedUpAddress.contactPersonName ?? '',
            contactPersonNumber: widget.pickedUpAddress.contactPersonNumber ?? '',
            streetNumber: widget.pickedUpAddress.streetNumber ?? '', house: widget.pickedUpAddress.house ?? '',
            floor: widget.pickedUpAddress.floor ?? '',
            discountAmount: 0, taxAmount: 0, parcelCategoryId: widget.parcelCategory.id.toString(),
            chargePayer: parcelController.payerTypes[parcelController.payerIndex], dmTips: parcelController.tips.toString(),
            cutlery: 0, unavailableItemNote: '',
            deliveryInstruction: (isInstructionSelected ? '${parcelController.parcelInstructionList![parcelController.selectedIndexNote!].instruction}' : '') + (isInstructionSelected ? (isCustomNote ? " (${parcelController.customNote})" : '') : (isCustomNote ? parcelController.customNote ?? '' : '')),
            partialPayment: 0, guestId: AuthHelper.isGuestLoggedIn() ? int.parse(AuthHelper.getGuestId()) : 0, isBuyNow: 0,
            guestEmail: widget.pickedUpAddress.email ?? '', extraPackagingAmount: null,
            createNewUser: Get.find<CheckoutController>().isCreateAccount ? 1 : 0, password: _guestPasswordController.text,
          );

          // if(parcelController.paymentIndex == 3) {
          //   Get.toNamed(RouteHelper.getOfflinePaymentScreen(placeOrderBody: placeOrderBody, zoneId: widget.pickedUpAddress.zoneId, total: charge, maxCodOrderAmount: 0, fromCart: false, isCodActive: false, forParcel: true));
          // } else {
            parcelController.startLoader(true);
            parcelController.placeOrder(placeOrderBody, widget.pickedUpAddress.zoneId, charge, 0, false, false, forParcel: true, isOfflinePay: parcelController.paymentIndex == 3);
          // }
        }
      } : null,
    );
  }

  double _calculateParcelDeliveryCharge({required ParcelController parcelController, required ParcelCategoryModel parcelCategory, required int zoneId, double? surgePrice, String? surgePriceType}) {
    double charge = 0;

    if(parcelController.distance != -1 && parcelController.extraCharge != null) {
      double parcelPerKmShippingCharge = parcelCategory.parcelPerKmShippingCharge! > 0
          ? parcelCategory.parcelPerKmShippingCharge!
          : Get.find<SplashController>().configModel!.parcelPerKmShippingCharge!;
      double parcelMinimumShippingCharge = parcelCategory.parcelMinimumShippingCharge! > 0
          ? parcelCategory.parcelMinimumShippingCharge!
          : Get.find<SplashController>().configModel!.parcelMinimumShippingCharge!;
      charge = parcelController.distance! * parcelPerKmShippingCharge;
      if (charge < parcelMinimumShippingCharge) {
        charge = parcelMinimumShippingCharge;
      }

      if (parcelController.extraCharge != null) {
        charge = charge + parcelController.extraCharge!;
      }

      if (surgePrice != null && surgePrice > 0) {
        if (surgePriceType == 'percent') {
          charge = charge + (charge * (surgePrice / 100));
        } else {
          charge = charge + surgePrice;
        }
      }
    }

    return PriceConverter.toFixed(charge);
  }

}
