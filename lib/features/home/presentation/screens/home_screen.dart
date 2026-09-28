import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/domain/entities/klaim_info.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../../../shared/widgets/notifikasi_button.dart';
import '../../../../shared/widgets/orang_avatar.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final klaimInfo = ref.watch(klaimNotifierProvider).valueOrNull;
    final orang = klaimInfo?.orang;
    final isVerified = klaimInfo?.status == KlaimStatus.disetujui;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarombo'),
        actions: const [NotifikasiButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Material(
            color: _kGreen1,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: orang == null ? null : () => context.push('/profil/${orang.id}'),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    orang != null
                        ? OrangAvatar(orangId: orang.id, jenisKelamin: 'L', radius: 28)
                        : CircleAvatar(
                            radius: 28,
                            backgroundColor: _kGold.withValues(alpha: 0.2),
                            child: const Icon(Icons.person_rounded, color: Colors.white, size: 30),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang,',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            orang?.name ?? user?.name ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          if (orang != null)
                            Text('Sundut ke-${orang.sundut} • Lihat profil saya', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                        ],
                      ),
                    ),
                    if (orang != null) const Icon(Icons.chevron_right, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 16),
            Material(
              color: _kGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => context.push('/klaim'),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: _kGreen1),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Identitas Anda belum tertaut ke data anggota. Tap untuk klaim sekarang.',
                          style: TextStyle(color: _kGreen1, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: _kGreen1),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Menu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _kGreen1)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _MenuTile(icon: Icons.family_restroom_rounded, label: 'Profil Keluarga', onTap: () => context.push('/profil')),
              _MenuTile(icon: Icons.calculate_outlined, label: 'Hitung Partuturan', onTap: () => context.push('/partuturan')),
              _MenuTile(
                icon: Icons.edit_note_rounded,
                label: 'Usulan',
                locked: !isVerified,
                onTap: isVerified
                    ? () => context.push('/usulan')
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Klaim identitas Anda dulu sebelum bisa mengajukan usulan.')),
                        ),
              ),
              _MenuTile(icon: Icons.school_outlined, label: 'Direktori Keahlian', onTap: () => context.push('/direktori-keahlian')),
              _MenuTile(icon: Icons.map_outlined, label: 'Kerabat Terdekat', onTap: () => context.push('/peta-kerabat')),
              _MenuTile(icon: Icons.photo_library_outlined, label: 'Arsip', onTap: () => context.push('/arsip')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool locked;
  const _MenuTile({required this.icon, required this.label, this.onTap, this.locked = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 32, color: locked ? Colors.grey.shade400 : _kGreen1),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: locked ? Colors.grey.shade500 : null),
                    ),
                  ],
                ),
                if (locked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(Icons.lock_rounded, size: 14, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
