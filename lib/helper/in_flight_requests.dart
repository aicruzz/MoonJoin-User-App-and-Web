/// Lets concurrent callers share ONE in-flight network request instead of each
/// sending an identical copy.
///
/// Home and AllStoreScreen both load the same storefront lists in the same
/// frame; without this, each list went to the backend twice. The guard only
/// covers the time a request is actually running: once it completes — success
/// or failure — the entry is dropped, so the next call (including an explicit
/// reload) always reaches the network again. There is no TTL and no caching.
///
/// Requests are identified by [keyFor]: the URI plus the effective request
/// headers. Module, zone, language and auth all travel in those headers, so a
/// Food request can never satisfy a Grocery one, nor a request made before a
/// zone or language change satisfy one made after it.
class InFlightRequests {
  final Map<String, Future<Object?>> _pending = <String, Future<Object?>>{};

  /// Returns the running request for [key] if there is one, otherwise starts
  /// [request] and shares it until it completes.
  Future<T> run<T>(String key, Future<T> Function() request) {
    final Future<Object?>? existing = _pending[key];
    if (existing != null) {
      return existing as Future<T>;
    }
    final Future<T> future = request();
    _pending[key] = future;
    // Release on completion either way. The error is left for the callers; this
    // listener only clears the slot, so it must not surface it a second time.
    future.then<void>((_) => _release(key, future), onError: (Object _) => _release(key, future));
    return future;
  }

  /// Whether a request for [key] is currently running.
  bool isInFlight(String key) => _pending.containsKey(key);

  void _release(String key, Future<Object?> future) {
    if (identical(_pending[key], future)) {
      _pending.remove(key);
    }
  }

  /// Identity of a GET: the URI plus the headers it is sent with, in a stable
  /// order so equal header maps always produce the same key.
  static String keyFor(String uri, Map<String, String>? headers) {
    final List<String> entries = (headers ?? const <String, String>{})
        .entries.map((e) => '${e.key}=${e.value}').toList()..sort();
    return '$uri|${entries.join('&')}';
  }
}
