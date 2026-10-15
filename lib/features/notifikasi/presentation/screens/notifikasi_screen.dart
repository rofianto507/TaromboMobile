import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../domain/entities/notifikasi_item.dart';
import '../../notifikasi_nav.dart';
import '../providers/notifikasi_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

class NotifikasiScreen extends ConsumerWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(notifikasiListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded),
            tooltip: 'Tandai semua dibaca',
            onPressed: () =>
                ref.read(notifikasiServiceProvider).tandaiSemuaDibaca(),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Gagal memuat notifikasi.\n$e',
            textAlign: TextAlign.center,
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 64,
                      color: _kGreen1.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Belum ada notifikasi',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notifikasiListProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _NotifikasiTile(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

class _NotifikasiTile extends ConsumerWidget {
  final NotifikasiItem item;
  const _NotifikasiTile({required this.item});

  // Dibedakan lewat 'hasil' di payload data (dikirim backend sejak
  // tarombo_usulan.py/tarombo_klaim_akun.py), bukan menebak dari teks judul
  // — notifikasi lama sebelum field ini ada otomatis fallback ke ikon netral.
  (IconData, Color) get _tampilan {
    // Berita & agenda baru: ikon sesuai jenisnya, bukan ikon status klaim.
    if (item.tipe == 'berita') {
      return item.data['jenis'] == 'agenda'
          ? (Icons.event_rounded, _kGold)
          : (Icons.newspaper_rounded, _kGreen1);
    }
    switch (item.data['hasil']) {
      case 'disetujui':
        return (Icons.check_circle_rounded, Colors.green);
      case 'ditolak':
        return (Icons.cancel_rounded, Colors.red);
      default:
        return (Icons.notifications_rounded, _kGreen1);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, warna) = _tampilan;
    return ListTile(
      tileColor: item.dibaca ? null : _kGold.withValues(alpha: 0.08),
      leading: CircleAvatar(
        backgroundColor: warna.withValues(alpha: 0.1),
        child: Icon(icon, color: warna),
      ),
      title: Text(
        item.judul,
        style: TextStyle(
          fontWeight: item.dibaca ? FontWeight.normal : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.isi != null) Text(item.isi!),
          if (item.tanggal != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(item.tanggal!),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ),
        ],
      ),
      isThreeLine: item.isi != null,
      onTap: () async {
        if (!item.dibaca) {
          await ref
              .read(apiClientProvider)
              .callKw(
                model: 'tarombo.notifikasi',
                method: 'tandai_dibaca',
                args: [
                  [item.id],
                ],
              );
          ref.invalidate(notifikasiListProvider);
          ref.invalidate(notifikasiUnreadCountProvider);
        }
        if (!context.mounted) return;
        final path = pathUntukTipeNotifikasi(item.tipe, item.data);
        if (path == '/home') {
          ref.invalidate(klaimNotifierProvider);
          ref.invalidate(authNotifierProvider);
          context.go('/home');
        } else if (path != '/notifikasi') {
          context.push(path);
        }
      },
    );
  }
}
