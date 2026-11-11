import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Selects the smallest backend image variant that is still large enough for the
/// physical size an image will occupy on screen.
///
/// The backend Media 6G pilot exposes an additive `image_variants` map on
/// `GET /api/v1/items/details/{id}`; only variants that physically exist are
/// returned, so any tier may be missing. The original URL is always the
/// fallback: when no variant can satisfy the request the caller keeps rendering
/// exactly what it renders today.
///
/// Pure selection only — this helper never rewrites URLs, never touches
/// image-proxy/web-vs-mobile handling (that stays in `CustomImage`), performs no
/// I/O and does not mutate [variants].

/// Nominal longest edge, in pixels, of each generated variant tier.
const Map<String, int> kImageVariantLongestEdge = <String, int>{
  'sm': 320,
  'md': 720,
  'lg': 1440,
};

/// Tiers ordered small → large. Selection may only step upward through this
/// list, so an image is never served smaller than the space it fills.
const List<String> _tiersAscending = <String>['sm', 'md', 'lg'];

String? pickImageUrl({
  required String? original,
  required Map<String, String>? variants,
  required double logicalWidth,
  required double logicalHeight,
  required double devicePixelRatio,
}) {
  if (original == null || original.isEmpty) {
    return original;
  }
  if (variants == null || variants.isEmpty) {
    return original;
  }

  final double targetPx = max(logicalWidth, logicalHeight) * devicePixelRatio;
  if (targetPx.isNaN || targetPx <= 0) {
    return original;
  }

  for (int i = 0; i < _tiersAscending.length; i++) {
    if (targetPx <= kImageVariantLongestEdge[_tiersAscending[i]]!) {
      /// Requested tier decided; step upward only until one actually exists.
      for (int j = i; j < _tiersAscending.length; j++) {
        final String? url = variants[_tiersAscending[j]];
        if (url != null && url.isNotEmpty) {
          return url;
        }
      }
      return original;
    }
  }

  /// Larger than the biggest generated variant (1440) — the original is the
  /// only representation big enough.
  return original;
}

/// Web Performance Slice 3. Parses one additive backend `*_variants` field
/// (`logo_variants`, `cover_photo_variants`, `image_variants`, `icon_variants`,
/// `thumbnail_variants`) with exactly the rules `Item.fromJson` applies to
/// `image_variants`: only non-empty String URLs under String keys survive, and
/// anything else — absent, null, `[]` (what the backend sends when no size
/// exists), a non-map, or a map with no usable entry — collapses to null so the
/// model's existing `*_full_url` stays the fallback.
Map<String, String>? parseImageVariants(dynamic value) {
  if (value is! Map) {
    return null;
  }
  final Map<String, String> variants = <String, String>{};
  value.forEach((key, url) {
    if (key is String && key.isNotEmpty && url is String && url.isNotEmpty) {
      variants[key] = url;
    }
  });
  return variants.isNotEmpty ? variants : null;
}

/// Web Performance Slice 3. Web-only variant selection for Store / Category /
/// Banner / Module images.
///
/// Off the web this returns [original] exactly, so mobile keeps loading the
/// same `*_full_url` it loads today. On the web it delegates to [pickImageUrl],
/// which stays the single source of truth for size selection. The chosen URL
/// is still handed to `CustomImage`, so the existing web `/image-proxy`
/// transport applies to it unchanged. [isWeb] exists only so tests can drive
/// both branches; production callers never pass it.
String? pickWebImageUrl({
  required String? original,
  required Map<String, String>? variants,
  required double logicalWidth,
  required double logicalHeight,
  required double devicePixelRatio,
  bool isWeb = kIsWeb,
}) {
  if (!isWeb) {
    return original;
  }
  return pickImageUrl(
    original: original,
    variants: variants,
    logicalWidth: logicalWidth,
    logicalHeight: logicalHeight,
    devicePixelRatio: devicePixelRatio,
  );
}
