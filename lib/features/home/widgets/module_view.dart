import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:sixam_mart/common/widgets/address_widget.dart';
import 'package:sixam_mart/features/banner/controllers/banner_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/address/controllers/address_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_loader.dart';
import 'package:sixam_mart/common/widgets/title_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/home/widgets/popular_store_view.dart';
import 'package:sixam_mart/common/models/module_model.dart';

class ModuleView extends StatelessWidget {
  final SplashController splashController;
  const ModuleView({super.key, required this.splashController});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      GetBuilder<BannerController>(builder: (bannerController) {
        return const BannerView(isFeatured: true);
      }),

      splashController.moduleList != null
          ? splashController.moduleList!.isNotEmpty
              ? _buildStaggeredLayout(context)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                    child: Text('no_module_found'.tr),
                  ),
                )
          : ModuleShimmer(isEnabled: splashController.moduleList == null),

      GetBuilder<AddressController>(builder: (locationController) {
        List<AddressModel?> addressList = [];
        if(AuthHelper.isLoggedIn() && locationController.addressList != null) {
          addressList = [];
          bool contain = false;
          if(AddressHelper.getUserAddressFromSharedPref()!.id != null) {
            for(int index=0; index<locationController.addressList!.length; index++) {
              if(locationController.addressList![index].id == AddressHelper.getUserAddressFromSharedPref()!.id) {
                contain = true;
                break;
              }
            }
          }
          if(!contain) {
            addressList.add(AddressHelper.getUserAddressFromSharedPref());
          }
          addressList.addAll(locationController.addressList!);
        }
        return (!AuthHelper.isLoggedIn() || locationController.addressList != null) ? addressList.isNotEmpty ? Column(
          children: [

            const SizedBox(height: Dimensions.paddingSizeLarge),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
              child: TitleWidget(title: 'deliver_to'.tr),
            ),
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),

            SizedBox(
              height: 80,
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: addressList.length,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: Dimensions.paddingSizeSmall, right: Dimensions.paddingSizeSmall, top: Dimensions.paddingSizeExtraSmall),
                itemBuilder: (context, index) {
                  return Container(
                    width: 300,
                    padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                    child: AddressWidget(
                      address: addressList[index],
                      fromAddress: false,
                      onTap: () {
                        if(AddressHelper.getUserAddressFromSharedPref()!.id != addressList[index]!.id) {
                          Get.dialog(const CustomLoaderWidget(), barrierDismissible: false);
                          Get.find<LocationController>().saveAddressAndNavigate(
                            addressList[index], false, null, false, ResponsiveHelper.isDesktop(context),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ) : const SizedBox() : AddressShimmer(isEnabled: AuthHelper.isLoggedIn() && locationController.addressList == null);
      }),

      const PopularStoreView(isPopular: false, isFeatured: true),

      const SizedBox(height: 120),

    ]);
  }

  Widget _buildStaggeredLayout(BuildContext context) {
    final List<ModuleModel> modules = splashController.moduleList ?? [];
    if (modules.isEmpty) return const SizedBox();

    final List<MapEntry<int, ModuleModel>> featured = [];
    final List<MapEntry<int, ModuleModel>> primary = [];
    final List<MapEntry<int, ModuleModel>> quick = [];

    for (int i = 0; i < modules.length; i++) {
      if (i < 2) {
        featured.add(MapEntry(i, modules[i]));
      } else if (i < 5) {
        primary.add(MapEntry(i, modules[i]));
      } else {
        quick.add(MapEntry(i, modules[i]));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Dimensions.paddingSizeSmall),

          if (featured.isNotEmpty) _buildFeaturedRow(context, featured),
          if (featured.isNotEmpty) const SizedBox(height: Dimensions.paddingSizeDefault),

          if (primary.isNotEmpty) _buildPrimaryRow(context, primary),
          if (primary.isNotEmpty) const SizedBox(height: Dimensions.paddingSizeDefault),

          if (quick.isNotEmpty) _buildQuickServices(context, quick),

          const SizedBox(height: Dimensions.paddingSizeSmall),
        ],
      ),
    );
  }

  Widget _buildFeaturedRow(BuildContext context, List<MapEntry<int, ModuleModel>> items) {
    return Row(
      children: List.generate(items.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? Dimensions.paddingSizeSmall : 0),
            child: _buildFeaturedCard(context, items[i].key, items[i].value),
          ),
        );
      }),
    );
  }

  Widget _buildFeaturedCard(BuildContext context, int originalIndex, ModuleModel module) {
    final String type = (module.moduleType ?? '').toLowerCase();
    final bool isFoodOrGreen = type == AppConstants.food || type.contains('food');
    final Color waveColor = isFoodOrGreen ? const Color(0xFFA8D5A2) : const Color(0xFFB8D8B0);

    String subtitle = module.description ?? 'Quality services';
    if (type == AppConstants.food || type.contains('food')) {
      subtitle = 'Fresh meals\ndelivered';
    } else if (type == AppConstants.grocery || type.contains('grocery')) {
      subtitle = 'Daily essentials\n& more';
    }

    return _ScaleTap(
      onTap: () => splashController.switchModule(originalIndex, true),
      child: Container(
        height: 170,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _WavyBottomPainter(color: waveColor.withValues(alpha: 0.45)),
              ),
            ),
            Positioned(
              left: 14,
              top: 16,
              right: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.moduleName ?? '',
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: const Color(0xFF222222),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: const Color(0xFF555555),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                child: CustomImage(
                  image: '${module.thumbnailFullUrl ?? module.iconFullUrl ?? ''}',
                  height: 95,
                  width: 95,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryRow(BuildContext context, List<MapEntry<int, ModuleModel>> items) {
    return Row(
      children: List.generate(items.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < items.length - 1 ? Dimensions.paddingSizeSmall : 0),
            child: _buildPrimaryCard(context, items[i].key, items[i].value),
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryCard(BuildContext context, int originalIndex, ModuleModel module) {
    return _ScaleTap(
      onTap: () => splashController.switchModule(originalIndex, true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: '${module.iconFullUrl ?? ''}',
                height: 55,
                width: 55,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              module.moduleName ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickServices(BuildContext context, List<MapEntry<int, ModuleModel>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, color: Colors.white, size: 14),
              const SizedBox(width: 2),
              const Icon(Icons.home_outlined, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Quick Services',
                style: robotoMedium.copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Dimensions.paddingSizeSmall),

        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              return SizedBox(
                width: 90,
                child: _buildQuickServiceCard(context, items[index].key, items[index].value),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickServiceCard(BuildContext context, int originalIndex, ModuleModel module) {
    return _ScaleTap(
      onTap: () => splashController.switchModule(originalIndex, true),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: '${module.iconFullUrl ?? ''}',
                height: 45,
                width: 45,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              module.moduleName ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeExtraSmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _WavyBottomPainter extends CustomPainter {
  final Color color;
  _WavyBottomPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.quadraticBezierTo(
      size.width * 0.25, size.height * 0.35,
      size.width * 0.5, size.height * 0.55,
    );
    path.quadraticBezierTo(
      size.width * 0.75, size.height * 0.75,
      size.width, size.height * 0.50,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ModuleShimmer extends StatelessWidget {
  final bool isEnabled;
  const ModuleShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(2, (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 0 ? Dimensions.paddingSizeSmall : 0),
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  color: Theme.of(context).cardColor,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                ),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  enabled: isEnabled,
                  child: Container(),
                ),
              ),
            )),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Row(
            children: List.generate(3, (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 2 ? Dimensions.paddingSizeSmall : 0),
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).cardColor,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                ),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  enabled: isEnabled,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(
                      height: 45, width: 45,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                        color: Colors.grey[300],
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Container(height: 12, width: 50, color: Colors.grey[300]),
                  ]),
                ),
              ),
            )),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          Container(
            height: 32,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            children: List.generate(4, (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? Dimensions.paddingSizeSmall : 0),
                height: 95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  color: Theme.of(context).cardColor,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                ),
                child: Shimmer(
                  duration: const Duration(seconds: 2),
                  enabled: isEnabled,
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(height: 38, width: 38, decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                      color: Colors.grey[300],
                    )),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 40, color: Colors.grey[300]),
                  ]),
                ),
              ),
            )),
          ),
        ],
      ),
    );
  }
}

class AddressShimmer extends StatelessWidget {
  final bool isEnabled;
  const AddressShimmer({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: Dimensions.paddingSizeLarge),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
          child: TitleWidget(title: 'deliver_to'.tr),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),

        SizedBox(
          height: 70,
          child: ListView.builder(
            physics: const BouncingScrollPhysics(),
            itemCount: 5,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
            itemBuilder: (context, index) {
              return Container(
                width: 300,
                padding: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                child: Container(
                  padding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? Dimensions.paddingSizeDefault
                      : Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      Icons.location_on,
                      size: ResponsiveHelper.isDesktop(context) ? 50 : 40, color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Expanded(
                      child: Shimmer(
                        duration: const Duration(seconds: 2),
                        enabled: isEnabled,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(height: 15, width: 100, color: Colors.grey[300]),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                          Container(height: 10, width: 150, color: Colors.grey[300]),
                        ]),
                      ),
                    ),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _ScaleTap({required this.child, required this.onTap});

  @override
  State<_ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<_ScaleTap> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 0.93)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}