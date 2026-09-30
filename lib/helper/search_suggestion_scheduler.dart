import 'package:moonjoin/common/widgets/custom_debounce_widget.dart';

/// Decides WHEN the live autocomplete request is sent and WHICH answer may be
/// shown. It owns no UI and no network code: the screen supplies [fetch] (the
/// existing SearchController.getSearchSuggestions) and renders what it is given.
///
/// Rules:
/// - Typing is never restricted; only the suggestion request is gated.
/// - Below [minLength] characters nothing is requested, any pending request is
///   dropped and [onClear] is called so stale suggestions disappear.
/// - At or above it, the request waits until typing settles ([debounceMs]).
/// - An unchanged query is not re-requested, but an empty or failed answer
///   releases it, so a retry is always possible.
/// - Every sent request gets a generation number; only the newest request, for
///   the text still in the field, may deliver. package:http cannot cancel an
///   in-flight call, so a late answer is discarded instead of applied.
class SearchSuggestionScheduler {
  SearchSuggestionScheduler({
    required this.fetch,
    required this.currentText,
    required this.onResult,
    required this.onClear,
    this.minLength = 3,
    int debounceMs = 300,
  }) : _debounce = CustomDebounceWidget(milliseconds: debounceMs);

  final Future<List<String>> Function(String query) fetch;

  /// The text currently in the search field, read when the timer fires and
  /// when an answer arrives.
  final String Function() currentText;

  final void Function(List<String> suggestions) onResult;
  final void Function() onClear;
  final int minLength;

  final CustomDebounceWidget _debounce;
  String? _lastRequestedQuery;
  int _generation = 0;
  bool _disposed = false;

  /// Called by every search field on this screen whenever its text changes.
  ///
  /// The raw text is used, exactly as before Slice B: trimming would change
  /// which query is sent, which is search semantics, not performance.
  void onTextChanged(String text) {
    if (_disposed) {
      return;
    }
    if (text.length < minLength) {
      _reset();
      onClear();
      return;
    }
    _debounce.run(() => _send(text));
  }

  /// Stops any pending request and ignores any answer still in flight.
  void dispose() {
    _disposed = true;
    _reset();
  }

  void _reset() {
    _debounce.cancel();
    _lastRequestedQuery = null;
    _generation++;
  }

  Future<void> _send(String query) async {
    // The field may have been cleared or edited programmatically (clear icon,
    // voice) after the timer was armed, which does not report a text change.
    if (_disposed || query != currentText()) {
      return;
    }
    if (query == _lastRequestedQuery) {
      return;
    }
    _lastRequestedQuery = query;
    final int generation = ++_generation;

    List<String> suggestions;
    try {
      suggestions = await fetch(query);
    } catch (_) {
      if (generation == _generation) {
        _lastRequestedQuery = null;
      }
      return;
    }

    if (_disposed || generation != _generation) {
      // A newer request (or a reset) owns the screen now.
      return;
    }
    if (query != currentText()) {
      // Still the newest request, but the field moved on without a newer one
      // being sent yet. Release the query so returning to it asks again.
      _lastRequestedQuery = null;
      return;
    }
    // An empty answer is either "no matches" or a failed call — the existing
    // controller reports both as an empty list — so allow a retry either way.
    if (suggestions.isEmpty) {
      _lastRequestedQuery = null;
    }
    onResult(suggestions);
  }
}
