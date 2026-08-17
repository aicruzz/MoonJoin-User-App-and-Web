import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/home/domain/models/advertisement_model.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/screens/store_screen.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:video_player/video_player.dart';

/// MoonJoin Advertisement ("Highlights") card — a premium promotional BANNER
/// (ui-designs/advert_reference.PNG + text_display.PNG): the video/image is the
/// full card surface, with the store branding + title + description + Order Now
/// button overlaid directly on it over a soft dark scrim. No separate white
/// information sheet.
///
/// PRESENTATION ONLY. Data comes from the existing `AdvertisementModel`; store
/// navigation, the `video_player` mechanism, muted controls-free autoplay and the
/// loop/advance behaviour are all unchanged. The whole banner is tappable → the
/// same StoreScreen the Order Now button opens.
class MoonjoinAdvertisementCard extends StatelessWidget {
  final AdvertisementModel advertisement;
  /// When a video finishes and it is NOT looping, advance the carousel.
  final VoidCallback? onVideoComplete;
  /// Loop the video (single-advertisement case) instead of advancing.
  final bool loop;
  const MoonjoinAdvertisementCard({super.key, required this.advertisement, this.onVideoComplete, this.loop = false});

  @override
  Widget build(BuildContext context) {
    return advertisement.addType == 'video_promotion'
        ? _AdVideoBanner(advertisement: advertisement, onComplete: onVideoComplete, loop: loop)
        : _AdImageBanner(advertisement: advertisement);
  }
}

// ── Shared helpers ──

void _openStore(int? storeId) {
  Get.toNamed(
    RouteHelper.getStoreRoute(id: storeId, page: 'store'),
    arguments: StoreScreen(store: Store(id: storeId), fromModule: false),
  );
}

/// Best-effort store name from data ALREADY loaded on the home (no new API, no
/// model change). Returns null when the store isn't in a loaded list, in which
/// case the banner shows the store logo alone — never a hardcoded name.
String? _resolveStoreName(int? storeId) {
  if (storeId == null || !Get.isRegistered<StoreController>()) return null;
  final StoreController sc = Get.find<StoreController>();
  for (final List<Store>? list in [
    sc.popularStoreList, sc.latestStoreList, sc.topOfferStoreList,
    sc.featuredStoreList, sc.recommendedStoreList, sc.visitAgainStoreList,
  ]) {
    if (list == null) continue;
    for (final Store s in list) {
      if (s.id == storeId && (s.name?.isNotEmpty ?? false)) return s.name;
    }
  }
  return null;
}

/// The banner frame shared by image + video ads: media fills the card, a dark
/// scrim keeps the overlay legible, and the store/title/description/Order Now sit
/// directly on top. Tapping anywhere opens the store.
///
/// [showLogo] reflects the Advertisement Type: Store Promotion has a profile
/// image and shows the logo; Video Promotion has NO profile image, so the logo
/// (and its space) is not rendered at all — only the store name as text.
Widget _bannerFrame({required BuildContext context, required AdvertisementModel ad, required Widget media, required bool showLogo}) {
  final Color green = Theme.of(context).primaryColor;
  final String? storeName = _resolveStoreName(ad.storeId);
  final List<Widget> branding = [];
  if (showLogo) {
    branding.add(Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)),
      child: ClipOval(child: CustomImage(image: ad.profileImageFullUrl ?? '', height: 28, width: 28, fit: BoxFit.cover)),
    ));
  }
  if (storeName != null) {
    if (branding.isNotEmpty) branding.add(const SizedBox(width: Dimensions.paddingSizeSmall));
    branding.add(Flexible(child: Text(storeName, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall))));
  }
  return GestureDetector(
    onTap: () => _openStore(ad.storeId),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
      child: Stack(fit: StackFit.expand, children: [

        // Live advertisement media (image or video).
        media,

        // Dark scrim — darker at the bottom-left (where the text sits), clear at
        // the top-right so the food/media still reads.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomLeft, end: Alignment.topRight,
              colors: [Colors.black.withValues(alpha: 0.74), Colors.black.withValues(alpha: 0.34), Colors.transparent],
              stops: const [0.0, 0.45, 0.82],
            ),
          ),
        ),

        // Overlay content.
        Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Store branding: logo (Store Promotion only) + dynamic name as text.
            // Video Promotion renders no avatar and reserves no space for it.
            if (branding.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: branding),

            const Spacer(),

            // Promotional headline + description.
            if ((ad.title ?? '').isNotEmpty)
              Text(ad.title!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeExtraLarge)),
            if ((ad.description ?? '').isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(ad.description!, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: robotoRegular.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: Dimensions.fontSizeSmall)),
            ],
            const SizedBox(height: Dimensions.paddingSizeSmall),

            // Order Now → opens the same store (navigation unchanged).
            InkWell(
              onTap: () => _openStore(ad.storeId),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: green, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('order_now'.tr, style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall)),
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                ]),
              ),
            ),
          ]),
        ),
      ]),
    ),
  );
}

class _AdImageBanner extends StatelessWidget {
  final AdvertisementModel advertisement;
  const _AdImageBanner({required this.advertisement});

  @override
  Widget build(BuildContext context) {
    return _bannerFrame(
      context: context,
      ad: advertisement,
      showLogo: true, // Store Promotion → profile image shown.
      media: CustomImage(image: advertisement.coverImageFullUrl ?? '', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
    );
  }
}

class _AdVideoBanner extends StatefulWidget {
  final AdvertisementModel advertisement;
  final VoidCallback? onComplete;
  final bool loop;
  const _AdVideoBanner({required this.advertisement, this.onComplete, this.loop = false});

  @override
  State<_AdVideoBanner> createState() => _AdVideoBannerState();
}

class _AdVideoBannerState extends State<_AdVideoBanner> {
  VideoPlayerController? _controller;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    final VideoPlayerController controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.advertisement.videoAttachmentFullUrl ?? ''),
    );
    _controller = controller;
    controller.addListener(_onTick);
    try {
      await controller.initialize();
    } catch (_) {
      return; // Leave the loading state; never crash on a bad URL (existing behaviour).
    }
    if (!mounted) {
      controller.dispose();
      return;
    }
    await controller.setVolume(0);
    await controller.setLooping(widget.loop);
    await controller.play();
    setState(() {});
  }

  void _onTick() {
    final VideoPlayerController? c = _controller;
    if (c == null || !mounted || widget.loop) return;
    if (c.value.isInitialized && c.value.duration > Duration.zero && c.value.position >= c.value.duration) {
      if (!_completed) {
        _completed = true;
        widget.onComplete?.call();
      }
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? c = _controller;
    final bool ready = c != null && c.value.isInitialized;
    // Raw VideoPlayer only → NO controls/chrome. Cover-fitted so it fills the
    // banner without distortion; a black base shows while it initialises.
    final Widget media = Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: ready
          ? FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: c.value.size.width <= 0 ? 16 : c.value.size.width,
                height: c.value.size.height <= 0 ? 9 : c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          : const SizedBox.shrink(),
    );
    // Video Promotion → NO profile image/logo.
    return _bannerFrame(context: context, ad: widget.advertisement, media: media, showLogo: false);
  }
}
