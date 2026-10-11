import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../klaim/domain/entities/klaim_info.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../../profil_saya/presentation/providers/profil_saya_provider.dart';
import '../../../profil_saya/presentation/widgets/kelengkapan_profil_card.dart';
import '../../../../shared/widgets/notifikasi_button.dart';
import '../../../../shared/widgets/orang_avatar.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

// Seberapa jauh grid menu "naik" menimpa bagian bawah header hijau — sengaja
// sampai separuh tinggi tile baris atas (Profil Keluarga/Hitung Partuturan),
// bukan cuma sliver tipis di tepi.
const _kOverlapTinggi = 105.0;

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final klaimInfo = ref.watch(klaimNotifierProvider).valueOrNull;
    final orang = klaimInfo?.orang;
    final isVerified = klaimInfo?.status == KlaimStatus.disetujui;
    // Kartu kelengkapan hanya untuk akun yang sudah tertaut dan belum 100%.
    final kelengkapan = ref.watch(profilSayaProvider).valueOrNull?.kelengkapan;

    return Scaffold(
      body: Stack(
        children: [
          // Background Danau Toba — dipatok di dasar layar (tepat di atas
          // bottom bar), bukan ikut scroll bareng konten. Di-tint hijau
          // (BlendMode.color, selaras palet app, bukan foto full-color
          // berdiri sendiri) dan tepi atasnya di-fade (ShaderMask) supaya
          // meluruh halus ke background, bukan terpotong kotak.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white],
                stops: [0.0, 0.5],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: 0.35,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    _kGreen1,
                    BlendMode.color,
                  ),
                  child: Image.asset(
                    'assets/images/toba.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          ListView(
            padding: EdgeInsets.zero,
            children: [
              _Header(user: user, orang: orang, isVerified: isVerified),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _MenuTile(
                      icon: Icons.family_restroom_rounded,
                      label: 'Profil Keluarga',
                      onTap: () => context.push('/profil'),
                    ),
                    _MenuTile(
                      icon: Icons.calculate_outlined,
                      label: 'Hitung Partuturan',
                      onTap: () => context.push('/partuturan'),
                    ),
                    _MenuTile(
                      icon: Icons.edit_note_rounded,
                      label: 'Usulan',
                      locked: !isVerified,
                      onTap: isVerified
                          ? () => context.push('/usulan')
                          : () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Klaim identitas Anda dulu sebelum bisa mengajukan usulan.',
                                ),
                              ),
                            ),
                    ),
                    _MenuTile(
                      icon: Icons.school_outlined,
                      label: 'Direktori Keahlian',
                      onTap: () => context.push('/direktori-keahlian'),
                    ),
                    _MenuTile(
                      icon: Icons.map_outlined,
                      label: 'Kerabat Terdekat',
                      onTap: () => context.push('/peta-kerabat'),
                    ),
                    _MenuTile(
                      icon: Icons.photo_library_outlined,
                      label: 'Arsip',
                      onTap: () => context.push('/arsip'),
                    ),
                  ],
                ),
              ),
              if (kelengkapan != null && !kelengkapan.lengkap)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: KelengkapanProfilCard(
                    kelengkapan: kelengkapan,
                    onTap: () => context.push('/profil-saya'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final User? user;
  final MyOrang? orang;
  final bool isVerified;
  const _Header({
    required this.user,
    required this.orang,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    // Latar hijau sengaja dilukis MELEWATI batas bawah kotak header (bottom
    // negatif) supaya menu di bawahnya tampak menumpuk di atas hijau. Dulu
    // efek ini dibuat dengan menggeser menu ke atas (Transform.translate),
    // tapi itu hanya memindahkan gambar, bukan area sentuh — separuh atas
    // baris pertama menu jadi tidak bisa diketuk.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          bottom: -(_kOverlapTinggi - 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _kGreen1,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 28,
            20,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: orang == null
                        ? null
                        : () => context.push('/profil/${orang!.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _kGold, width: 2),
                      ),
                      child: orang != null
                          ? OrangAvatar(
                              orangId: orang!.id,
                              jenisKelamin: 'L',
                              radius: 26,
                            )
                          : CircleAvatar(
                              radius: 26,
                              backgroundColor: _kGold.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: orang == null
                          ? null
                          : () => context.push('/profil/${orang!.id}'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selamat datang,',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            orang?.name ?? user?.name ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (orang != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Sundut ke-${orang!.sundut} • Lihat profil saya',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const IconTheme(
                    data: IconThemeData(color: Colors.white),
                    child: NotifikasiButton(),
                  ),
                ],
              ),
              if (!isVerified) ...[
                const SizedBox(height: 18),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/klaim'),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: _kGreen1),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Identitas Anda belum tertaut ke data anggota. Tap untuk klaim sekarang.',
                              style: TextStyle(
                                color: _kGreen1,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: _kGreen1),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool locked;
  const _MenuTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                    Icon(
                      icon,
                      size: 32,
                      color: locked ? Colors.grey.shade400 : _kGreen1,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: locked ? Colors.grey.shade500 : null,
                      ),
                    ),
                  ],
                ),
                if (locked)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
