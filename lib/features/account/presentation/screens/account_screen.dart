import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/domain/entities/klaim_info.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../../../shared/utils/confirm_logout.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/notifikasi_button.dart';
import '../../../../shared/widgets/orang_avatar.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;
    final klaimInfo = ref.watch(klaimNotifierProvider).valueOrNull;
    final orang = klaimInfo?.orang;
    final isVerified = klaimInfo?.status == KlaimStatus.disetujui;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F4F0),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.person_outline_rounded, size: 22),
            SizedBox(width: 10),
            Text('Akun'),
          ],
        ),
        actions: const [NotifikasiButton()],
      ),
      body: Stack(
        children: [
          // Sama seperti Beranda — tekstur Danau Toba di-tint hijau & fade
          // di tepi atas, dipatok ke dasar layar, bukan ikut scroll.
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
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kGreen1,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    orang != null
                        ? OrangAvatar(
                            orangId: orang.id,
                            jenisKelamin: 'L',
                            radius: 28,
                          )
                        : CircleAvatar(
                            radius: 28,
                            backgroundColor: _kGold.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.person_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orang?.name ?? user?.name ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.login ?? '',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isVerified) ...[
                const SizedBox(height: 12),
                Material(
                  color: _kGold.withValues(alpha: 0.15),
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
              ] else if (orang != null) ...[
                const SizedBox(height: 12),
                _SectionCard(
                  children: [
                    _LinkTile(
                      icon: Icons.family_restroom_rounded,
                      label: 'Lihat Profil Saya',
                      onTap: () => context.push('/profil/${orang.id}'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              const _SectionLabel('Tentang Aplikasi'),
              const SizedBox(height: 8),
              _SectionCard(
                children: [
                  _LinkTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Kebijakan Privasi',
                    onTap: () async {
                      final uri = Uri.parse(AppConstants.privacyPolicyUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                  const _Divider(),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final info = snapshot.data;
                      final versi = info == null
                          ? '—'
                          : '${info.version} (Build ${info.buildNumber})';
                      return _InfoTile(
                        icon: Icons.info_outline_rounded,
                        label: 'Versi Aplikasi',
                        value: versi,
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                children: [
                  _LinkTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Hapus Akun',
                    color: Colors.red.shade700,
                    onTap: () => _confirmHapusAkun(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    if (await confirmLogout(context)) {
                      ref.read(authNotifierProvider.notifier).logout();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmHapusAkun(BuildContext context, WidgetRef ref) async {
  final alasanCtrl = TextEditingController();
  final confirmed = await showAppConfirmDialog(
    context,
    title: 'Hapus Akun?',
    message:
        'Permintaan akan dicatat dan diproses admin dalam maksimal 30 hari kerja. '
        'Akun dan tautan identitas Anda akan dihapus permanen; data silsilah '
        'keluarga itu sendiri tetap disimpan sebagai arsip bersama.',
    icon: Icons.delete_forever_outlined,
    confirmLabel: 'Ajukan',
    destructive: true,
    content: TextField(
      controller: alasanCtrl,
      maxLines: 2,
      decoration: InputDecoration(
        hintText: 'Alasan (opsional)',
        isDense: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  if (!confirmed) {
    alasanCtrl.dispose();
    return;
  }
  if (!context.mounted) return;

  try {
    final api = ref.read(apiClientProvider);
    final response = await api.dio.post(
      AppConstants.hapusAkunPath,
      data: {
        'jsonrpc': '2.0',
        'method': 'call',
        'params': {'alasan': alasanCtrl.text.trim()},
      },
    );
    alasanCtrl.dispose();
    final body = response.data as Map<String, dynamic>;
    final result = body['result'] as Map<String, dynamic>?;
    if (!context.mounted) return;
    if (result?['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result?['message'] as String? ?? 'Permintaan hapus akun terkirim.',
          ),
        ),
      );
      await ref.read(authNotifierProvider.notifier).logout();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengirim permintaan. Coba lagi.')),
      );
    }
  } catch (_) {
    alasanCtrl.dispose();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terjadi kesalahan jaringan. Coba lagi.')),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: _kGreen1,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 52,
    endIndent: 16,
    color: Colors.grey.shade200,
  );
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _LinkTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? _kGreen1;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade500, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: _kGreen1,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
