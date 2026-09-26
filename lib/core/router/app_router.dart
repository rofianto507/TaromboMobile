import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/registration/presentation/screens/registration_screen.dart';
import '../../features/klaim/presentation/providers/klaim_provider.dart';
import '../../features/klaim/domain/entities/klaim_info.dart';
import '../../features/klaim/presentation/screens/klaim_search_screen.dart';
import '../../features/klaim/presentation/screens/klaim_new_person_screen.dart';
import '../../features/klaim/presentation/screens/klaim_pending_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/profile/presentation/screens/profile_search_screen.dart';
import '../../features/profile/presentation/screens/profile_detail_screen.dart';
import '../../features/partuturan/presentation/screens/partuturan_screen.dart';
import '../../features/usulan/presentation/screens/usulan_list_screen.dart';
import '../../features/usulan/presentation/screens/usulan_form_screen.dart';
import '../../features/direktori_keahlian/presentation/screens/direktori_keahlian_screen.dart';
import '../../features/nearby_map/presentation/screens/nearby_map_screen.dart';
import '../../features/arsip/presentation/screens/arsip_list_screen.dart';
import '../../features/arsip/presentation/screens/arsip_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../network/session_expired_notifier.dart';

final _splashTimerProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(milliseconds: 1200));
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);

  ref.listen(authNotifierProvider, (_, _) => notifier.signal());
  ref.listen(klaimNotifierProvider, (_, _) => notifier.signal());
  ref.listen(_splashTimerProvider, (_, _) => notifier.signal());

  // Auto-logout saat Odoo session expired (server restart, timeout, dll.).
  // Flag sengaja dibiarkan menyala sampai login berikutnya berhasil — lihat
  // penjelasan yang sama di DigitalKamtibmasMobile.
  ref.listen<SessionExpiredNotifier>(sessionExpiredProvider, (_, expired) {
    if (!expired.hasExpired) return;
    ref.read(authNotifierProvider.notifier).logout();
  });

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onAuthScreen = loc == '/login' || loc == '/register';
      final splashDone = ref.read(_splashTimerProvider).hasValue;

      // /splash HANYA untuk boot pertama aplikasi (menunggu authNotifier
      // selesai baca sesi tersimpan) — BUKAN untuk setiap kali auth/klaim
      // provider di-refresh, mis. saat app kembali dari background (lihat
      // main.dart: didChangeAppLifecycleState). Sebelum ini diperbaiki,
      // setiap resume melempar pengguna ke /splash lalu (setelah refresh
      // selesai) logika di bawah menghitung ulang tujuan dari nol — hampir
      // selalu jatuh ke /home — walau tadinya sedang membuka halaman lain
      // sama sekali (mis. detail Arsip) yang activity-nya belum di-destroy.
      // Begitu splashDone sekali, redirect ini TIDAK PERNAH memaksa pindah
      // halaman lagi hanya karena provider sedang loading — cukup `return
      // null` (tetap di halaman yang sama) sambil menunggu hasil refresh;
      // pindah halaman hanya terjadi kalau hasilnya benar-benar mengharuskan
      // (sesi habis, klaim ditolak, dst.), dievaluasi setelah loading selesai.
      if (!splashDone) {
        return loc == '/splash' ? null : '/splash';
      }

      final authAsync = ref.read(authNotifierProvider);
      if (authAsync.isLoading) return null;

      final user = authAsync.valueOrNull;
      final isLoggedIn = user != null;

      if (!isLoggedIn) {
        return onAuthScreen ? null : '/login';
      }

      final klaimAsync = ref.read(klaimNotifierProvider);
      if (klaimAsync.isLoading) return null;

      final status = klaimAsync.valueOrNull?.status ?? KlaimStatus.belum;
      final isKlaimRoute = loc.startsWith('/klaim');

      switch (status) {
        case KlaimStatus.belum:
          return isKlaimRoute ? null : '/klaim';
        case KlaimStatus.menunggu:
        case KlaimStatus.ditolak:
          if (loc == '/klaim/pending') return null;
          if (status == KlaimStatus.ditolak && loc == '/klaim') return null;
          return '/klaim/pending';
        case KlaimStatus.disetujui:
          if (isKlaimRoute || loc == '/login' || loc == '/register' || loc == '/splash') {
            return '/home';
          }
          return null;
      }
    },
    routes: [
      GoRoute(path: '/splash', name: 'splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', name: 'register', builder: (_, _) => const RegistrationScreen()),
      GoRoute(path: '/klaim', name: 'klaim', builder: (_, _) => const KlaimSearchScreen()),
      GoRoute(path: '/klaim/orang-baru', name: 'klaimOrangBaru', builder: (_, _) => const KlaimOrangBaruScreen()),
      GoRoute(path: '/klaim/pending', name: 'klaimPending', builder: (_, _) => const KlaimPendingScreen()),
      GoRoute(path: '/home', name: 'home', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/profil', name: 'profil', builder: (_, _) => const ProfileSearchScreen()),
      GoRoute(
        path: '/profil/:id',
        name: 'profilDetail',
        builder: (_, state) => ProfileDetailScreen(orangId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(path: '/partuturan', name: 'partuturan', builder: (_, _) => const PartuturanScreen()),
      GoRoute(path: '/usulan', name: 'usulan', builder: (_, _) => const UsulanListScreen()),
      GoRoute(path: '/usulan/baru', name: 'usulanBaru', builder: (_, _) => const UsulanFormScreen()),
      GoRoute(path: '/direktori-keahlian', name: 'direktoriKeahlian', builder: (_, _) => const DirektoriKeahlianScreen()),
      GoRoute(path: '/peta-kerabat', name: 'petaKerabat', builder: (_, _) => const NearbyMapScreen()),
      GoRoute(path: '/arsip', name: 'arsip', builder: (_, _) => const ArsipListScreen()),
      GoRoute(
        path: '/arsip/:id',
        name: 'arsipDetail',
        builder: (_, state) => ArsipDetailScreen(arsipId: int.parse(state.pathParameters['id']!)),
      ),
    ],
  );
});

/// ChangeNotifier tipis: dipakai sebagai [GoRouter.refreshListenable].
/// GoRouter akan re-evaluasi [redirect] setiap kali [signal] dipanggil.
class _RouterRefreshNotifier extends ChangeNotifier {
  void signal() => notifyListeners();
}
