import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/klaim/presentation/providers/klaim_provider.dart';
import 'features/notifikasi/presentation/providers/notifikasi_provider.dart';
import 'features/push/push_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  // Didaftarkan di sini (sebelum runApp), bukan ditunda sampai login — supaya
  // notifikasi yang masuk selagi app benar-benar ter-kill tertangani sejak
  // proses baru hidup, bukan baru aktif setelah user sempat buka app.
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const ProviderScope(child: TaromboApp()));
}

class TaromboApp extends ConsumerStatefulWidget {
  const TaromboApp({super.key});

  @override
  ConsumerState<TaromboApp> createState() => _TaromboAppState();
}

class _TaromboAppState extends ConsumerState<TaromboApp> with WidgetsBindingObserver {
  // Dipakai untuk membedakan "benar-benar sempat dikirim ke background lalu
  // kembali" dari sekadar "inactive" sesaat (overlay screenshot MIUI, tarik
  // notification shade, dialog izin sistem, dll). Android/MIUI mengirim
  // resumed→inactive→resumed untuk kasus sesaat itu TANPA pernah singgah di
  // paused — hanya benar-benar pindah app/kunci layar yang singgah di
  // paused. Tanpa penanda ini, ambil screenshot saja memicu refresh (splash
  // berkedip) setiap kali.
  bool _sempatPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _sempatPaused = true;
      return;
    }
    if (state != AppLifecycleState.resumed || !_sempatPaused) return;
    _sempatPaused = false;

    // Login Google (native account picker) JUGA memicu paused→resumed yang
    // persis sama seperti balik dari background biasa — bedanya di sini app
    // baru resume di TENGAH proses login yang belum selesai (authNotifier
    // masih AsyncLoading, sedang menunggu respons /tarombo/mobile/google_login).
    // Invalidate di momen ini akan membuang notifier yang sedang berjalan itu
    // sebelum sempat menyimpan hasil loginnya ke state yang di-watch UI —
    // login tetap SUKSES di server & tersimpan di storage (makanya buka ulang
    // app langsung masuk), tapi UI nyangkut di layar login karena notifier
    // penggantinya sudah keburu baca sesi lama (masih kosong). Jadi: lewati
    // invalidate selagi ada proses auth yang sedang berjalan.
    if (ref.read(authNotifierProvider).isLoading) return;

    // Status klaim (dan sesi login) bisa berubah di luar aplikasi — mis.
    // pengurus menyetujui lewat web sementara HP anggota tertidur di
    // background. Cek ulang begitu aplikasi aktif lagi, supaya anggota
    // tidak terjebak di layar "Klaim Identitas"/"Menunggu Verifikasi" yang
    // sudah usang tanpa harus force-close aplikasi secara manual.
    ref.invalidate(klaimNotifierProvider);
    ref.invalidate(authNotifierProvider);
    // Push notification bisa saja masuk selagi app di background — badge
    // lonceng harus ikut ter-refresh begitu app aktif lagi, bukan cuma
    // ketika ada pesan foreground.
    ref.invalidate(notifikasiUnreadCountProvider);
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Tarombo',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: const Locale('id'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id'), Locale('en')],
    );
  }
}
