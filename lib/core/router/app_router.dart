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
import '../../features/shell/presentation/screens/main_shell_screen.dart';
import '../../features/tarombo_tree/presentation/screens/tarombo_tree_screen.dart';
import '../../features/account/presentation/screens/account_screen.dart';
import '../../features/notifikasi/presentation/screens/notifikasi_screen.dart';
import '../../features/profile/presentation/screens/profile_search_screen.dart';
import '../../features/profile/presentation/screens/profile_detail_screen.dart';
import '../../features/partuturan/presentation/screens/partuturan_screen.dart';
import '../../features/usulan/presentation/screens/usulan_list_screen.dart';
import '../../features/usulan/presentation/screens/usulan_form_screen.dart';
import '../../features/direktori_keahlian/presentation/screens/direktori_keahlian_screen.dart';
import '../../features/nearby_map/presentation/screens/nearby_map_screen.dart';
import '../../features/arsip/presentation/screens/arsip_list_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../network/session_expired_notifier.dart';

final _splashTimerProvider = FutureProvider<void>((ref) async {
  await Future.delayed(const Duration(milliseconds: 1200));
});

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterRefreshNotifier();
  ref.onDispose(notifier.dispose);

  ref.listen(authNotifierProvider, (_, _) => notifier.signal());
  ref.listen(klaimNotifierProvider, (_, _) => notifier.signal());
  ref.listen(klaimReminderDismissedProvider, (_, _) => notifier.signal());
  ref.listen(_splashTimerProvider, (_, _) => notifier.signal());

  // Auto-logout saat Odoo session expired (server restart, timeout, dll.).
  // Flag sengaja dibiarkan menyala sampai login berikutnya berhasil — lihat
  // penjelasan yang sama di DigitalKamtibmasMobile.
  ref.listen<SessionExpiredNotifier>(sessionExpiredProvider, (_, expired) {
    if (!expired.hasExpired) return;
    ref.read(authNotifierProvider.notifier).logout();
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
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

      if (status == KlaimStatus.disetujui) {
        if (isKlaimRoute ||
            loc == '/login' ||
            loc == '/register' ||
            loc == '/splash') {
          return '/home';
        }
        return null;
      }

      // Belum tertaut ke data anggota mana pun (belum/menunggu/ditolak).
      // Sebelumnya akun begini dikunci total ke layar klaim. Sekarang form
      // klaim cukup ditampilkan SEKALI per sesi aplikasi (ditandai lewat
      // klaimReminderDismissedProvider, yang reset ke false setiap app
      // dibuka ulang dari awal — lihat komentar di provider itu) dan boleh
      // di-skip; setelah di-skip, pengguna bebas ke menu lain. Usulan
      // (mengubah data bersama) sengaja DIKECUALIKAN dari pelonggaran ini —
      // tetap dikunci sampai identitas benar-benar terverifikasi pengurus.
      final isUsulanRoute = loc.startsWith('/usulan');
      final reminderTarget = status == KlaimStatus.belum
          ? '/klaim'
          : '/klaim/pending';

      if (isUsulanRoute) {
        return isKlaimRoute ? null : reminderTarget;
      }

      final reminderDismissed = ref.read(klaimReminderDismissedProvider);
      if (!reminderDismissed && !isKlaimRoute) {
        return reminderTarget;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (_, _) => const RegistrationScreen(),
      ),
      GoRoute(
        path: '/klaim',
        name: 'klaim',
        builder: (_, _) => const KlaimSearchScreen(),
      ),
      GoRoute(
        path: '/klaim/orang-baru',
        name: 'klaimOrangBaru',
        builder: (_, _) => const KlaimOrangBaruScreen(),
      ),
      GoRoute(
        path: '/klaim/pending',
        name: 'klaimPending',
        builder: (_, _) => const KlaimPendingScreen(),
      ),

      // 3 tab utama (Beranda - Tarombo - Akun), tiap tab punya stack navigasi
      // sendiri lewat StatefulShellRoute.indexedStack — pindah tab TIDAK
      // reset posisi/state tab lain (beda dari sekadar push/pop GoRoute biasa).
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShellScreen(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tarombo',
                name: 'taromboTree',
                builder: (_, _) => const TaromboTreeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/akun',
                name: 'akun',
                builder: (_, _) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),

      // Rute detail — sengaja parentNavigatorKey: root navigator, supaya
      // dibuka FULL-SCREEN menutupi bottom bar (bukan menumpuk di dalam
      // stack salah satu tab), konsisten dengan gaya "tap menu -> halaman
      // penuh dengan tombol back" yang sudah ada sebelum bottom nav ini.
      GoRoute(
        path: '/notifikasi',
        name: 'notifikasi',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const NotifikasiScreen(),
      ),
      GoRoute(
        path: '/profil',
        name: 'profil',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ProfileSearchScreen(),
      ),
      GoRoute(
        path: '/profil/:id',
        name: 'profilDetail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => ProfileDetailScreen(
          orangId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/partuturan',
        name: 'partuturan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const PartuturanScreen(),
      ),
      GoRoute(
        path: '/usulan',
        name: 'usulan',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const UsulanListScreen(),
      ),
      GoRoute(
        path: '/usulan/baru',
        name: 'usulanBaru',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return UsulanFormScreen(
            initialTargetId: extra?['targetId'] as int?,
            initialTargetName: extra?['targetName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/direktori-keahlian',
        name: 'direktoriKeahlian',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const DirektoriKeahlianScreen(),
      ),
      GoRoute(
        path: '/peta-kerabat',
        name: 'petaKerabat',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const NearbyMapScreen(),
      ),
      GoRoute(
        path: '/arsip',
        name: 'arsip',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ArsipListScreen(),
      ),
    ],
  );
});

/// ChangeNotifier tipis: dipakai sebagai [GoRouter.refreshListenable].
/// GoRouter akan re-evaluasi [redirect] setiap kali [signal] dipanggil.
class _RouterRefreshNotifier extends ChangeNotifier {
  void signal() => notifyListeners();
}
