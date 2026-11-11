import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moonjoin/common/widgets/web_raster_image.dart';
import 'package:moonjoin/util/app_constants.dart';
import 'package:moonjoin/util/images.dart';
import 'package:octo_image/octo_image.dart';

class CustomImage extends StatelessWidget {
  final String image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final bool isNotification;
  final String placeholder;
  final bool isHovered;
  final Color? color;
  const CustomImage({super.key, required this.image, this.height, this.width, this.fit = BoxFit.cover, this.isNotification = false, this.placeholder = '', this.isHovered = false, this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isHovered ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: kIsWeb ? _webImage() : CachedNetworkImage(
        color: color,
        imageUrl: kIsWeb ? '${AppConstants.baseUrl}/image-proxy?url=$image' : image, height: height, width: width, fit: fit,
        placeholder: (context, url) => Image.asset(
          placeholder.isNotEmpty ? placeholder : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
          height: height, width: width, fit: fit, color: color,
        ),
        errorWidget: (context, url, error) => Image.asset(
          placeholder.isNotEmpty ? placeholder : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
          height: height, width: width, fit: fit, color: color,
        ),
      ),
    );
  }

  /// Web only. Same OctoImage, URL (/image-proxy), placeholder, error widget and
  /// fade timings CachedNetworkImage uses, but the image comes from
  /// [WebRasterImage] (raster pixels), not a browser <img>: Flutter 3.47.5
  /// CanvasKit clears an <img> (src='') on release even while it can still be
  /// drawn, which turned visible images black/placeholder after navigation.
  Widget _webImage() {
    Widget placeholderImage() => Image.asset(
      placeholder.isNotEmpty ? placeholder : (isNotification ? Images.notificationPlaceholder : Images.placeholder),
      height: height, width: width, fit: fit, color: color,
    );
    return OctoImage(
      image: WebRasterImage('${AppConstants.baseUrl}/image-proxy?url=$image'),
      placeholderBuilder: (context) => placeholderImage(),
      errorBuilder: (context, error, stackTrace) => placeholderImage(),
      // CachedNetworkImage's defaults, so web keeps the exact same fades.
      fadeOutDuration: const Duration(milliseconds: 1000),
      fadeOutCurve: Curves.easeOut,
      fadeInDuration: const Duration(milliseconds: 500),
      fadeInCurve: Curves.easeIn,
      height: height, width: width, fit: fit, color: color,
    );
  }
}
