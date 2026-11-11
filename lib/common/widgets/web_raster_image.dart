import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:moonjoin/common/widgets/web_raster_image_decoder_stub.dart'
    if (dart.library.js_interop) 'package:moonjoin/common/widgets/web_raster_image_decoder_web.dart';

/// Web image provider that yields a **raster** `ui.Image` (pixels owned by
/// CanvasKit) instead of one backed by a browser `<img>` element.
///
/// Why: on Flutter 3.47.5 CanvasKit (no WebCodecs ImageDecoder, e.g. iOS
/// Safari) every network/byte image is decoded through an `<img>` and drawn as
/// a lazy texture from it. When the image's reference count reaches zero the
/// engine clears that element (`img.src = ''`), yet the image can still be
/// drawn, so it re-uploads as black/placeholder. A raster image has no external
/// source to clear. Proven on a physical iPhone 15 Plus (Safari, iOS 18.6).
///
/// Load path: fetch(url) → createImageBitmap → OffscreenCanvas pixels →
/// `ui.decodeImageFromPixels`. Same URL, same HTTP cache, full resolution.
@immutable
class WebRasterImage extends ImageProvider<WebRasterImage> {
  const WebRasterImage(this.url, {this.scale = 1.0});

  final String url;
  final double scale;

  @override
  Future<WebRasterImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture<WebRasterImage>(this);

  @override
  ImageStreamCompleter loadImage(WebRasterImage key, ImageDecoderCallback decode) {
    return OneFrameImageStreamCompleter(
      _load(key),
      informationCollector: () => <DiagnosticsNode>[DiagnosticsProperty<ImageProvider>('Image provider', this)],
    );
  }

  Future<ImageInfo> _load(WebRasterImage key) async {
    try {
      return ImageInfo(image: await decodeUrlToRasterImage(key.url), scale: key.scale);
    } catch (_) {
      // Like NetworkImage: drop the failed entry so a later request retries.
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(key));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) => other is WebRasterImage && other.url == url && other.scale == scale;

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() => '${objectRuntimeType(this, 'WebRasterImage')}("$url", scale: $scale)';
}
