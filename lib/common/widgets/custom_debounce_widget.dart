import 'dart:async';
import 'package:flutter/material.dart';

class CustomDebounceWidget{

  final int milliseconds;
  Timer? _timer;
  CustomDebounceWidget({required this.milliseconds});
  void run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Drops a pending action without running it.
  ///
  /// Needed wherever a debounced callback must not outlive its screen, or where
  /// the input stops qualifying before the timer fires. Safe to call when
  /// nothing is pending.
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

}