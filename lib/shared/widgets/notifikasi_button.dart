import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/notifikasi/presentation/providers/notifikasi_provider.dart';

/// Ikon lonceng notifikasi — dipakai di AppBar tiap tab utama (Beranda,
/// Tarombo, Akun) supaya konsisten di semua tab, bukan cuma satu halaman.
class NotifikasiButton extends ConsumerWidget {
  const NotifikasiButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(notifikasiUnreadCountProvider).valueOrNull ?? 0;
    return IconButton(
      icon: Badge.count(
        count: unread,
        isLabelVisible: unread > 0,
        child: const Icon(Icons.notifications_none_rounded),
      ),
      tooltip: 'Notifikasi',
      onPressed: () async {
        await context.push('/notifikasi');
        ref.invalidate(notifikasiUnreadCountProvider);
      },
    );
  }
}
