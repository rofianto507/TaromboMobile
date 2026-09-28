import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/klaim_provider.dart';
import '../../domain/entities/klaim_info.dart';
import '../../../../shared/utils/confirm_logout.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class KlaimPendingScreen extends ConsumerWidget {
  const KlaimPendingScreen({super.key});

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
      body: Center(
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
                  color: (isDitolak ? Colors.red : _kGold).withValues(alpha: 0.12),
                ),
                child: Icon(
                  isDitolak ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                  size: 44,
                  color: isDitolak ? Colors.red.shade700 : _kGold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isDitolak ? 'Klaim Ditolak' : 'Menunggu Verifikasi Pengurus',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kGreen1),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                isDitolak
                    ? (info?.alasanTolak?.isNotEmpty == true
                        ? info!.alasanTolak!
                        : 'Klaim Anda ditolak pengurus. Silakan ajukan ulang dengan data yang benar.')
                    : 'Klaim identitas Anda sedang ditinjau oleh pengurus. '
                        'Anda akan bisa mengakses fitur lain setelah klaim disetujui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 32),
              if (isDitolak)
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _kGreen1),
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  ref.read(klaimReminderDismissedProvider.notifier).state = true;
                  context.go('/home');
                },
                child: const Text('Lewati untuk sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
