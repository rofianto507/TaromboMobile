import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../../shared/utils/orang_labels.dart';
import '../../domain/entities/orang_ringkas.dart';
import '../providers/profile_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class ProfileDetailScreen extends ConsumerWidget {
  final int orangId;
  const ProfileDetailScreen({super.key, required this.orangId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(profileDetailProvider(orangId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat profil.\n$e', textAlign: TextAlign.center)),
        data: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileDetailProvider(orangId)),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Column(
                  children: [
                    OrangAvatar(orangId: d.id, jenisKelamin: d.jenisKelamin, radius: 48),
                    const SizedBox(height: 12),
                    Text(d.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kGreen1), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      children: [
                        _Badge(text: 'Sundut ${d.sundut}'),
                        _Badge(text: jenisKelaminLabel(d.jenisKelamin)),
                        if (d.punguan != null) _Badge(text: d.punguan!),
                        _Badge(
                          text: statusLabel(d.status),
                          color: d.status == 'sahih' ? Colors.green.shade50 : Colors.orange.shade50,
                          textColor: d.status == 'sahih' ? Colors.green.shade800 : Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (d.ayahId != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.man_rounded, color: _kGreen1),
                  title: Text('Ayah: ${d.ayahName}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profil/${d.ayahId}'),
                ),
              const Divider(height: 32),
              _SectionHeader(icon: Icons.arrow_upward_rounded, title: 'Leluhur', subtitle: '${d.leluhur.length} generasi ke atas'),
              if (d.leluhur.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada data leluhur.', style: TextStyle(color: Colors.grey)))
              else
                ...d.leluhur.map((o) => _OrangTile(orang: o, prefix: '${o.level}× ke atas')),
              const Divider(height: 32),
              _SectionHeader(icon: Icons.arrow_downward_rounded, title: 'Keturunan', subtitle: '${d.keturunan.length} orang tercatat'),
              if (d.keturunan.isEmpty)
                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada data keturunan.', style: TextStyle(color: Colors.grey)))
              else ...[
                ...d.keturunan.map((o) => _OrangTile(orang: o, prefix: 'Generasi ke-${o.level}')),
                if (d.keturunanMungkinTerpotong)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Sebagian keturunan tidak ditampilkan (daftar dibatasi agar tetap ringan). '
                      'Buka profil salah satu keturunan untuk melihat generasi selanjutnya.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _SectionHeader({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kGold),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _kGreen1)),
        const SizedBox(width: 8),
        Expanded(child: Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12), overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

class _OrangTile extends StatelessWidget {
  final OrangRingkas orang;
  final String prefix;
  const _OrangTile({required this.orang, required this.prefix});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: OrangAvatar(orangId: orang.id, jenisKelamin: orang.jenisKelamin, radius: 20),
      title: Text(orang.name),
      subtitle: Text('$prefix • Sundut ${orang.sundut}${orang.punguan != null ? ' • ${orang.punguan}' : ''}'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/profil/${orang.id}'),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  const _Badge({required this.text, this.color, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? _kGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor ?? _kGreen1, fontWeight: FontWeight.w600)),
    );
  }
}
