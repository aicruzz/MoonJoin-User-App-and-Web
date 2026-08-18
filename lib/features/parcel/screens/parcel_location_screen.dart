import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:moonjoin/features/checkout/controllers/checkout_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/address/controllers/address_controller.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/features/parcel/controllers/parcel_controller.dart';
import 'package:moonjoin/features/parcel/domain/models/parcel_category_model.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/helper/address_helper.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/custom_validator.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/helper/route_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_app_bar.dart';
import 'package:moonjoin/common/widgets/moonjoin/wavy_header.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:moonjoin/features/parcel/widgets/parcel_view_widget.dart';

class ParcelLocationScreen extends StatefulWidget {
  final ParcelCategoryModel category;
  const ParcelLocationScreen({super.key, required this.category});

  @override
  State<ParcelLocationScreen> createState() => _ParcelLocationScreenState();
}

class _ParcelLocationScreenState extends State<ParcelLocationScreen> with TickerProviderStateMixin {
   final TextEditingController _senderNameController = TextEditingController();
   final TextEditingController _senderPhoneController = TextEditingController();
   final TextEditingController _receiverNameController = TextEditingController();
   final TextEditingController _receiverPhoneController = TextEditingController();
   final TextEditingController _senderStreetNumberController = TextEditingController();
   final TextEditingController _senderHouseController = TextEditingController();
   final TextEditingController _senderFloorController = TextEditingController();
   final TextEditingController _receiverStreetNumberController = TextEditingController();
   final TextEditingController _receiverHouseController = TextEditingController();
   final TextEditingController _receiverFloorController = TextEditingController();
   final TextEditingController _guestSenderEmailController = TextEditingController();
   final TextEditingController _guestReceiverEmailController = TextEditingController();
   final TextEditingController _senderAddressController = TextEditingController();
   final TextEditingController _receiverAddressController = TextEditingController();

  TabController? _tabController;
  String? _countryDialCode;
  bool firstTime = true;

  @override
  void initState() {
    super.initState();
    initCall();
  }

  Future<void> initCall() async {
    _tabController = TabController(length: 2, initialIndex: 0, vsync: this);

    _countryDialCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty ? Get.find<AuthController>().getUserCountryCode()
        : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;

    Get.find<ParcelController>().setPickupAddress(AddressHelper.getUserAddressFromSharedPref(), false);
    Get.find<ParcelController>().setDestinationAddress(AddressHelper.getUserAddressFromSharedPref(), notify: false);
    Get.find<ParcelController>().setIsPickedUp(true, false);
    Get.find<ParcelController>().setIsSender(true, false);
    Get.find<ParcelController>().setCountryCode(_countryDialCode!, true);
    Get.find<ParcelController>().setCountryCode(_countryDialCode!, false);
    if(AuthHelper.isLoggedIn() && Get.find<AddressController>().addressList == null) {
      Get.find<AddressController>().getAddressList();
    }
    if (AuthHelper.isLoggedIn()){
      if(Get.find<ProfileController>().userInfoModel == null){
        await Get.find<ProfileController>().getUserInfo();
        _senderNameController.text = Get.find<ProfileController>().userInfoModel != null ? '${Get.find<ProfileController>().userInfoModel!.fName!} ${Get.find<ProfileController>().userInfoModel!.lName!}' : '';
        _countryDialCode = await splitPhoneNumber(Get.find<ProfileController>().userInfoModel != null ? Get.find<ProfileController>().userInfoModel!.phone! : '', true);
        _senderPhoneController.text = await splitPhoneNumber(Get.find<ProfileController>().userInfoModel != null ? Get.find<ProfileController>().userInfoModel!.phone! : '', false);
      }else{
        _senderNameController.text = '${Get.find<ProfileController>().userInfoModel!.fName!} ${Get.find<ProfileController>().userInfoModel!.lName!}';
        _countryDialCode = await splitPhoneNumber(Get.find<ProfileController>().userInfoModel != null ? Get.find<ProfileController>().userInfoModel!.phone! : '', true);
        _senderPhoneController.text = await splitPhoneNumber(Get.find<ProfileController>().userInfoModel != null ? Get.find<ProfileController>().userInfoModel!.phone! : '', false);
      }
      Get.find<ParcelController>().setCountryCode(_countryDialCode!, true);
      Get.find<ParcelController>().setCountryCode(_countryDialCode!, false);
      setState(() {});

    }

    _tabController?.addListener((){
      Get.find<ParcelController>().setIsPickedUp(_tabController!.index == 0, false);
      Get.find<ParcelController>().setIsSender(_tabController!.index == 0, true);
    });
  }

   Future<String> splitPhoneNumber(String number, bool returnCountyCode) async {
    String code = '';
    String pNumber = '';
    try {
      PhoneNumber phoneNumber = PhoneNumber.parse(number);
      code = '+${phoneNumber.countryCode}';
      pNumber = phoneNumber.international.substring(_countryDialCode!.length);
    } catch (e) {
      debugPrint('number can\'t parse : $e');
    }
     if(returnCountyCode) {
       return code;
     } else {
       return pNumber;
     }
   }

  @override
  void dispose() {
    super.dispose();
    _senderNameController.dispose();
    _senderPhoneController.dispose();
    _receiverNameController.dispose();
    _receiverPhoneController.dispose();
    _senderStreetNumberController.dispose();
    _senderHouseController.dispose();
    _senderFloorController.dispose();
    _receiverStreetNumberController.dispose();
    _receiverHouseController.dispose();
    _receiverFloorController.dispose();
    _guestSenderEmailController.dispose();
    _guestReceiverEmailController.dispose();
    _senderAddressController.dispose();
    _receiverAddressController.dispose();
    _tabController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      appBar: isDesktop ? CustomAppBar(title: 'parcel_location'.tr) : null,
      endDrawer: const MenuDrawer(),
      endDrawerEnableOpenDragGesture: false,
      body: GetBuilder<ParcelController>(builder: (parcelController) {
        return Column(children: [

          if(!isDesktop) _header(context, parcelController),

          Expanded(child: Column(children: [

            Center(
              child: Container(
                alignment: Alignment.center,
                width: Dimensions.webMaxWidth,
                margin: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                ),
                child: TabBar(
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.zero,
                  controller: _tabController,
                  indicatorColor: Colors.transparent,
                  indicatorWeight: 0.1,
                  dividerColor: Colors.transparent,
                  onTap: (int index) {
                    if(index == 1) {
                      _validateSender(parcelController);
                    }
                  },
                  tabs: [
                    _toggleTab(context, 'sender_info'.tr, parcelController.isSender),
                    _toggleTab(context, 'receiver_info'.tr, !parcelController.isSender),
                  ],
                ),
              ),
            ),

            Expanded(child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ParcelViewWidget(
                  isSender: true, nameController: _senderNameController, phoneController: _senderPhoneController, bottomButton: _bottomButton(),
                  streetController: _senderStreetNumberController, floorController: _senderFloorController, houseController: _senderHouseController,
                  countryCode: parcelController.senderCountryCode, guestEmailController: _guestSenderEmailController,
                  senderAddressController: _senderAddressController, receiverAddressController: _receiverAddressController,
                ),

                ParcelViewWidget(
                  isSender: false, nameController: _receiverNameController, phoneController: _receiverPhoneController, bottomButton: _bottomButton(),
                  streetController: _receiverStreetNumberController, floorController: _receiverFloorController, houseController: _receiverHouseController,
                  countryCode: parcelController.receiverCountryCode, guestEmailController: _guestReceiverEmailController,
                  senderAddressController: _senderAddressController, receiverAddressController: _receiverAddressController,
                ),
              ],
            )),
          ])),

          isDesktop ? const SizedBox() : SafeArea(top: false, child: _bottomButton()),

        ]);
      }),
    );
  }

  /// Green wavy header (reuses the frozen WavyHeader): back button, title +
  /// subtitle, and the 2-step (1 → 2) indicator driven by the sender/receiver tab.
  Widget _header(BuildContext context, ParcelController parcelController) {
    final Color green = Theme.of(context).primaryColor;
    final double topInset = MediaQuery.of(context).padding.top;
    final int step = parcelController.isSender ? 1 : 2;
    return SizedBox(
      height: topInset + 150,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(top: 0, left: 0, right: 0, child: WavyHeader(height: topInset + 150, color: green)),

        Positioned(
          top: topInset + Dimensions.paddingSizeExtraSmall, left: Dimensions.paddingSizeDefault,
          child: InkWell(
            onTap: () => Get.back(),
            customBorder: const CircleBorder(),
            child: Container(
              height: 42, width: 42, alignment: Alignment.center,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: Icon(Icons.arrow_back, color: green, size: 20),
            ),
          ),
        ),

        Positioned(
          top: topInset + Dimensions.paddingSizeSmall, left: 64, right: 64,
          child: Column(children: [
            Text('parcel_location'.tr, textAlign: TextAlign.center,
                style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge)),
            const SizedBox(height: 2),
            Text('provide_pickup_location_and_sender_details'.tr, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: Dimensions.fontSizeSmall)),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Row(mainAxisSize: MainAxisSize.min, children: [
              _stepCircle(context, '1', step >= 1),
              Container(width: 44, height: 2, color: Colors.white.withValues(alpha: step >= 2 ? 0.9 : 0.35)),
              _stepCircle(context, '2', step >= 2),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _stepCircle(BuildContext context, String n, bool active) {
    return Container(
      height: 28, width: 28, alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: active ? Colors.white : Colors.white.withValues(alpha: 0.25)),
      child: Text(n, style: robotoBold.copyWith(color: active ? Theme.of(context).primaryColor : Colors.white, fontSize: Dimensions.fontSizeSmall)),
    );
  }

  Widget _toggleTab(BuildContext context, String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall + 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Theme.of(context).primaryColor : null,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.person_outline, size: 18, color: active ? Colors.white : Theme.of(context).primaryColor),
        const SizedBox(width: Dimensions.paddingSizeExtraSmall),
        Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeDefault, color: active ? Colors.white : Theme.of(context).primaryColor))),
      ]),
    );
  }

  Widget _bottomButton() {
    return GetBuilder<ParcelController>(builder: (parcelController) {
      return CustomButton(
        margin: ResponsiveHelper.isDesktop(context) ? null : const EdgeInsets.all(Dimensions.paddingSizeSmall),
        buttonText: parcelController.isSender ? 'continue'.tr : 'save_and_continue'.tr,
        onPressed: () async {
          if( _tabController!.index == 0 ) {
            _validateSender(parcelController);
          } else{
            String numberWithCountryCode = '${parcelController.receiverCountryCode??''}${_receiverPhoneController.text.trim()}';
            PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
            numberWithCountryCode = phoneValid.phone;

            if(parcelController.destinationAddress == null) {
              showCustomSnackBar('select_destination_address'.tr);
            } else if(_receiverNameController.text.isEmpty){
              showCustomSnackBar('enter_receiver_name'.tr);
            } else if(_receiverPhoneController.text.isEmpty){
              showCustomSnackBar('enter_receiver_phone_number'.tr);
            } else if (!phoneValid.isValid) {
              showCustomSnackBar('invalid_phone_number'.tr);
            } else {
              AddressModel destination = AddressModel(
                address: parcelController.destinationAddress!.address,
                additionalAddress: parcelController.destinationAddress!.additionalAddress,
                addressType: parcelController.destinationAddress!.addressType,
                contactPersonName: _receiverNameController.text.trim(),
                contactPersonNumber: numberWithCountryCode,
                latitude: parcelController.destinationAddress!.latitude,
                longitude: parcelController.destinationAddress!.longitude,
                method: parcelController.destinationAddress!.method,
                zoneId: parcelController.destinationAddress!.zoneId,
                zoneIds: parcelController.destinationAddress!.zoneIds,
                id: parcelController.destinationAddress!.id,
                streetNumber: _receiverStreetNumberController.text.trim(),
                house: _receiverHouseController.text.trim(),
                floor: _receiverFloorController.text.trim(),
                email: _guestReceiverEmailController.text.trim(),
                zoneData: parcelController.destinationAddress!.zoneData,
              );

              parcelController.setDestinationAddress(destination);

              Get.toNamed(RouteHelper.getParcelRequestRoute(
                widget.category,
                parcelController.pickupAddress!,
                parcelController.destinationAddress!,
              ));
              Get.find<CheckoutController>().updateFirstTime();
              Get.find<CheckoutController>().updateFirstTimeCodActive();
            }
         }
        },
      );
    });
  }

  Future<void> _validateSender(ParcelController parcelController) async {
    String numberWithCountryCode = '${parcelController.senderCountryCode??''}${_senderPhoneController.text.trim()}';
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    if(parcelController.pickupAddress == null) {
      showCustomSnackBar('select_pickup_address'.tr);
      _tabController!.animateTo(0);
    } else if(_senderNameController.text.isEmpty){
      showCustomSnackBar('enter_sender_name'.tr);
      _tabController!.animateTo(0);
    } else if(_senderPhoneController.text.isEmpty){
      showCustomSnackBar('enter_sender_phone_number'.tr);
      _tabController!.animateTo(0);
    } else if (!phoneValid.isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
      _tabController!.animateTo(0);
    }else if(AuthHelper.isGuestLoggedIn() && _guestSenderEmailController.text.isEmpty){
      showCustomSnackBar('please_enter_sender_email'.tr);
      _tabController!.animateTo(0);
    }else if(AuthHelper.isGuestLoggedIn() && !CustomValidator.isEmailValid(_guestSenderEmailController.text.trim())){
      showCustomSnackBar('enter_valid_email_address'.tr);
      _tabController!.animateTo(0);
    } else{
      AddressModel pickup = AddressModel(
        address: parcelController.pickupAddress!.address,
        additionalAddress: parcelController.pickupAddress!.additionalAddress,
        addressType: parcelController.pickupAddress!.addressType,
        contactPersonName: _senderNameController.text.trim(),
        contactPersonNumber: numberWithCountryCode,
        latitude: parcelController.pickupAddress!.latitude,
        longitude: parcelController.pickupAddress!.longitude,
        method: parcelController.pickupAddress!.method,
        zoneId: parcelController.pickupAddress!.zoneId,
        id: parcelController.pickupAddress!.id,
        zoneIds: parcelController.pickupAddress!.zoneIds,
        streetNumber: _senderStreetNumberController.text.trim(),
        house: _senderHouseController.text.trim(),
        floor: _senderFloorController.text.trim(),
        email: _guestSenderEmailController.text.trim(),
        zoneData: parcelController.pickupAddress!.zoneData,
      );
      parcelController.setPickupAddress(pickup, true);
      // Use post-frame callback to delay tab animation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _tabController!.animateTo(1);
        }
      });
    }
  }

}
