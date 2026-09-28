import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Ikon lonceng notifikasi — dipakai di AppBar tiap tab utama (Beranda,
/// Tarombo, Akun) supaya konsisten di semua tab, bukan cuma satu halaman.
class NotifikasiButton extends StatelessWidget {
  const NotifikasiButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.notifications_none_rounded),
      tooltip: 'Notifikasi',
      onPressed: () => context.push('/notifikasi'),
    );
  }
}
