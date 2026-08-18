import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:moonjoin/common/widgets/moonjoin/moonjoin_advertisement_card.dart';
import 'package:moonjoin/features/home/controllers/advertisement_controller.dart';
import 'package:moonjoin/features/home/domain/models/advertisement_model.dart';
import 'package:moonjoin/util/dimensions.dart';
import 'package:moonjoin/util/styles.dart';

/// MoonJoin Advertisement ("Highlights") section — the approved MoonJoin design
/// language applied to the existing advertisement carousel: organic pale-green
/// module, premium header, premium ad cards (image + video), pagination dots.
///
/// PRESENTATION ONLY. It consumes the existing `AdvertisementController` (data,
/// `currentIndex`, `autoPlay`, `autoPlayDuration`) and preserves the existing
/// carousel semantics exactly — 7s auto-play, infinite scroll when >1, and the
/// video-aware pause/resume (auto-play pauses while a video ad is shown and
/// resumes when it ends). No fetch is triggered here: the home lifecycle already
/// loads the list, so there is no duplicate API request. Self-hides when empty.
class MoonjoinAdvertisementSection extends StatefulWidget {
  const MoonjoinAdvertisementSection({super.key});

  @override
  State<MoonjoinAdvertisementSection> createState() => _MoonjoinAdvertisementSectionState();
}

class _MoonjoinAdvertisementSectionState extends State<MoonjoinAdvertisementSection> {
  final CarouselSliderController _carouselController = CarouselSliderController();
  // Compact wide promotional banner (responsive: height = width / ratio), so the
  // green section wraps it tightly — no tall white sheet under the media.
  static const double _bannerAspectRatio = 1.8;

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return GetBuilder<AdvertisementController>(builder: (advertisementController) {
      final List<AdvertisementModel>? ads = advertisementController.advertisementList;
      if (ads == null) return const _AdSectionShimmer();
      if (ads.isEmpty) return const SizedBox();

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
        child: Stack(children: [

          // Organic pale-green background (amoeba lives on the green only; cards stay clean).
          Positioned.fill(
            child: ClipPath(
              clipper: _AdOrganicClipper(),
              child: Container(color: green.withValues(alpha: 0.08)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 26, Dimensions.paddingSizeDefault, 20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [

              _header(context, green),
              const SizedBox(height: Dimensions.paddingSizeDefault),

              CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: ads.length,
                options: CarouselOptions(
                  aspectRatio: _bannerAspectRatio,
                  viewportFraction: 1,
                  disableCenter: true,
                  enlargeCenterPage: false,
                  enableInfiniteScroll: ads.length > 1,
                  autoPlay: advertisementController.autoPlay,
                  autoPlayInterval: advertisementController.autoPlayDuration,
                  onPageChanged: (index, reason) {
                    advertisementController.setCurrentIndex(index, false);
                    // Pause the timed auto-play while a video ad is shown (the video
                    // advances the carousel itself on completion); keep it on for images.
                    advertisementController.updateAutoPlayStatus(
                      status: ads[index].addType != 'video_promotion', shouldUpdate: true,
                    );
                  },
                ),
                itemBuilder: (context, index, realIndex) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeExtraSmall),
                  child: MoonjoinAdvertisementCard(
                    advertisement: ads[index],
                    // Single ad → loop; multiple → advance to the next ad when the video ends.
                    loop: ads.length == 1,
                    onVideoComplete: () => _carouselController.nextPage(
                      duration: const Duration(milliseconds: 500), curve: Curves.easeInOut,
                    ),
                  ),
                ),
              ),

              if (ads.length > 1) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                _pagination(green, advertisementController.currentIndex, ads.length),
              ],
            ]),
          ),
        ]),
      );
    });
  }

  Widget _header(BuildContext context, Color green) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        height: 40, width: 40, alignment: Alignment.center,
        decoration: BoxDecoration(color: green, shape: BoxShape.circle),
        child: const Icon(Icons.campaign, color: Colors.white, size: 24),
      ),
      const SizedBox(width: Dimensions.paddingSizeSmall),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('highlights_for_you'.tr, maxLines: 1, overflow: TextOverflow.ellipsis, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
          Text('see_our_most_popular_store_and_item'.tr, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: Theme.of(context).disabledColor)),
        ]),
      ),
    ]);
  }

  Widget _pagination(Color green, int current, int count) {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(count, (i) {
      final bool active = i == current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 7, width: active ? 22 : 7,
        decoration: BoxDecoration(
          color: active ? green : green.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
      );
    }));
  }
}

/// Organic wavy background — same premium silhouette language as the rest of the
/// MoonJoin promotion sections, kept self-contained here so the frozen Flash
/// Deals component is not touched.
class _AdOrganicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final double w = size.width, h = size.height;
    const double r = 28, topWave = 16, botWave = 14;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..cubicTo(w * 0.30, 0, w * 0.34, topWave, w * 0.5, topWave)
      ..cubicTo(w * 0.66, topWave, w * 0.70, 0, w - r, 0)
      ..quadraticBezierTo(w, 0, w, r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..cubicTo(w * 0.70, h, w * 0.66, h - botWave, w * 0.5, h - botWave)
      ..cubicTo(w * 0.34, h - botWave, w * 0.30, h, r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Premium MoonJoin loading state.
class _AdSectionShimmer extends StatelessWidget {
  const _AdSectionShimmer();

  @override
  Widget build(BuildContext context) {
    final Color green = Theme.of(context).primaryColor;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall, vertical: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault, 26, Dimensions.paddingSizeDefault, 20),
      decoration: BoxDecoration(color: green.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
      child: Shimmer(
        duration: const Duration(seconds: 2),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(height: 40, width: 40, decoration: BoxDecoration(color: Colors.grey[300], shape: BoxShape.circle)),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(height: 14, width: 140, color: Colors.grey[300]),
              const SizedBox(height: 6),
              Container(height: 10, width: 200, color: Colors.grey[300]),
            ]),
          ]),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          AspectRatio(
            aspectRatio: 1.8,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
            ),
          ),
        ]),
      ),
    );
  }
}
