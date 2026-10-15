import 'dart:async';
import 'package:flutter/foundation.dart';

/// Menunda aksi sampai pengguna berhenti mengetik sejenak, supaya pencarian
/// tidak dikirim di setiap huruf.
class Debouncer {
  final Duration jeda;
  Timer? _timer;

  Debouncer(this.jeda);

  void run(VoidCallback aksi) {
    _timer?.cancel();
    _timer = Timer(jeda, aksi);
  }

  void cancel() => _timer?.cancel();

  void dispose() => _timer?.cancel();
}
