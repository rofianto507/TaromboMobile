import 'package:flutter/foundation.dart';

class SessionExpiredNotifier extends ChangeNotifier {
  bool _hasExpired = false;
  bool get hasExpired => _hasExpired;

  void expire() {
    if (_hasExpired) return;
    _hasExpired = true;
    notifyListeners();
  }

  void reset() {
    _hasExpired = false;
  }
}
