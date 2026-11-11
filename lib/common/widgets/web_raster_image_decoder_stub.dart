import 'dart:ui' as ui;

/// Non-web stub. [WebRasterImage] is only used on the web (CustomImage keeps
/// CachedNetworkImage on mobile), so this is never reached in the apps.
Future<ui.Image> decodeUrlToRasterImage(String url) =>
    Future<ui.Image>.error(UnsupportedError('WebRasterImage is web-only'));
