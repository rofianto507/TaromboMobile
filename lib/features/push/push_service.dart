import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/router/app_router.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../klaim/presentation/providers/klaim_provider.dart';
import '../notifikasi/notifikasi_nav.dart';
import '../notifikasi/presentation/providers/notifikasi_provider.dart';

const _kGreen1 = Color(0xFF2E5339);

/// Harus top-level/static (dipanggil Android di isolate terpisah saat app
/// di-kill, bukan di dalam widget tree) — hanya perlu init Firebase supaya
/// SDK tidak crash; sistem Android sendiri yang menampilkan notifikasinya
/// dari payload `notification` kiriman FCM, tidak perlu kode tambahan di sini.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

final pushServiceProvider = Provider<PushService>((ref) => PushService(ref));

/// Push notification (FCM): registrasi token ke backend, tampilkan notifikasi
/// lokal saat app di foreground (FCM TIDAK otomatis menampilkan system
/// notification kalau app sedang dibuka), dan navigasi saat notifikasi
/// di-tap. Backend (`tarombo.push_sender`) lihat `context.md` bagian 10.
class PushService {
  final Ref ref;
  final _local = FlutterLocalNotificationsPlugin();
  String? _tokenTerdaftar;
  bool _siap = false;

  PushService(this.ref);

  static const _channel = AndroidNotificationChannel(
    'tarombo_default',
    'Notifikasi Tarombo',
    description: 'Pemberitahuan status klaim identitas & usulan.',
    importance: Importance.high,
  );

  Future<void> init() async {
    if (_siap) return;
    _siap = true;

    // Firebase & background handler sudah didaftarkan duluan di main() —
    // di sini cuma guard kalau PushService ternyata dipanggil sebelum itu.
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }

    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final path = response.payload;
        if (path != null) _navigasiKe(path);
      },
    );

    FirebaseMessaging.onMessage.listen(_tampilkanNotifikasiLokal);
    FirebaseMessaging.onMessageOpenedApp.listen(_tanganiTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _tanganiTap(initial);
  }

  /// Minta izin notifikasi (Android 13+/iOS wajib runtime permission) lalu
  /// daftarkan token FCM device ini ke akun yang sedang login. Dipanggil
  /// setiap kali login sukses & setiap app start selagi sudah login (token
  /// FCM bisa rotate kapan saja, bukan cuma sekali seumur install).
  Future<void> daftarkanToken() async {
    await init();
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _kirimTokenKeBackend(token);

    FirebaseMessaging.instance.onTokenRefresh.listen(_kirimTokenKeBackend);
  }

  Future<void> _kirimTokenKeBackend(String token) async {
    if (_tokenTerdaftar == token) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.callKw(
        model: 'tarombo.push_token',
        method: 'register_token',
        args: [token],
        kwargs: {'platform': Platform.isIOS ? 'ios' : 'android'},
      );
      _tokenTerdaftar = token;
    } catch (_) {
      // Best-effort — gagal daftar token tidak boleh mengganggu alur login.
    }
  }

  /// Dipanggil saat logout, SEBELUM sesi/cookie dibuang — device ini
  /// berhenti menerima push untuk akun yang baru logout.
  Future<void> lupakanToken() async {
    final token = _tokenTerdaftar;
    if (token == null) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.callKw(model: 'tarombo.push_token', method: 'unregister_token', args: [token]);
    } catch (_) {
      // Best-effort.
    }
    _tokenTerdaftar = null;
  }

  Future<void> _tampilkanNotifikasiLokal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;
    // Pesan ini juga berarti ada baris baru di tarombo.notifikasi (backend
    // selalu buat record inbox bareng pengiriman push, lihat kirim()) —
    // refresh badge supaya langsung kelihatan tanpa nunggu buka tab Notifikasi.
    ref.invalidate(notifikasiUnreadCountProvider);
    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id, _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          color: _kGreen1,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: pathUntukTipeNotifikasi(message.data['tipe'] as String?),
    );
  }

  void _tanganiTap(RemoteMessage message) => _navigasiKe(pathUntukTipeNotifikasi(message.data['tipe'] as String?));

  void _navigasiKe(String path) {
    if (path.startsWith('/home')) {
      // Status klaim bisa berubah (disetujui/ditolak) — invalidate supaya
      // redirect router mengarahkan ke layar yang benar, sama seperti saat
      // app di-resume dari background (lihat main.dart).
      ref.invalidate(klaimNotifierProvider);
      ref.invalidate(authNotifierProvider);
      ref.read(appRouterProvider).go('/home');
      return;
    }
    ref.read(appRouterProvider).push(path);
  }
}
