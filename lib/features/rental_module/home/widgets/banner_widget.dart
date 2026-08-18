import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:moonjoin/common/widgets/custom_image.dart';
import 'package:moonjoin/common/widgets/custom_ink_well.dart';
import 'package:moonjoin/common/widgets/custom_snackbar.dart';
import 'package:moonjoin/features/rental_module/home/controllers/taxi_home_controller.dart';
import 'package:moonjoin/features/rental_module/home/domain/models/taxi_banner_model.dart';
import 'package:moonjoin/features/rental_module/provider_adapter/rental_apartment_adapter.dart';
import 'package:moonjoin/features/rental_module/vendor/screens/vendor_detail_screen.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BannerWidget extends StatefulWidget {
  /// Additive section scope (default `all` → prior behaviour everywhere).
  /// The Main Rental Home keeps `all`; each dedicated listing passes its own
  /// section so only that section's REAL banners render (adapter-classified —
  /// see RentalApartmentAdapter.filterBanners; queue item 18).
  final RentalSection section;
  const BannerWidget({super.key, this.section = RentalSection.all});

  @override
  State<BannerWidget> createState() => _BannerWidgetState();
}

class _BannerWidgetState extends State<BannerWidget> {
  int _currentCarouselIndex = 0;

  @override
  Widget build(BuildContext context) {

    return GetBuilder<TaxiHomeController>(
      builder: (taxiHomeController) {
        final List<Banners> banners = RentalApartmentAdapter.filterBanners(
          taxiHomeController.taxiBannerModel?.banners,
          section: widget.section,
          loadedInventory: taxiHomeController.topRatedCarsModel?.vehicles,
          aptCategoryId: RentalApartmentAdapter.apartmentCategoryId(taxiHomeController.vehicleCategoryModel),
        );
        return taxiHomeController.taxiBannerModel != null ? banners.isNotEmpty ? Padding(
          padding: const EdgeInsets.only(top: Dimensions.paddingSizeLarge),
          child: Column(children: [
            CarouselSlider.builder(
              options: CarouselOptions(
                autoPlay: true,
                enlargeCenterPage: true,
                disableCenter: true,
                viewportFraction: 0.95,
                aspectRatio: 16/6,
                autoPlayInterval: const Duration(seconds: 7),
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
              itemCount: banners.length,
              itemBuilder: (context, index, _) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(Dimensions.radiusLarge)),
                  child: CustomInkWell(
                    onTap: () async {
                      if(banners[index].type == 'default') {
                        String url = banners[index].link ?? '';
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(url, mode: LaunchMode.externalApplication);
                        } else {
                          showCustomSnackBar('unable_to_found_url'.tr);
                        }
                      } else {
                        Get.to(()=> VendorDetailScreen(vendorId: banners[index].providerId));
                      }
                    },
                    radius: Dimensions.radiusLarge,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                      child: CustomImage(image: banners[index].imageFullUrl??'', fit: BoxFit.cover, width: double.infinity),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),

            Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _currentCarouselIndex,
                count: banners.length,
                effect: ExpandingDotsEffect(
                  dotHeight: 6, dotWidth: 6, activeDotColor: Theme.of(context).primaryColor,
                  dotColor: Theme.of(context).disabledColor, spacing: 5,
                ),
              ),
            ),

          ]),
        ) : const SizedBox() : Shimmer(
          duration: const Duration(seconds: 2),
          enabled: taxiHomeController.taxiBannerModel?.banners == null,
          child: Container(margin: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
            color: Colors.grey[300],
          )),
        );
      }
    );
  }
}

