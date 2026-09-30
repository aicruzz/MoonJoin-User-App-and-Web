import 'package:connectivity_plus/connectivity_plus.dart';

/// Connectivity decision for the Set Location (address selection) screen.
///
/// On iOS, connectivity_plus answers `checkConnectivity()` by reading the
/// current path of an NWPathMonitor it creates on demand; the monitor is thrown
/// away whenever the last `onConnectivityChanged` listener cancels (the splash
/// screen's, once Home opens). A freshly created monitor has not evaluated the
/// network yet, so the first read can report `none` on a phone that is online —
/// which sent the first address-selection open to "No internet connection".
///
/// A positive first answer is trusted immediately. A negative one is checked
/// once more after [recheckDelay], by which time the monitor has evaluated; only
/// if that second answer is also offline is the device treated as offline.
Future<bool> isOnlineForAddressSelection(
  Future<List<ConnectivityResult>> Function() checkConnectivity, {
  Duration recheckDelay = const Duration(milliseconds: 300),
}) async {
  if (_hasWifiOrMobile(await checkConnectivity())) {
    return true;
  }
  await Future<void>.delayed(recheckDelay);
  return _hasWifiOrMobile(await checkConnectivity());
}

/// Same rule the screen always used: online means Wi-Fi or mobile data.
bool _hasWifiOrMobile(List<ConnectivityResult> result) =>
    result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile);
