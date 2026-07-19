import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/helper/address_helper.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Premium embedded **Store location map card** (new MoonJoin feature, shared by
/// every storefront module's Store page — Food/Grocery/Pharmacy/E-commerce).
///
/// It is a *location-awareness* map, NOT live navigation: it shows the store, the
/// user's saved location, and the distance between them, and the customer can
/// drag/zoom/explore. "View on Map" expands the SAME card in place (no new
/// screen); floating actions offer Re-center, My Location, a one-shot Directions
/// **preview** (route polyline + distance/ETA, no tracking) and Open in Google
/// Maps. Reuses the existing store lat/lng, the existing Google Maps integration,
/// the existing `direction-api` / `distance-api` endpoints (via [ApiClient]) and
/// the saved user address — no new backend, no duplicated map/location service.
class StoreMapView extends StatefulWidget {
  final Store store;
  const StoreMapView({super.key, required this.store});

  @override
  State<StoreMapView> createState() => _StoreMapViewState();
}

class _StoreMapViewState extends State<StoreMapView> {
  static const double _collapsedHeight = 150;
  static const double _expandedHeight = 380;

  GoogleMapController? _mapController;
  bool _expanded = false;
  bool _routeLoading = false;
  bool _routeShown = false;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  LatLng? _storePos;
  LatLng? _userPos;
  String? _distanceText; // straight-line, shown on the collapsed card
  String? _routeDistanceText; // road distance from the directions preview
  String? _routeEtaText;

  @override
  void initState() {
    super.initState();
    _storePos = _latLng(widget.store.latitude, widget.store.longitude);
    final address = AddressHelper.getUserAddressFromSharedPref();
    _userPos = _latLng(address?.latitude, address?.longitude);
    _buildBaseMarkers();
    _computeStraightLineDistance();
  }

  LatLng? _latLng(String? lat, String? lng) {
    final double? la = double.tryParse(lat ?? '');
    final double? ln = double.tryParse(lng ?? '');
    if (la == null || ln == null) return null;
    return LatLng(la, ln);
  }

  void _buildBaseMarkers() {
    _markers.clear();
    if (_storePos != null) {
      _markers.add(Marker(
        markerId: const MarkerId('store'),
        position: _storePos!,
        infoWindow: InfoWindow(title: widget.store.name ?? ''),
      ));
    }
    if (_userPos != null) {
      _markers.add(Marker(
        markerId: const MarkerId('user'),
        position: _userPos!,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: InfoWindow(title: 'your_location'.tr),
      ));
    }
  }

  void _computeStraightLineDistance() {
    if (_storePos == null || _userPos == null) return;
    final double km = Geolocator.distanceBetween(
          _userPos!.latitude, _userPos!.longitude, _storePos!.latitude, _storePos!.longitude,
        ) /
        1000;
    _distanceText = km >= 1 ? '${km.toStringAsFixed(1)} km' : '${(km * 1000).toStringAsFixed(0)} m';
  }

  String _areaName() {
    final String addr = widget.store.address ?? '';
    if (addr.isEmpty) return widget.store.name ?? 'store'.tr;
    // Pick a meaningful locality token (e.g. "Ogbomoso"/"Oyo State") from the
    // address — skip the country and any purely-numeric postal-code tokens.
    final parts = addr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    for (final token in parts.reversed) {
      // Normalise (drop trailing punctuation/digits) before matching.
      final String norm = token.toLowerCase().replaceAll(RegExp(r'[^a-z ]'), '').trim();
      final bool isNumeric = RegExp(r'^[0-9]+$').hasMatch(token);
      final bool isCountry = norm == 'nigeria' || norm.isEmpty;
      if (!isNumeric && !isCountry) return token.replaceAll(RegExp(r'[.,]+$'), '').trim();
    }
    return widget.store.name ?? 'store'.tr;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _recenterStore() {
    if (_storePos != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_storePos!, 15));
    }
  }

  Future<void> _goToMyLocation() async {
    LatLng? target = _userPos;
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      target = LatLng(pos.latitude, pos.longitude);
      _userPos = target;
      _buildBaseMarkers();
      _computeStraightLineDistance();
      if (mounted) setState(() {});
    } catch (_) {
      // Permission denied / unavailable → fall back to the saved address.
    }
    if (target != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
    }
  }

  Future<void> _showDirectionsPreview() async {
    if (_storePos == null || _userPos == null || _routeLoading) return;
    final Color routeColor = Theme.of(context).primaryColor; // capture before the async gap
    setState(() => _routeLoading = true);
    try {
      final Response response = await Get.find<ApiClient>().getData(
        '${AppConstants.directionUri}?origin_lat=${_userPos!.latitude}&origin_lng=${_userPos!.longitude}'
        '&destination_lat=${_storePos!.latitude}&destination_lng=${_storePos!.longitude}',
      );
      if (response.statusCode == 200 && response.body['routes'] != null && (response.body['routes'] as List).isNotEmpty) {
        final route = response.body['routes'][0];
        final List<LatLng> points = _decodePolyline(route['polyline']['encodedPolyline']);
        if (points.isNotEmpty) {
          _polylines
            ..clear()
            ..add(Polyline(
              polylineId: const PolylineId('store_route'),
              points: points,
              color: routeColor,
              width: 5,
            ));
          _routeShown = true;
          _fitBounds([_userPos!, _storePos!]);
        }
        // Road distance + ETA from the same response when present.
        final int? meters = (route['distanceMeters'] as num?)?.toInt();
        if (meters != null) {
          final double km = meters / 1000;
          _routeDistanceText = km >= 1 ? '${km.toStringAsFixed(1)} km' : '$meters m';
        }
        final String? dur = route['duration']?.toString();
        if (dur != null) {
          final double secs = double.tryParse(dur.replaceAll('s', '')) ?? 0;
          if (secs > 0) _routeEtaText = _formatEta(secs);
        }
      }
    } catch (_) {
      // Preview is best-effort — never break the map.
    }
    if (mounted) setState(() => _routeLoading = false);
  }

  Future<void> _openInGoogleMaps() async {
    if (_storePos == null) return;
    final String url = 'https://www.google.com/maps/dir/?api=1&destination=${_storePos!.latitude},${_storePos!.longitude}';
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url, mode: LaunchMode.externalApplication);
    }
  }

  String _formatEta(double seconds) {
    final int mins = (seconds / 60).round();
    if (mins < 60) return '$mins ${'min'.tr}';
    final int h = mins ~/ 60;
    final int m = mins % 60;
    return m == 0 ? '$h ${'hour'.tr}' : '$h ${'hour'.tr} $m ${'min'.tr}';
  }

  void _fitBounds(List<LatLng> pts) {
    if (_mapController == null || pts.isEmpty) return;
    double south = pts.first.latitude, north = pts.first.latitude, west = pts.first.longitude, east = pts.first.longitude;
    for (final p in pts) {
      south = math.min(south, p.latitude);
      north = math.max(north, p.latitude);
      west = math.min(west, p.longitude);
      east = math.max(east, p.longitude);
    }
    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(
      LatLngBounds(southwest: LatLng(south, west), northeast: LatLng(north, east)),
      60,
    ));
  }

  // Standard Google encoded-polyline decoder.
  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = [];
    int index = 0, len = encoded.length, lat = 0, lng = 0;
    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // No coordinates → hide the card entirely (backend-honest).
    if (_storePos == null) return const SizedBox();
    final Color primary = Theme.of(context).primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: _expanded ? _expandedHeight : _collapsedHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: _expanded ? _expandedView(context, primary) : _collapsedView(context, primary),
      ),
    );
  }

  // ── Collapsed: "Explore {area}" + View on Map + small map preview ───────────
  Widget _collapsedView(BuildContext context, Color primary) {
    return Row(children: [
      Expanded(
        flex: 5,
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${'explore'.tr} ${_areaName()}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
            const SizedBox(height: 3),
            Text(
              _distanceText != null ? '${_distanceText!} ${'away'.tr}' : (widget.store.address ?? ''),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white),
                  const SizedBox(width: 5),
                  Text('view_on_map'.tr, style: robotoBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: Colors.white)),
                ]),
              ),
            ),
          ]),
        ),
      ),
      Expanded(
        flex: 6,
        child: Stack(fit: StackFit.expand, children: [
          _map(interactive: false),
          // Tap the preview to expand too.
          Positioned.fill(child: Material(color: Colors.transparent, child: InkWell(onTap: () => setState(() => _expanded = true)))),
        ]),
      ),
    ]);
  }

  // ── Expanded: full interactive map + floating actions ───────────────────────
  Widget _expandedView(BuildContext context, Color primary) {
    return Stack(children: [
      _map(interactive: true),

      // Collapse handle (top-left)
      Positioned(
        top: Dimensions.paddingSizeSmall, left: Dimensions.paddingSizeSmall,
        child: _circleAction(Icons.close_fullscreen_rounded, () => setState(() => _expanded = false)),
      ),

      // Distance / ETA chip (top-center) when a preview has been drawn
      if (_routeShown && (_routeDistanceText != null || _routeEtaText != null))
        Positioned(
          top: Dimensions.paddingSizeSmall, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: 6),
              decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge)),
              child: Text(
                [?_routeDistanceText, ?_routeEtaText].join('  •  '),
                style: robotoBold.copyWith(color: Colors.white, fontSize: Dimensions.fontSizeSmall),
              ),
            ),
          ),
        ),

      // Right-side floating actions
      Positioned(
        right: Dimensions.paddingSizeSmall, top: 0, bottom: 0,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
          _circleAction(Icons.store_mall_directory_outlined, _recenterStore, tooltip: 'recenter'.tr),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _circleAction(Icons.my_location, _goToMyLocation, tooltip: 'my_location'.tr),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _circleAction(_routeLoading ? null : Icons.alt_route, _routeLoading ? null : _showDirectionsPreview,
              tooltip: 'directions_preview'.tr, loading: _routeLoading),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          _circleAction(Icons.open_in_new, _openInGoogleMaps, tooltip: 'open_in_google_maps'.tr),
        ]),
      ),
    ]);
  }

  Widget _map({required bool interactive}) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: _storePos!, zoom: 15),
      markers: _markers,
      polylines: _polylines,
      onMapCreated: (c) => _mapController = c,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      liteModeEnabled: !interactive && defaultTargetPlatform == TargetPlatform.android,
      zoomGesturesEnabled: interactive,
      scrollGesturesEnabled: interactive,
      rotateGesturesEnabled: interactive,
      tiltGesturesEnabled: false,
      // Let the map claim drag/zoom gestures so it works inside the scrolling page.
      gestureRecognizers: interactive
          ? <Factory<OneSequenceGestureRecognizer>>{Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer())}
          : const <Factory<OneSequenceGestureRecognizer>>{},
    );
  }

  Widget _circleAction(IconData? icon, VoidCallback? onTap, {String? tooltip, bool loading = false}) {
    final Color primary = Theme.of(context).primaryColor;
    final Widget btn = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 42, width: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: loading
            ? Padding(padding: const EdgeInsets.all(11), child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(primary)))
            : Icon(icon, size: 20, color: primary),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }
}
