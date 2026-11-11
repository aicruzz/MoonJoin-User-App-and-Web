import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:web/web.dart' as web;

/// Fetches [url] and returns a raster `ui.Image` whose pixels live in CanvasKit
/// (via `ui.decodeImageFromPixels`), so no browser `<img>`/bitmap backs it.
Future<ui.Image> decodeUrlToRasterImage(String url) async {
  final web.Response response = await web.window.fetch(url.toJS).toDart;
  if (!response.ok) {
    throw Exception('HTTP ${response.status} loading $url');
  }
  final web.Blob blob = await response.blob().toDart;
  // Browser decode (off the main thread), then read the pixels back once.
  final web.ImageBitmap bitmap = await web.window.createImageBitmap(blob).toDart;
  final int width = bitmap.width;
  final int height = bitmap.height;
  final Uint8List pixels;
  try {
    final web.OffscreenCanvas canvas = web.OffscreenCanvas(width, height);
    final web.OffscreenCanvasRenderingContext2D context =
        canvas.getContext('2d')! as web.OffscreenCanvasRenderingContext2D;
    context.drawImage(bitmap, 0, 0);
    final Uint8ClampedList data = context.getImageData(0, 0, width, height).data.toDart;
    pixels = Uint8List.view(data.buffer, data.offsetInBytes, data.lengthInBytes);
    canvas.width = 0; // let the browser reclaim the canvas backing store
    canvas.height = 0;
  } finally {
    bitmap.close();
  }
  _premultiply(pixels);
  final Completer<ui.Image> completer = Completer<ui.Image>();
  ui.decodeImageFromPixels(pixels, width, height, ui.PixelFormat.rgba8888, completer.complete);
  return completer.future;
}

/// getImageData() is straight (un-premultiplied) RGBA; decodeImageFromPixels
/// expects premultiplied alpha. Opaque pixels are left untouched.
void _premultiply(Uint8List p) {
  for (int i = 3; i < p.length; i += 4) {
    final int a = p[i];
    if (a == 255) continue;
    p[i - 3] = (p[i - 3] * a + 127) ~/ 255;
    p[i - 2] = (p[i - 2] * a + 127) ~/ 255;
    p[i - 1] = (p[i - 1] * a + 127) ~/ 255;
  }
}
