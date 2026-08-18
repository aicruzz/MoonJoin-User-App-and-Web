import 'package:geolocator/geolocator.dart';
import 'package:moonjoin/common/controllers/theme_controller.dart';
import 'package:moonjoin/common/widgets/moonjoin/bottom_action_bar.dart';
import 'package:moonjoin/features/location/controllers/location_controller.dart';
import 'package:moonjoin/features/splash/controllers/splash_controller.dart';
import 'package:moonjoin/features/profile/controllers/profile_controller.dart';
import 'package:moonjoin/features/address/domain/models/address_model.dart';
import 'package:moonjoin/features/auth/controllers/auth_controller.dart';
import 'package:moonjoin/helper/address_helper.dart';
import 'package:moonjoin/helper/auth_helper.dart';
import 'package:moonjoin/helper/responsive_helper.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/images.dart';
import 'package:moonjoin/util/styles.dart';
import 'package:moonjoin/common/widgets/custom_button.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/common/widgets/menu_drawer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:moonjoin/features/location/widgets/serach_location_widget.dart';

class PickMapScreen extends StatefulWidget {
  final bool fromSignUp;
  final bool fromAddAddress;
  final bool canRoute;
  final String? route;
  final GoogleMapController? googleMapController;
  final Function(AddressModel address)? onPicked;
  final bool fromLandingPage;
  const PickMapScreen({super.key,
    required this.fromSignUp, required this.fromAddAddress, required this.canRoute,
    required this.route, this.googleMapController, this.onPicked, this.fromLandingPage = false,
  });

  @override
  State<PickMapScreen> createState() => _PickMapScreenState();
}

class _PickMapScreenState extends State<PickMapScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _cameraPosition;
  late LatLng _initialPosition;
  bool locationAlreadyAllow = false;

  @override
  void initState() {
    super.initState();

    if(widget.fromAddAddress) {
      Get.find<LocationController>().setPickData();
      // Seed _cameraPosition with the map's initial camera so the first
      // onCameraIdle → updatePosition is never null (parity with the Add flow).
      _cameraPosition = CameraPosition(
        target: LatLng(
          Get.find<LocationController>().position.latitude,
          Get.find<LocationController>().position.longitude,
        ),
        zoom: 16,
      );
    }
    _initialPosition = LatLng(
      double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lat ?? '0'),
      double.parse(Get.find<SplashController>().configModel!.defaultLocation!.lng ?? '0'),
    );
    _checkAlreadyLocationEnable();
  }

  Future<void> _checkAlreadyLocationEnable() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if(permission == LocationPermission.whileInUse) {
      locationAlreadyAllow = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResponsiveHelper.isDesktop(context) ? Colors.transparent : Theme.of(context).cardColor,
      endDrawer: const MenuDrawer(),endDrawerEnableOpenDragGesture: false,
      body: ResponsiveHelper.isDesktop(context)
          ? SafeArea(child: Center(child: Container(
              height: 600, width: 700,
              decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(Dimensions.radiusSmall)),
              child: GetBuilder<LocationController>(builder: (locationController) => _desktopBody(context, locationController)),
            )))
          : GetBuilder<LocationController>(builder: (locationController) => _mobileBody(context, locationController)),
    );
  }

  // ---------------------------------------------------------------------------
  // MoonJoin Premium Pick Map — MOBILE. Uber/Glovo-style full-screen picker:
  // full-bleed map, floating center pin, premium search + back + current-
  // location controls, and a bottom card showing the selected address + the
  // zone-aware action. Every map callback and _onPickAddressButtonPressed
  // preserved exactly.
  // ---------------------------------------------------------------------------
  Widget _mobileBody(BuildContext context, LocationController locationController) {
    return Stack(children: [
      GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.fromAddAddress ? LatLng(locationController.position.latitude, locationController.position.longitude)
              : _initialPosition,
          zoom: 16,
        ),
        minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
        myLocationButtonEnabled: false,
        onMapCreated: (GoogleMapController mapController) async {
          _mapController = mapController;
          if(!widget.fromAddAddress && widget.route != 'splash') {
            Get.find<LocationController>().getCurrentLocation(false, mapController: mapController).then((value) async {
              if(widget.fromLandingPage && !locationAlreadyAllow && await _locationCheck()) {
                _onPickAddressButtonPressed(locationController);
              }
            });
          }
        },
        scrollGesturesEnabled: !Get.isDialogOpen!,
        zoomControlsEnabled: false,
        onCameraMove: (CameraPosition cameraPosition) {
          _cameraPosition = cameraPosition;
        },
        onCameraMoveStarted: () {
          locationController.disableButton();
        },
        onCameraIdle: () {
          Get.find<LocationController>().updatePosition(_cameraPosition, false);
        },
        style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
      ),

      // Floating center pin (with soft base shadow).
      Center(child: !locationController.loading ? Column(mainAxisSize: MainAxisSize.min, children: [
        Image.asset(Images.pickMarker, height: 50, width: 50),
        Container(
          width: 14, height: 4,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(height: 24),
      ]) : const CircularProgressIndicator()),

      // Top: back + premium search.
      Positioned(
        top: Dimensions.paddingSizeLarge, left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall,
        child: SafeArea(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InkWell(
            onTap: () => Get.back(),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Theme.of(context).textTheme.bodyLarge!.color),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(child: SearchLocationWidget(mapController: _mapController, pickedAddress: locationController.pickAddress, isEnabled: null)),
        ])),
      ),

      // Current-location FAB (sits above the bottom card).
      Positioned(
        bottom: 170, right: Dimensions.paddingSizeLarge,
        child: FloatingActionButton(
          mini: true, backgroundColor: Theme.of(context).cardColor, elevation: 2,
          onPressed: () => Get.find<LocationController>().checkPermission(() {
            Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
          }),
          child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
        ),
      ),

      // Bottom: selected address + zone-aware action.
      Positioned(
        left: 0, right: 0, bottom: 0,
        child: BottomActionBar(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.location_on_rounded, color: Theme.of(context).primaryColor, size: 20),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(child: Text(
                (locationController.pickAddress != null && locationController.pickAddress!.isNotEmpty)
                    ? locationController.pickAddress! : 'move_the_map_to_select'.tr,
                style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).textTheme.bodyLarge!.color),
                maxLines: 2, overflow: TextOverflow.ellipsis,
              )),
            ]),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            CustomButton(
              radius: Dimensions.radiusDefault,
              isBold: false,
              buttonText: locationController.inZone ? widget.fromAddAddress ? 'pick_address'.tr : 'pick_location'.tr
                  : 'service_not_available_in_this_area'.tr,
              isLoading: locationController.isLoading,
              onPressed: locationController.isLoading ? (){} : (locationController.buttonDisabled || locationController.loading) ? null : () {
                _onPickAddressButtonPressed(locationController);
              },
            ),
          ]),
        ),
      ),
    ]);
  }

  // ---------------------------------------------------------------------------
  // DESKTOP — legacy presentation preserved verbatim.
  // ---------------------------------------------------------------------------
  Widget _desktopBody(BuildContext context, LocationController locationController) {
    return Padding(
      padding: const  EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall, horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.clear),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Text('type_your_address_here_to_pick_form_map'.tr, style: robotoBold),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          SearchLocationWidget(mapController: _mapController, pickedAddress: locationController.pickAddress, isEnabled: null, fromDialog: true),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          SizedBox(
            height: 350,
            child:  Stack(children: [
              ClipRRect(
                borderRadius:BorderRadius.circular(Dimensions.radiusDefault),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: widget.fromAddAddress ? LatLng(locationController.position.latitude, locationController.position.longitude)
                        : _initialPosition,
                    zoom: 16,
                  ),
                  minMaxZoomPreference: const MinMaxZoomPreference(0, 16),
                  myLocationButtonEnabled: false,
                  onMapCreated: (GoogleMapController mapController) async {
                    _mapController = mapController;
                    if(!widget.fromAddAddress && widget.route != 'splash') {
                      Get.find<LocationController>().getCurrentLocation(false, mapController: mapController).then((value) async {
                        if(widget.fromLandingPage && !locationAlreadyAllow && await _locationCheck()) {
                          _onPickAddressButtonPressed(locationController);
                        }
                      });
                    }
                  },
                  scrollGesturesEnabled: !Get.isDialogOpen!,
                  zoomControlsEnabled: false,
                  onCameraMove: (CameraPosition cameraPosition) {
                    _cameraPosition = cameraPosition;
                  },
                  onCameraMoveStarted: () {
                    locationController.disableButton();
                  },
                  onCameraIdle: () {
                    Get.find<LocationController>().updatePosition(_cameraPosition, false);
                  },
                  style: Get.isDarkMode ? Get.find<ThemeController>().darkMap : Get.find<ThemeController>().lightMap,
                ),
              ),

              Center(child: !locationController.loading ? Image.asset(Images.pickMarker, height: 50, width: 50)
                  : const CircularProgressIndicator()),

              Positioned(
                bottom: 75, right: Dimensions.paddingSizeSmall,
                child: FloatingActionButton(
                  mini: true, backgroundColor: Theme.of(context).cardColor,
                  onPressed: () => Get.find<LocationController>().checkPermission(() {
                    Get.find<LocationController>().getCurrentLocation(false, mapController: _mapController);
                  }),
                  child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                ),
              ),
            ]),
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          CustomButton(
            isBold: false,
            radius: Dimensions.radiusSmall,
            buttonText: locationController.inZone ? widget.fromAddAddress ? 'pick_address'.tr : 'pick_location'.tr
                : 'service_not_available_in_this_area'.tr,
            isLoading: locationController.isLoading,
            onPressed: locationController.isLoading ? (){} : (locationController.buttonDisabled || locationController.loading) ? null : () {
              _onPickAddressButtonPressed(locationController);
            },
          ),

        ],
      ),
    );
  }

  void _onPickAddressButtonPressed(LocationController locationController) {
    if(locationController.pickPosition.latitude != 0 && locationController.pickAddress!.isNotEmpty) {
      if(widget.onPicked != null) {
        AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: 'others', address: locationController.pickAddress,
          contactPersonName: AddressHelper.getUserAddressFromSharedPref()!.contactPersonName,
          contactPersonNumber: AddressHelper.getUserAddressFromSharedPref()!.contactPersonNumber,
        );
        widget.onPicked!(address);
        Get.back();
      }else if(widget.fromAddAddress) {
        if(widget.googleMapController != null) {
          widget.googleMapController!.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(
            locationController.pickPosition.latitude, locationController.pickPosition.longitude,
          ), zoom: 16)));
          locationController.setAddAddressData();
        }
        Get.back();
      }else {
        AddressModel address = AddressModel(
          latitude: locationController.pickPosition.latitude.toString(),
          longitude: locationController.pickPosition.longitude.toString(),
          addressType: 'others', address: locationController.pickAddress,
        );

        if(widget.fromLandingPage) {
          if(!AuthHelper.isGuestLoggedIn() && !AuthHelper.isLoggedIn()) {
            Get.find<AuthController>().guestLogin().then((response) {
              if(response.isSuccess) {
                Get.find<ProfileController>().setForceFullyUserEmpty();
                Get.back();
                locationController.saveAddressAndNavigate(
                  address, widget.fromSignUp, widget.route, widget.canRoute, ResponsiveHelper.isDesktop(Get.context),
                );
              }
            });
          } else {
            Get.back();
            locationController.saveAddressAndNavigate(
              address, widget.fromSignUp, widget.route, widget.canRoute, ResponsiveHelper.isDesktop(context),
            );
          }
        }else {
          locationController.saveAddressAndNavigate(
            address, widget.fromSignUp, widget.route, widget.canRoute, ResponsiveHelper.isDesktop(context),
          );
        }
      }
    }else {
      showCustomSnackBar('pick_an_address'.tr);
    }
  }

  Future<bool> _locationCheck() async {
    bool locationServiceEnabled = true;
    LocationPermission permission = await Geolocator.checkPermission();

    if(permission == LocationPermission.denied) {
      locationServiceEnabled = false;
      permission = await Geolocator.requestPermission();
    }
    if(permission == LocationPermission.deniedForever) {
      locationServiceEnabled = false;
    }
    return locationServiceEnabled;
  }

}
