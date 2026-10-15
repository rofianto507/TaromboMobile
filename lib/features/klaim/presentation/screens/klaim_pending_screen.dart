import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/klaim_provider.dart';
import '../../domain/entities/klaim_info.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/utils/confirm_logout.dart';
import '../../../../shared/widgets/app_dialog.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

class KlaimPendingScreen extends ConsumerWidget {
  const KlaimPendingScreen({super.key});

  Future<void> _batalkan(
    BuildContext context,
    WidgetRef ref,
    KlaimInfo info,
  ) async {
    final ya = await showAppConfirmDialog(
      context,
      title: info.banding ? 'Batalkan Banding?' : 'Batalkan Pengajuan?',
      message:
          'Pengajuan${info.namaDiklaim != null ? ' untuk "${info.namaDiklaim}"' : ''} '
          'akan ditarik dari antrean pengurus. Anda dapat memilih dan '
          'mengajukan kembali setelahnya.',
      icon: Icons.undo_rounded,
      confirmLabel: 'Ya, Batalkan',
      destructive: true,
    );
    if (!ya || !context.mounted) return;
    try {
      await ref
          .read(klaimNotifierProvider.notifier)
          .batalkanPengajuan(info.klaimId!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pengajuan dibatalkan.')));
      context.go('/klaim');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ServerException
                ? e.message
                : 'Gagal membatalkan. Periksa koneksi Anda.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final klaimAsync = ref.watch(klaimNotifierProvider);
    final info = klaimAsync.valueOrNull;
    final isDitolak = info?.status == KlaimStatus.ditolak;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Klaim'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: () async {
              if (await confirmLogout(context)) {
                ref.read(authNotifierProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      // Dapat digulir: saat keyboard dari dialog sebelumnya masih turun,
      // tinggi tersedia sempit dan Column tetap di tengah tanpa overflow.
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isDitolak ? Colors.red : _kGold).withValues(
                          alpha: 0.12,
                        ),
                      ),
                      child: Icon(
                        isDitolak
                            ? Icons.cancel_outlined
                            : Icons.hourglass_top_rounded,
                        size: 44,
                        color: isDitolak ? Colors.red.shade700 : _kGold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isDitolak
                          ? (info?.banding == true
                                ? 'Banding Ditolak'
                                : 'Klaim Ditolak')
                          : (info?.banding == true
                                ? 'Banding Sedang Diperiksa'
                                : 'Menunggu Verifikasi Pengurus'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kGreen1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isDitolak
                          ? (info?.alasanTolak?.isNotEmpty == true
                                ? info!.alasanTolak!
                                : 'Klaim Anda ditolak pengurus. Silakan ajukan ulang dengan data yang benar.')
                          : info?.banding == true
                          ? 'Banding Anda${info?.namaDiklaim != null ? ' atas "${info!.namaDiklaim}"' : ''} sedang diperiksa pengurus. '
                                'Bila disetujui, tautan akun lama dicabut dan nama tersebut otomatis terhubung ke akun Anda. '
                                'Anda akan menerima notifikasi hasilnya.'
                          : 'Klaim identitas Anda${info?.namaDiklaim != null ? ' sebagai "${info!.namaDiklaim}"' : ''} sedang ditinjau oleh pengurus. '
                                'Anda akan bisa mengakses fitur lain setelah klaim disetujui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (isDitolak)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: _kGreen1,
                        ),
                        onPressed: () => context.go('/klaim'),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Ajukan Ulang'),
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () => ref.invalidate(klaimNotifierProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Muat Ulang Status'),
                      ),
                    if (!isDitolak && info?.klaimId != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                        ),
                        onPressed: () => _batalkan(context, ref, info!),
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Batalkan Pengajuan'),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        ref
                                .read(klaimReminderDismissedProvider.notifier)
                                .state =
                            true;
                        context.go('/home');
                      },
                      child: const Text('Lewati untuk sekarang'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
