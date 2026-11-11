// Web image regression (Flutter 3.47.5 CanvasKit): an image that is still drawn
// after every Dart reference to it was released must keep its pixels.
//
// Run with:  flutter test --platform chrome test/media/web_raster_image_browser_test.dart
//
// Mechanism under test: CanvasKit draws `<img>`-backed images as lazy textures
// from the element and clears the element (src = '') when the image's ref count
// reaches zero. A recorded picture can still draw that image afterwards, and it
// then uploads an empty texture (seen on iPhone Safari as black images after
// Home → Store → Home). WebRasterImage produces raster images instead.
@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui_web' as ui_web;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moonjoin/common/widgets/web_raster_image.dart';
import 'package:moonjoin/common/widgets/web_raster_image_decoder_web.dart';

const ui.Color kRed = ui.Color(0xFFFF0000);
const ui.Color kHalfBlue = ui.Color(0x800000FF);

/// 4x4 PNG: left half opaque red, right half 50% blue (exercises premultiply).
Future<String> _pngDataUrl() async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  canvas.drawRect(const ui.Rect.fromLTWH(0, 0, 2, 4), ui.Paint()..color = kRed);
  canvas.drawRect(const ui.Rect.fromLTWH(2, 0, 2, 4), ui.Paint()..color = kHalfBlue);
  final ui.Image image = await recorder.endRecording().toImage(4, 4);
  final ByteData png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  image.dispose();
  return 'data:image/png;base64,${base64Encode(png.buffer.asUint8List())}';
}

/// Records a picture drawing [image], releases [image] (ref count → 0), then
/// rasterizes the picture: the exact order of events on Store → Home.
Future<Uint8List> _drawAfterRelease(ui.Image image) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImage(image, ui.Offset.zero, ui.Paint());
  final ui.Picture picture = recorder.endRecording();
  image.dispose();
  final ui.Image out = await picture.toImage(4, 4);
  final ByteData bytes = (await out.toByteData(format: ui.ImageByteFormat.rawStraightRgba))!;
  out.dispose();
  picture.dispose();
  return bytes.buffer.asUint8List();
}

void _expectRedAndHalfBlue(Uint8List px) {
  // pixel (0,0) → opaque red
  expect(px.sublist(0, 4), <int>[255, 0, 0, 255]);
  // pixel (3,0) → 50% blue (allow rounding)
  final List<int> blue = px.sublist(12, 16);
  expect(blue[0], lessThanOrEqualTo(2));
  expect(blue[1], lessThanOrEqualTo(2));
  expect(blue[2], greaterThanOrEqualTo(250));
  expect(blue[3], inInclusiveRange(126, 130));
}

/// Drops every reference the image cache and stream completers hold, so the
/// only remaining reference is the caller's clone.
void _releaseCache() {
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}

Future<ui.Image> _resolve(ImageProvider provider) async {
  final ImageStream stream = provider.resolve(ImageConfiguration.empty);
  final Future<ui.Image> image = () async {
    final ImageInfo info = await _firstImage(stream);
    final ui.Image clone = info.image.clone();
    info.dispose();
    return clone;
  }();
  return image;
}

Future<ImageInfo> _firstImage(ImageStream stream) {
  final Completer<ImageInfo> done = Completer<ImageInfo>();
  late final ImageStreamListener listener;
  listener = ImageStreamListener((ImageInfo info, bool _) {
    stream.removeListener(listener);
    done.complete(info);
  }, onError: (Object e, StackTrace? st) {
    stream.removeListener(listener);
    done.completeError(e, st);
  });
  stream.addListener(listener);
  return done.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('WebRasterImage decode: drawn after release keeps its pixels', () async {
    // Same decode WebRasterImage uses; the caller holds the only reference, so
    // _drawAfterRelease drops the ref count to zero exactly like the control.
    final String url = await _pngDataUrl();
    final ui.Image image = await decodeUrlToRasterImage(url);
    _expectRedAndHalfBlue(await _drawAfterRelease(image));
  });

  test('WebRasterImage: load → release/evict → same URL again stays renderable', () async {
    final String url = await _pngDataUrl();
    final WebRasterImage provider = WebRasterImage(url);

    final ui.Image first = await _resolve(provider);
    expect(PaintingBinding.instance.imageCache.evict(provider), isTrue);
    _releaseCache();
    _expectRedAndHalfBlue(await _drawAfterRelease(first));

    final ui.Image second = await _resolve(provider); // same URL, fresh load
    _releaseCache();
    _expectRedAndHalfBlue(await _drawAfterRelease(second));
  });

  test('control: <img>-backed engine path loses its pixels after release (the defect avoided)', () async {
    final String url = await _pngDataUrl();
    final ui.Codec codec = await ui_web.createImageCodecFromUrl(Uri.parse(url));
    final ui.Image image = (await codec.getNextFrame()).image;
    codec.dispose();
    final Uint8List px = await _drawAfterRelease(image);
    // Documents the Flutter 3.47.5 behaviour this fix works around: the first
    // pixel is no longer opaque red. If a future Flutter fixes the engine this
    // control fails, which is the signal to re-evaluate WebRasterImage.
    expect(px.sublist(0, 4), isNot(<int>[255, 0, 0, 255]));
  });
}
