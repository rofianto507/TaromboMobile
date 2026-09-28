import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kGreen1 = Color(0xFF2E5339);

/// Scaffold bersama untuk 3 tab utama (Beranda - Tarombo - Akun), dibangun
/// dari StatefulShellRoute.indexedStack di app_router.dart supaya tiap tab
/// punya stack navigasi sendiri (pindah tab tidak reset posisi scroll/state
/// tab lain). Rute detail (profil, usulan, arsip, dst.) sengaja didaftarkan
/// dengan parentNavigatorKey ke root navigator (lihat app_router.dart) supaya
/// terbuka full-screen MENUTUPI bottom bar ini, bukan di dalam salah satu tab.
class MainShellScreen extends StatelessWidget {
  final StatefulNavigationShell shell;
  const MainShellScreen({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        indicatorColor: _kGreen1.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: _kGreen1),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree_rounded, color: _kGreen1),
            label: 'Tarombo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: _kGreen1),
            label: 'Akun',
          ),
        ],
      ),
    );
  }
}
