import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/moonjoin/bottom_action_bar.dart';
import 'package:sixam_mart/common/widgets/moonjoin/filter_chip_widget.dart';
import 'package:sixam_mart/common/widgets/moonjoin/section_header.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/profile/widgets/profile_page_header.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/location/widgets/permission_dialog_widget.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/custom_validator.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_text_field.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/menu_drawer.dart';
import 'package:sixam_mart/features/location/screens/pick_map_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';

class AddAddressScreen extends StatefulWidget {
  final bool fromCheckout;
  final bool fromRide;
  final AddressModel? address;
  final int? zoneId;
  final bool forGuest;
  final bool fromNavBar;
  const AddAddressScreen({super.key, required this.fromCheckout, required this.fromRide, this.address, this.zoneId, this.forGuest = false, this.fromNavBar = false});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactPersonNameController = TextEditingController();
  final TextEditingController _contactPersonNumberController = TextEditingController();
  final TextEditingController _streetNumberController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _floorController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _addressNode = FocusNode();
  final FocusNode _levelNode = FocusNode();
  final FocusNode _nameNode = FocusNode();
  final FocusNode _numberNode = FocusNode();
  final FocusNode _streetNode = FocusNode();
  final FocusNode _houseNode = FocusNode();
  final FocusNode _floorNode = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  CameraPosition? _cameraPosition;
  late LatLng _initialPosition;
  bool _otherSelect = false;
  String? _countryDialCode = Get.find<AuthController>().getUserCountryCode().isNotEmpty ? Get.find<AuthController>().getUserCountryCode()
      : CountryCode.fromCountryCode(Get.find<SplashController>().configModel!.country!).dialCode;

  @override
  void initState() {
    super.initState();
    initCall();

    if(widget.address != null) {
      // Edit flow: getCurrentLocation is NOT auto-called (no camera animation),
      // so seed _cameraPosition with the map's initial camera. Prevents the
      // first onCameraIdle → updatePosition(null) null-throw that left the
      // spinner stuck until a manual current-location tap.
      _cameraPosition = CameraPosition(target: _initialPosition, zoom: 16);
      splitPhoneNumber(widget.address!.contactPersonNumber!);
      _contactPersonNameController.text = widget.address!.contactPersonName ?? '';
      _emailController.text = widget.address!.email ?? '';
      _streetNumberController.text = widget.address!.streetNumber ?? '';
      _houseController.text = widget.address!.house ?? '';
      _floorController.text = widget.address!.floor ?? '';

    }else if(Get.find<ProfileController>().userInfoModel != null && _contactPersonNameController.text.isEmpty) {
      _contactPersonNameController.text = '${Get.find<ProfileController>().userInfoModel!.fName} ${Get.find<ProfileController>().userInfoModel!.lName}';
      splitPhoneNumber(Get.find<ProfileController>().userInfoModel!.phone!);
    }

  }

  void initCall(){

    Get.find<LocationController>().setAddressTypeIndex(0, isUpdate: false);
    if(AuthHelper.isLoggedIn() && Get.find<ProfileController>().userInfoModel == null) {
      Get.find<ProfileController>().getUserInfo();
    }
    if(widget.address == null) {
      _initialPosition = LatLng(
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '0'),
        double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '0'),
      );
    }else {
      Get.find<LocationController>().setUpdateAddress(widget.address!);
      _initialPosition = LatLng(
        double.parse(widget.address!.latitude ?? '0'),
        double.parse(widget.address!.longitude ?? '0'),
      );

      if(widget.address!.addressType == 'home') {
        Get.find<LocationController>().setAddressTypeIndex(0, isUpdate: false);
      } else if (widget.address!.addressType == 'office') {
        Get.find<LocationController>().setAddressTypeIndex(1, isUpdate: false);
      } else {
        Get.find<LocationController>().setAddressTypeIndex(2, isUpdate: false);
        _levelController.text = widget.address!.addressType!;
        _otherSelect = true;
      }
    }
  }

  void splitPhoneNumber(String number) async {
    try {
      PhoneNumber phoneNumber = PhoneNumber.parse(number);
      _countryDialCode = '+${phoneNumber.countryCode}';
      _contactPersonNumberController.text = phoneNumber.international.substring(_countryDialCode!.length);
    } catch (e) {
      debugPrint('number can\'t parse : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);
    return Scaffold(
      endDrawer: const MenuDrawer(), endDrawerEnableOpenDragGesture: false,
      // MoonJoin Premium Address (mobile) uses ProfilePageHeader inside the body;
      // desktop keeps the legacy CustomAppBar. Title logic preserved.
      appBar: isDesktop ? CustomAppBar(title: widget.forGuest ? 'set_address'.tr : widget.address == null ? 'add_new_address'.tr : 'update_address'.tr) : null,
      body: SafeArea(
        child: GetBuilder<ProfileController>(builder: (profileController) {
          return GetBuilder<LocationController>(builder: (locationController) {
            _addressController.text = locationController.address!;

            return isDesktop ? _desktopBody(context, locationController) : _mobileBody(context, locationController);
          });
        }) ,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MoonJoin Premium Address — MOBILE (Phase: Premium Address Experience)
  // Presentation only. Grouping: Location → Delivery Address → Contact
  // Information → Address Details → Address Type → Primary Action. Every
  // controller call, GoogleMap callback, validation and navigation is preserved
  // exactly as the legacy screen.
  // ---------------------------------------------------------------------------
  Widget _mobileBody(BuildContext context, LocationController locationController) {
    final bool isRideLabel = widget.fromRide || (Get.find<SplashController>().module != null && Get.find<SplashController>().module!.moduleType.toString() == AppConstants.taxi);
    return Column(children: [

      ProfilePageHeader(
        title: widget.forGuest ? 'set_address'.tr : widget.address == null ? 'add_new_address'.tr : 'update_address'.tr,
      ),

      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeLarge, Dimensions.paddingSizeSmall, Dimensions.paddingSizeLarge, Dimensions.paddingSizeLarge),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ---- Location (premium floating map card) ----
          _premiumMapCard(context, locationController),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 14, color: Theme.of(context).disabledColor),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(child: Text(
              'add_the_location_correctly'.tr,
              style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: Dimensions.fontSizeExtraSmall),
            )),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // ---- Delivery Address ----
          SectionHeader(title: isRideLabel ? 'pickup_address'.tr : 'delivery_address'.tr),
          _sectionCard(context, [
            CustomTextField(
              showTitle: false,
              hintText: 'write_delivery_address'.tr,
              showLabelText: false,
              suffixIcon: Icons.my_location,
              inputType: TextInputType.streetAddress,
              controller: _addressController,
              focusNode: _addressNode,
              nextFocus: _nameNode,
              required: true,
              onChanged: (text) => locationController.setPlaceMark(text),
            ),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // ---- Contact Information ----
          SectionHeader(title: 'contact_information'.tr),
          _sectionCard(context, [
            CustomTextField(
              showTitle: true,
              titleText: 'contact_person_name'.tr,
              hintText: 'write_name'.tr,
              showLabelText: false,
              inputType: TextInputType.name,
              controller: _contactPersonNameController,
              focusNode: _nameNode,
              nextFocus: _numberNode,
              capitalization: TextCapitalization.words,
              required: true,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            CustomTextField(
              showTitle: true,
              titleText: 'contact_person_number'.tr,
              hintText: 'write_number'.tr,
              showLabelText: false,
              controller: _contactPersonNumberController,
              focusNode: _numberNode,
              nextFocus: widget.forGuest ? _emailFocus : _streetNode,
              inputType: TextInputType.phone,
              isPhone: true,
              required: true,
              onCountryChanged: (CountryCode countryCode) {
                _countryDialCode = countryCode.dialCode;
              },
              countryDialCode: _countryDialCode ?? Get.find<LocalizationController>().locale.countryCode,
            ),
            if(widget.forGuest) ...[
              const SizedBox(height: Dimensions.paddingSizeLarge),
              CustomTextField(
                showTitle: true,
                titleText: 'email'.tr,
                hintText: 'enter_email'.tr,
                showLabelText: false,
                controller: _emailController,
                focusNode: _emailFocus,
                nextFocus: _streetNode,
                inputType: TextInputType.emailAddress,
                prefixIcon: Icons.mail,
                required: true,
              ),
            ],
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // ---- Address Details ----
          SectionHeader(title: 'address_details'.tr),
          _sectionCard(context, [
            CustomTextField(
              showTitle: true,
              titleText: '${'street_number'.tr} (${'optional'.tr})',
              hintText: 'write_street_number'.tr,
              showLabelText: false,
              inputType: TextInputType.streetAddress,
              focusNode: _streetNode,
              nextFocus: _houseNode,
              controller: _streetNumberController,
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),
            Row(children: [
              Expanded(
                child: CustomTextField(
                  showTitle: true,
                  titleText: '${'house'.tr} (${'optional'.tr})',
                  hintText: 'write_house_number'.tr,
                  showLabelText: false,
                  inputType: TextInputType.text,
                  focusNode: _houseNode,
                  nextFocus: _floorNode,
                  controller: _houseController,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: CustomTextField(
                  showTitle: true,
                  titleText: "${'floor'.tr} (${'optional'.tr})",
                  hintText: 'write_floor_number'.tr,
                  showLabelText: false,
                  inputType: TextInputType.text,
                  focusNode: _floorNode,
                  inputAction: TextInputAction.done,
                  controller: _floorController,
                ),
              ),
            ]),
          ]),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // ---- Address Type ----
          SectionHeader(title: 'label_as'.tr),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          _typeChips(context, locationController),
          if(_otherSelect) ...[
            const SizedBox(height: Dimensions.paddingSizeLarge),
            CustomTextField(
              showTitle: true,
              titleText: '${'level_name'.tr}(${'optional'.tr})',
              hintText: 'write_level_name'.tr,
              showLabelText: false,
              inputType: TextInputType.text,
              controller: _levelController,
              focusNode: _levelNode,
              nextFocus: _addressNode,
              capitalization: TextCapitalization.words,
            ),
          ],

        ]),
      )),

      // ---- Primary Action (pinned) ----
      BottomActionBar(child: _primaryAction(locationController)),
    ]);
  }

  // Premium floating map card — the exact legacy mobile GoogleMap + overlays,
  // wrapped in a rounded, shadowed MoonJoin surface with a floating pin, a
  // current-location FAB and a fullscreen (pick-map) affordance. No map
  // callback / controller behaviour changed.
  Widget _premiumMapCard(BuildContext context, LocationController locationController) {
    return Container(
      height: 190,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        child: Stack(clipBehavior: Clip.none, children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 16),
            minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
            onTap: (latLng) {
              if(ResponsiveHelper.isDesktop(Get.context)) {
                showGeneralDialog(context: context, pageBuilder: (_, _, _) {
                  return SizedBox(
                      height: 300, width: 300,
                      child: PickMapScreen(fromSignUp: false, canRoute: false, fromAddAddress: true, route: null, googleMapController: locationController.mapController)
                  );
                });
              }else {
                Get.toNamed(
                  RouteHelper.getPickMapRoute('add-address', false),
                  arguments: PickMapScreen(
                    fromAddAddress: true,
                    fromSignUp: false,
                    googleMapController: locationController.mapController,
                    route: null,
                    canRoute: false,
                  ),
                );
              }
            },
            zoomControlsEnabled: false,
            compassEnabled: false,
            indoorViewEnabled: true,
            mapToolbarEnabled: false,
            onCameraIdle: () {
              locationController.updatePosition(_cameraPosition, true);
            },
            onCameraMove: ((position) {
              _cameraPosition = position;
            }
            ),
            onMapCreated: (GoogleMapController controller) {
              locationController.setMapController(controller);
              if(widget.address == null) {
                locationController.getCurrentLocation(true, mapController: controller);
              }
            },
            myLocationButtonEnabled: false,
            style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
              Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
              Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
            },
          ),

          // Floating center pin (with soft base shadow). IgnorePointer so map
          // taps (open Pick Map) pass through the pin.
          IgnorePointer(child: Center(child: !locationController.loading ? Column(mainAxisSize: MainAxisSize.min, children: [
            Image.asset(Images.pickMarker, height: 50, width: 50),
            Container(
              width: 14, height: 4,
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 24),
          ]) : const CircularProgressIndicator())),

          // Current-location FAB (premium circular).
          Positioned(
            bottom: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
            child: InkWell(
              onTap: () => _checkPermission(() {
                locationController.getCurrentLocation(true, mapController: locationController.mapController);
              }),
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                ),
                child: Icon(Icons.my_location, color: Theme.of(context).primaryColor, size: 20),
              ),
            ),
          ),

          // Fullscreen (open Pick Map) affordance.
          Positioned(
            top: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
            child: InkWell(
              onTap: () {
                if(ResponsiveHelper.isDesktop(Get.context)) {
                  showGeneralDialog(context: context, pageBuilder: (_, _, _) {
                    return SizedBox(
                        height: 300, width: 300,
                        child: PickMapScreen(fromSignUp: false, canRoute: false, fromAddAddress: true, route: null, googleMapController: locationController.mapController)
                    );
                  });
                }else {
                  Get.toNamed(
                    RouteHelper.getPickMapRoute('add-address', false),
                    arguments: PickMapScreen(
                      fromAddAddress: true,
                      fromSignUp: false,
                      googleMapController: locationController.mapController,
                      route: null,
                      canRoute: false,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: Theme.of(context).cardColor,
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
                ),
                child: Icon(Icons.fullscreen, color: Theme.of(context).primaryColor, size: 20),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // Premium address-type chips (Home / Office / Others). onTap logic preserved.
  Widget _typeChips(BuildContext context, LocationController locationController) {
    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: List.generate(locationController.addressTypeList.length, (index) {
        final bool selected = locationController.addressTypeIndex == index;
        final IconData icon = index == 0 ? Icons.home_rounded : index == 1 ? Icons.work_rounded : Icons.location_on_rounded;
        final String label = index == 0 ? 'home'.tr : index == 1 ? 'office'.tr : 'others'.tr;
        return MoonjoinFilterChip(
          label: label,
          icon: icon,
          selected: selected,
          onTap: () {
            _otherSelect = index == 2;
            locationController.setAddressTypeIndex(index);
          },
        );
      }),
    );
  }

  // A grouped MoonJoin surface (card) that hosts a section's fields.
  Widget _sectionCard(BuildContext context, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  // Pinned primary action — Save / Update / Done. Logic preserved.
  Widget _primaryAction(LocationController locationController) {
    return GetBuilder<AddressController>(
      builder: (addressController) {
        return CustomButton(
          radius: Dimensions.radiusDefault,
          isBold: false,
          isLoading: addressController.isLoading,
          buttonText: widget.forGuest ? 'done'.tr : widget.address == null ? 'save_location'.tr : 'update_address'.tr,
          onPressed: () async => _onSaveOrUpdateButtonPressed(locationController),
        );
      }
    );
  }

  // ---------------------------------------------------------------------------
  // DESKTOP — legacy presentation preserved verbatim (mobile-first migration).
  // ---------------------------------------------------------------------------
  Widget _desktopBody(BuildContext context, LocationController locationController) {
    return SingleChildScrollView(
      child: FooterView(
        child: Column(
          children: [
            Container(
              height: 64,
              color: Theme.of(context).primaryColor.withValues(alpha: 0.10),
              child: Center(child: Text('address'.tr, style: robotoMedium)),
            ),
            const SizedBox(height: Dimensions.paddingSizeLarge),

            Center(
              child: SizedBox(
                width: Dimensions.webMaxWidth,
                child: Row( crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        color: Theme.of(context).cardColor,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width : 680,
                            height: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              border: Border.all(width: 2, color: Theme.of(context).primaryColor),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                              child: Stack(clipBehavior: Clip.none, children: [
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 16),
                                  minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                                  onTap: (latLng) {
                                    if(ResponsiveHelper.isDesktop(Get.context)) {

                                    }else {
                                      Get.toNamed(
                                        RouteHelper.getPickMapRoute('add-address', false),
                                        arguments: PickMapScreen(
                                          fromAddAddress: true,
                                          fromSignUp: false,
                                          googleMapController: locationController.mapController,
                                          route: null,
                                          canRoute: false,
                                        ),
                                      );
                                    }
                                  },
                                  zoomControlsEnabled: false,
                                  compassEnabled: false,
                                  indoorViewEnabled: true,
                                  mapToolbarEnabled: false,
                                  onCameraIdle: () {
                                    locationController.updatePosition(_cameraPosition, true);
                                  },
                                  onCameraMove: ((position) => _cameraPosition = position),
                                  onMapCreated: (GoogleMapController controller) {
                                    locationController.setMapController(controller);
                                    if(widget.address == null) {
                                      locationController.getCurrentLocation(true, mapController: controller);
                                    }
                                  },
                                  style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
                                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                    Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                                    Factory<PanGestureRecognizer>(() => PanGestureRecognizer()),
                                    Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
                                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
                                    Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                                  },
                                ),
                                locationController.loading ? const Center(child: CircularProgressIndicator()) : const SizedBox(),
                                Center(child: !locationController.loading ? Image.asset(Images.pickMarker, height: 50, width: 50)
                                    : const CircularProgressIndicator()),
                                Positioned(
                                  bottom: 10, right: 0,
                                  child: InkWell(
                                    onTap: () => _checkPermission(() {
                                      locationController.getCurrentLocation(true, mapController: locationController.mapController);
                                    }),
                                    child: Container(
                                      width: 30, height: 30,
                                      margin: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Colors.white),
                                      child: Icon(Icons.my_location, color: Theme.of(context).primaryColor, size: 20),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10, right: 0,
                                  child: InkWell(
                                    onTap: () {
                                      if(ResponsiveHelper.isDesktop(Get.context)) {
                                        showGeneralDialog(context: context, pageBuilder: (_, _, _) {
                                          return SizedBox(
                                            height: 300, width: 300,
                                            child: PickMapScreen(fromSignUp: false, canRoute: false, fromAddAddress: true, route: null, googleMapController: locationController.mapController)
                                          );
                                        });
                                      }else {
                                        Get.toNamed(
                                          RouteHelper.getPickMapRoute('add-address', false),
                                          arguments: PickMapScreen(
                                            fromAddAddress: true,
                                            fromSignUp: false,
                                            googleMapController: locationController.mapController,
                                            route: null,
                                            canRoute: false,
                                          ),
                                        );
                                      }
                                    },
                                    child: Container(
                                      width: 30, height: 30,
                                      margin: const EdgeInsets.only(right: Dimensions.paddingSizeLarge),
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusSmall), color: Colors.white),
                                      child: Icon(Icons.fullscreen, color: Theme.of(context).primaryColor, size: 20),
                                    ),
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),


                          Text(
                            'label_as'.tr,
                            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyMedium!.color),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          SizedBox(height: 50, child: ListView.builder(
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            itemCount: locationController.addressTypeList.length,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                              child: InkWell(
                                onTap: () {
                                  _otherSelect = index == 2;
                                  locationController.setAddressTypeIndex(index);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                                      color: locationController.addressTypeIndex == index ? Theme.of(context).primaryColor : Theme.of(context).cardColor,
                                      boxShadow: const [BoxShadow(color: Colors.black12, spreadRadius: 1, blurRadius: 5)],
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        height: 24, width: 24,
                                        child: Image.asset(
                                          index == 0 ? Images.homeIcon : index == 1 ? Images.workIcon : Images.otherIcon,
                                          color: locationController.addressTypeIndex == index ? Theme.of(context).cardColor : Theme.of(context).disabledColor,
                                        ),
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeSmall),

                                      Text(index == 0 ? 'home'.tr : index == 1 ? 'office'.tr : 'others'.tr,
                                        style: robotoRegular.copyWith(color: locationController.addressTypeIndex == index ? Theme.of(context).cardColor : Theme.of(context).disabledColor),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )),
                          const SizedBox(height: Dimensions.paddingSizeSmall),

                          _otherSelect ? SizedBox (
                            height: 90, width: 680,
                            child: CustomTextField(
                              titleText: '${'level_name'.tr}(${'optional'.tr})',
                              hintText: 'write_level_name'.tr,
                              showTitle: true,
                              inputType: TextInputType.text,
                              controller: _levelController,
                              focusNode: _levelNode,
                              nextFocus: _addressNode,
                              capitalization: TextCapitalization.words,
                            ),
                          ) : const SizedBox(),

                          const SizedBox(height: Dimensions.paddingSizeLarge),
                          SizedBox(height: 90, width: 680,
                            child: CustomTextField(
                              suffixIcon: Icons.my_location,
                              showTitle: true,
                              titleText: 'delivery_address'.tr,
                              hintText: 'write_delivery_address'.tr,
                              inputType: TextInputType.streetAddress,
                              controller: _addressController,
                              focusNode: _addressNode,
                              nextFocus: _nameNode,
                              required: true,
                              onChanged: (text) => locationController.setPlaceMark(text),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeLarge),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeLarge),

                    Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                            color: Theme.of(context).cardColor,
                            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                          ),
                          child: Column(
                            children: [

                              CustomTextField(
                                showTitle: true,
                                titleText: 'contact_person_name'.tr,
                                hintText: 'write_name'.tr,
                                showLabelText: false,
                                inputType: TextInputType.name,
                                controller: _contactPersonNameController,
                                focusNode: _nameNode,
                                nextFocus: _numberNode,
                                capitalization: TextCapitalization.words,
                                required: true,
                              ),
                              const SizedBox(height: Dimensions.paddingSizeLarge),

                              CustomTextField(
                                showTitle: true,
                                titleText: 'contact_person_number'.tr,
                                hintText: 'write_number'.tr,
                                showLabelText: false,
                                controller: _contactPersonNumberController,
                                focusNode: _numberNode,
                                nextFocus: widget.forGuest ? _emailFocus :_streetNode,
                                inputType: TextInputType.phone,
                                isPhone: true,
                                required: true,
                                onCountryChanged: (CountryCode countryCode) {
                                  _countryDialCode = countryCode.dialCode;
                                },
                                countryDialCode: _countryDialCode ?? Get.find<LocalizationController>().locale.countryCode,
                              ),
                              const SizedBox(height: Dimensions.paddingSizeLarge),

                              widget.forGuest ? CustomTextField(
                                showTitle: true,
                                titleText: 'email'.tr,
                                hintText: 'email'.tr,
                                showLabelText: false,
                                controller: _emailController,
                                focusNode: _emailFocus,
                                nextFocus: _streetNode,
                                inputType: TextInputType.emailAddress,
                                required: true,
                              ) : const SizedBox(),
                              SizedBox(height: widget.forGuest ? Dimensions.paddingSizeLarge : 0),

                              CustomTextField(
                                showTitle: true,
                                hintText: 'street_number'.tr,
                                titleText: '${'street_number'.tr} (${'optional'.tr})',
                                showLabelText: false,
                                inputType: TextInputType.streetAddress,
                                focusNode: _streetNode,
                                nextFocus: _houseNode,
                                controller: _streetNumberController,
                              ),
                              const SizedBox(height: Dimensions.paddingSizeLarge),

                              Row(children: [
                                Expanded(
                                  child: CustomTextField(
                                    showTitle: true,
                                    hintText: 'house_name'.tr,
                                    titleText: '${'house'.tr} (${'optional'.tr})',
                                    showLabelText: false,
                                    inputType: TextInputType.text,
                                    focusNode: _houseNode,
                                    nextFocus: _floorNode,
                                    controller: _houseController,
                                  ),
                                ),
                                const SizedBox(width: Dimensions.paddingSizeSmall),

                                Expanded(
                                  child: CustomTextField(
                                    hintText: 'floor_number'.tr,
                                    showLabelText: false,
                                    showTitle: true,
                                    titleText: "${'floor'.tr} (${'optional'.tr})",
                                    inputType: TextInputType.text,
                                    focusNode: _floorNode,
                                    inputAction: TextInputAction.done,
                                    controller: _floorController,
                                  ),
                                ),
                              ]),
                              const SizedBox(height: Dimensions.paddingSizeLarge),

                              button(locationController),
                            ],
                          ),
                        )
                    ),


                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _checkPermission(Function onTap) async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.denied) {
      showCustomSnackBar('you_have_to_allow'.tr);
    }else if(permission == LocationPermission.deniedForever) {
      Get.dialog(const PermissionDialogWidget());
    }else {
      onTap();
    }
  }

  Widget button(LocationController locationController) {
    return GetBuilder<AddressController>(
      builder: (addressController) {
        return Container(
          width: Dimensions.webMaxWidth,
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          child: CustomButton(
            radius: Dimensions.radiusSmall,
            isBold: false,
            isLoading: addressController.isLoading,
            buttonText: widget.forGuest ? 'done'.tr : widget.address == null ? 'save_location'.tr : 'update_address'.tr,
            onPressed: () async => _onSaveOrUpdateButtonPressed(locationController),
          ),
        );
      }
    );
  }

  void _onSaveOrUpdateButtonPressed(LocationController locationController) async {

    String numberWithCountryCode = _countryDialCode! + _contactPersonNumberController.text;
    PhoneValid phoneValid = await CustomValidator.isPhoneValid(numberWithCountryCode);
    numberWithCountryCode = phoneValid.phone;

    AddressModel? addressModel = _prepareAddressModel(locationController, phoneValid.isValid, numberWithCountryCode);
    if(addressModel == null) {
      return;
    }

    if(widget.forGuest) {
      addressModel.email = _emailController.text;
      Get.back(result: addressModel);
    } else {
      if(widget.address == null) {
        _addAddress(addressModel);
      }else {
        _updateAddress(addressModel);
      }
    }

  }

  AddressModel? _prepareAddressModel(LocationController locationController, bool isValid, String numberWithCountryCode) {
    String? addressType = locationController.addressTypeList[locationController.addressTypeIndex];
    if(locationController.addressTypeIndex == 2){
      addressType = _levelController.text.isNotEmpty ? _levelController.text.trim() : locationController.addressTypeList[locationController.addressTypeIndex];
    }
    if(_addressController.text.isEmpty) {
      showCustomSnackBar('please_enter_the_delivery_address'.tr);
    } else if(_contactPersonNameController.text.isEmpty) {
      showCustomSnackBar('please_enter_the_contact_person_name'.tr);
    } else if(_contactPersonNumberController.text.isEmpty) {
      showCustomSnackBar('please_enter_the_phone_number'.tr);
    } else if (!isValid) {
      showCustomSnackBar('invalid_phone_number'.tr);
    } else if(widget.forGuest && _emailController.text.isEmpty) {
      showCustomSnackBar('please_enter_contact_person_email'.tr);
    } else {
      AddressModel addressModel = AddressModel(
        id: widget.address?.id,
        addressType: addressType,
        contactPersonName: _contactPersonNameController.text,
        contactPersonNumber: _countryDialCode! + _contactPersonNumberController.text,
        address: _addressController.text,
        latitude: locationController.position.latitude.toString(),
        longitude: locationController.position.longitude.toString(),
        zoneId: locationController.zoneID,
        streetNumber: _streetNumberController.text,
        house: _houseController.text,
        floor: _floorController.text,
      );
      return addressModel;
    }
    return null;
  }

  void _addAddress(AddressModel addressModel) {
    Get.find<AddressController>().addAddress(addressModel, widget.fromCheckout, widget.zoneId).then((response) {
      if(response.isSuccess && !widget.fromCheckout) {
        widget.fromNavBar ? Get.back() : Get.offNamed(RouteHelper.getAddressRoute());
        showCustomSnackBar('new_address_added_successfully'.tr, isError: false);
      } else if(response.isSuccess && widget.fromCheckout) {
        AddressModel? addressModel;
        try{
          addressModel = Get.find<AddressController>().addressList![0];
        }catch(_) {}
        Get.back(result: addressModel);
        showCustomSnackBar(response.message, isError: false);
      } else if(widget.fromRide) {
        Get.back();
      } else {
        showCustomSnackBar(response.message);
      }
    });
  }

  void _updateAddress(AddressModel addressModel) {
    Get.find<AddressController>().updateAddress(addressModel, widget.address!.id).then((response) {
      if(response.isSuccess) {
        Get.back();
        showCustomSnackBar(response.message, isError: false);
      }else {
        showCustomSnackBar(response.message);
      }
    });
  }

}
