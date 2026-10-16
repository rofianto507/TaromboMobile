import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/verified_badge.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/utils/arsip_labels.dart';
import '../../../../shared/utils/orang_labels.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/arsip_thumbnail.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../arsip/presentation/screens/arsip_detail_sheet.dart';
import '../../../arsip/presentation/widgets/arsip_form_sheet.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../../tarombo_tree/presentation/providers/pohon_provider.dart';
import '../../domain/entities/orang_ringkas.dart';
import '../providers/profile_provider.dart';
import '../widgets/riwayat_form_sheet.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final int orangId;

  /// Tab yang dibuka pertama kali: 'kontak' (telepon, email, dan domisili;
  /// hanya ada untuk akun terverifikasi), 'keluarga', 'riwayat', atau
  /// 'arsip'. 'domisili' dianggap 'kontak' karena kedua tab sudah digabung.
  /// Dipakai tautan dari layar lain, mis. Lengkapi Profil.
  final String? tabAwal;
  const ProfileDetailScreen({super.key, required this.orangId, this.tabAwal});

  @override
  ConsumerState<ProfileDetailScreen> createState() =>
      _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(profileDetailProvider(widget.orangId));
    final myOrangId = ref.watch(klaimNotifierProvider).valueOrNull?.orang?.id;
    final d = detailAsync.valueOrNull;
    // get_my_orang() (sumber myOrangId) cuma terisi kalau klaim identitas
    // sudah disetujui pengurus — jadi tidak perlu cek status verifikasi
    // terpisah di sini, perbandingan id saja sudah cukup.
    final isMilikSendiri = myOrangId != null && d != null && myOrangId == d.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (isMilikSendiri)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Lengkapi Profil',
              onPressed: () => context.push('/profil-saya'),
            ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Gagal memuat profil.\n$e', textAlign: TextAlign.center),
        ),
        data: (d) => RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(profileDetailProvider(widget.orangId)),
          child: _ProfilTabs(
            d: d,
            isMilikSendiri: isMilikSendiri,
            tabAwal: widget.tabAwal,
          ),
        ),
      ),
    );
  }
}

/// Header + tab profil. Dipisah supaya jumlah tab bisa menyesuaikan data:
/// tab Kontak hanya ada bila akun yang melihat sudah terverifikasi.
class _ProfilTabs extends StatefulWidget {
  final ProfileDetail d;
  final bool isMilikSendiri;
  final String? tabAwal;
  const _ProfilTabs({
    required this.d,
    required this.isMilikSendiri,
    this.tabAwal,
  });

  @override
  State<_ProfilTabs> createState() => _ProfilTabsState();
}

class _ProfilTabsState extends State<_ProfilTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _kunci;

  static const _judul = {
    'keluarga': 'Keluarga',
    'riwayat': 'Riwayat',
    'arsip': 'Arsip',
    'kontak': 'Kontak',
  };

  // Tab Kontak (telepon, email, domisili) hanya untuk akun terverifikasi.
  List<String> _hitungKunci() => [
    if (widget.d.kontakTerverifikasi) 'kontak',
    'keluarga',
    'riwayat',
    'arsip',
  ];

  @override
  void initState() {
    super.initState();
    _kunci = _hitungKunci();
    final tujuan = widget.tabAwal == 'domisili' ? 'kontak' : widget.tabAwal;
    final awal = _kunci.indexOf(tujuan ?? '');
    _tabController = TabController(
      length: _kunci.length,
      vsync: this,
      initialIndex: awal < 0 ? 0 : awal,
    );
  }

  @override
  void didUpdateWidget(covariant _ProfilTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    final baru = _hitungKunci();
    if (baru.length != _kunci.length) {
      // Status verifikasi berubah setelah refresh: bangun ulang controller.
      final index = _tabController.index.clamp(0, baru.length - 1);
      _tabController.dispose();
      _kunci = baru;
      _tabController = TabController(
        length: baru.length,
        vsync: this,
        initialIndex: index,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _isi(String kunci) {
    final d = widget.d;
    switch (kunci) {
      case 'keluarga':
        return _KeluargaTab(d: d);
      case 'riwayat':
        return _RiwayatTab(d: d, editable: widget.isMilikSendiri);
      case 'arsip':
        return _ArsipTab(d: d, editable: widget.isMilikSendiri);
      case 'kontak':
        return _KontakTab(d: d);
      default:
        return _KeluargaTab(d: d);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) => [
        SliverToBoxAdapter(child: _HeaderSection(d: widget.d)),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            TabBar(
              controller: _tabController,
              tabs: [for (final k in _kunci) Tab(text: _judul[k])],
              labelColor: _kGreen1,
              unselectedLabelColor: Colors.grey.shade500,
              indicatorColor: _kGold,
              indicatorWeight: 3,
            ),
          ),
        ),
      ],
      body: TabBarView(
        key: ValueKey(_kunci.length),
        controller: _tabController,
        children: [for (final k in _kunci) _isi(k)],
      ),
    );
  }
}

/// Tab Kontak — telepon, email, dan domisili. Hanya dirender untuk akun
/// terverifikasi (lihat _ProfilTabs).
class _KontakTab extends StatelessWidget {
  final ProfileDetail d;
  const _KontakTab({required this.d});

  Widget _judul(IconData ikon, String teks) => Row(
    children: [
      Icon(ikon, color: _kGold),
      const SizedBox(width: 8),
      Text(
        teks,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: _kGreen1,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final info = d.domisili;
    final adaKontak = d.noTelp != null || d.emailKontak != null;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (!adaKontak)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada kontak yang dicantumkan.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          )
        else ...[
          if (d.noTelp != null)
            _KontakBaris(
              ikon: Icons.phone_outlined,
              teks: d.noTelp!,
              aksi: 'Telepon',
              uri: Uri(
                scheme: 'tel',
                path: d.noTelp!.replaceAll(RegExp(r'[^0-9+]'), ''),
              ),
            ),
          if (d.emailKontak != null)
            _KontakBaris(
              ikon: Icons.email_outlined,
              teks: d.emailKontak!,
              aksi: 'Kirim email',
              uri: Uri(scheme: 'mailto', path: d.emailKontak!),
            ),
        ],
        const SizedBox(height: 20),
        Divider(height: 1, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        _judul(Icons.place_rounded, 'Domisili'),
        const SizedBox(height: 12),
        if (info.lengkap == null)
          const Text(
            'Belum ada data domisili.',
            style: TextStyle(color: Colors.grey),
          )
        else ...[
          Text(
            info.lengkap!,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          if (info.negara != null)
            Text(
              info.negara!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
        ],
        const SizedBox(height: 24),
        Text(
          'Kontak dan domisili hanya terlihat oleh anggota yang akunnya sudah terverifikasi.',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) =>
      oldDelegate.tabBar != tabBar;
}

class _HeaderSection extends ConsumerWidget {
  final ProfileDetail d;
  const _HeaderSection({required this.d});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                OrangAvatar(
                  orangId: d.id,
                  jenisKelamin: d.jenisKelamin,
                  radius: 48,
                ),
                const SizedBox(height: 12),
                OrangNama(
                  nama: d.name,
                  terverifikasi: d.terhubungAkun,
                  badgeSize: 22,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _kGreen1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  children: [
                    _Badge(text: 'Sundut ${d.sundut}'),
                    if (d.umur != null) _Badge(text: '${d.umur} tahun'),
                    _Badge(text: jenisKelaminLabel(d.jenisKelamin)),
                    _Badge(
                      text: statusLabel(d.status),
                      color: d.status == 'sahih'
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      textColor: d.status == 'sahih'
                          ? Colors.green.shade800
                          : Colors.orange.shade800,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(pohonNotifierProvider.notifier)
                      ..gantiMode(PohonMode.cabang)
                      ..pindahFokus(d.id);
                    context.go('/tarombo');
                  },
                  icon: const Icon(Icons.account_tree_rounded, size: 18),
                  label: const Text('Lihat di Tarombo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _kGreen1,
                    side: const BorderSide(color: _kGold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (d.ayahId != null)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.man_rounded, color: _kGreen1),
              title: Text('Ayah: ${d.ayahName}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/profil/${d.ayahId}'),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kGold),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: _kGreen1,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

// ── Tab: Domisili ───────────────────────────────────────────────────────

/// Satu baris kontak yang bisa diketuk untuk menelepon / membuka email.
class _KontakBaris extends StatelessWidget {
  final IconData ikon;
  final String teks;
  final String aksi;
  final Uri uri;
  const _KontakBaris({
    required this.ikon,
    required this.teks,
    required this.aksi,
    required this.uri,
  });

  Future<void> _buka(BuildContext context) async {
    final ok = await launchUrl(uri);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada aplikasi untuk "${aksi.toLowerCase()}" di perangkat ini.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: const Color(0x1FC8A24A),
        child: Icon(ikon, color: _kGreen1, size: 18),
      ),
      title: Text(teks, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        aksi,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _buka(context),
    );
  }
}

// ── Tab: Keluarga ───────────────────────────────────────────────────────

class _KeluargaTab extends StatelessWidget {
  final ProfileDetail d;
  const _KeluargaTab({required this.d});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          icon: Icons.arrow_upward_rounded,
          title: 'Leluhur',
          subtitle: '${d.leluhur.length} generasi ke atas',
        ),
        if (d.leluhur.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada data leluhur.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...d.leluhur.map(
            (o) => _OrangTile(
              orang: o,
              subtitle: '${o.level}× ke atas • Sundut ${o.sundut}',
            ),
          ),
        const Divider(height: 32),
        _SectionHeader(
          icon: Icons.favorite_rounded,
          title: 'Pernikahan',
          subtitle: d.pernikahan.length > 1
              ? '${d.pernikahan.length} pernikahan tercatat'
              : '',
        ),
        if (d.pernikahan.isNotEmpty)
          ...d.pernikahan.map((p) {
            final namaAda = p.istriNama.trim().isNotEmpty;
            final tahunValid = p.tahun != null && p.tahun! >= 1000;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x1FC8A24A),
                child: Icon(Icons.woman_rounded, color: _kGreen1),
              ),
              title: Text(
                namaAda ? p.istriNama : (p.istriMarga ?? 'Tidak diketahui'),
              ),
              subtitle: Text(
                [
                  if (namaAda && p.istriMarga != null) 'Marga ${p.istriMarga}',
                  if (tahunValid) 'Menikah ${p.tahun}',
                  if (p.jumlahAnak > 0) '${p.jumlahAnak} anak',
                ].join(' • '),
              ),
            );
          })
        else if (d.suamiNama != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: Color(0x1FC8A24A),
              child: Icon(Icons.man_rounded, color: _kGreen1),
            ),
            title: Text('Suami: ${d.suamiNama}'),
            subtitle: d.suamiMarga != null
                ? Text('Marga ${d.suamiMarga}')
                : null,
          )
        else
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada data pernikahan.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        const Divider(height: 32),
        _SectionHeader(
          icon: Icons.arrow_downward_rounded,
          title: 'Anak',
          subtitle: '${d.anak.length} anak tercatat',
        ),
        if (d.anak.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada data anak.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...d.anak.map(
            (o) => _OrangTile(
              orang: o,
              subtitle:
                  'Anak ke-${o.level} • ${jenisKelaminLabel(o.jenisKelamin)}'
                  '${o.jumlahAnak > 0 ? ' • ${o.jumlahAnak} anak' : ''}',
            ),
          ),
      ],
    );
  }
}

// ── Tab: Riwayat ────────────────────────────────────────────────────────

class _RiwayatTab extends ConsumerWidget {
  final ProfileDetail d;
  // true hanya di profil sendiri: boleh tambah/hapus riwayat tanpa verifikasi pengurus.
  final bool editable;
  const _RiwayatTab({required this.d, required this.editable});

  Future<void> _hapus(
    BuildContext context,
    WidgetRef ref, {
    required String nama,
    required Future<void> Function() aksi,
  }) async {
    final yakin = await showAppConfirmDialog(
      context,
      title: 'Hapus riwayat?',
      message: '"$nama" akan dihapus dari profil Anda.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!yakin) return;
    try {
      await aksi();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  Widget _tombolTambah(VoidCallback onTap) => TextButton.icon(
    onPressed: onTap,
    icon: const Icon(Icons.add, size: 18),
    label: const Text('Tambah'),
    style: TextButton.styleFrom(foregroundColor: _kGreen1),
  );

  Widget? _tombolHapus(VoidCallback onTap) => editable
      ? IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Hapus',
          onPressed: onTap,
        )
      : null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(riwayatRepositoryProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(
          icon: Icons.school_rounded,
          title: 'Pendidikan',
          subtitle: '',
          trailing: editable
              ? _tombolTambah(() => showPendidikanFormSheet(context, d.id))
              : null,
        ),
        if (d.pendidikan.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada data pendidikan.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...d.pendidikan.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x1FC8A24A),
                child: Icon(Icons.school_outlined, color: _kGreen1),
              ),
              title: Text(p.institusi),
              subtitle: Text(
                [
                  if (p.jenjang != null) jenjangLabel(p.jenjang),
                  if (p.jurusan != null) p.jurusan!,
                  if (p.tahunMasuk != null || p.tahunLulus != null)
                    '${p.tahunMasuk ?? '?'}–${p.lulus ? (p.tahunLulus ?? '?') : 'sekarang'}',
                ].join(' • '),
              ),
              trailing: _tombolHapus(
                () => _hapus(
                  context,
                  ref,
                  nama: p.institusi,
                  aksi: () => repo.hapusPendidikan(d.id, p.id),
                ),
              ),
            ),
          ),
        const Divider(height: 32),
        _SectionHeader(
          icon: Icons.work_rounded,
          title: 'Pekerjaan',
          subtitle: '',
          trailing: editable
              ? _tombolTambah(() => showPekerjaanFormSheet(context, d.id))
              : null,
        ),
        if (d.pekerjaan.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Belum ada data pekerjaan.',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...d.pekerjaan.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0x1FC8A24A),
                child: Icon(Icons.work_outline_rounded, color: _kGreen1),
              ),
              title: Text(p.jabatan),
              subtitle: Text(
                [
                  if (p.instansi != null) p.instansi!,
                  if (p.bidang != null) p.bidang!,
                  if (p.tahunMulai != null)
                    '${p.tahunMulai}–${p.sekarang ? 'sekarang' : (p.tahunSelesai ?? '?')}',
                ].join(' • '),
              ),
              trailing: _tombolHapus(
                () => _hapus(
                  context,
                  ref,
                  nama: p.jabatan,
                  aksi: () => repo.hapusPekerjaan(d.id, p.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Tab: Arsip ──────────────────────────────────────────────────────────

class _ArsipTab extends ConsumerWidget {
  final ProfileDetail d;
  // true hanya di profil sendiri: boleh menambah arsip tanpa verifikasi pengurus.
  final bool editable;
  const _ArsipTab({required this.d, required this.editable});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tombolTambah = editable
        ? Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                final ok = await showArsipFormSheet(context, d.id);
                if (ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Arsip berhasil ditambahkan.'),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Arsip'),
              style: TextButton.styleFrom(foregroundColor: _kGreen1),
            ),
          )
        : null;

    if (d.arsip.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Belum ada arsip terkait.',
              style: TextStyle(color: Colors.grey),
            ),
            ?tombolTambah,
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: d.arsip.length + (tombolTambah != null ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (tombolTambah != null) {
          if (i == 0) return tombolTambah;
          i -= 1;
        }
        final item = d.arsip[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () async {
              final dihapus = await showArsipDetailSheet(context, item.id);
              if (dihapus) ref.invalidate(profileDetailProvider(d.id));
            },
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ArsipThumbnail(
                    arsipId: item.id,
                    jenis: item.jenis,
                    icon: jenisArsipIcon(item.jenis),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _kGreen1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          jenisArsipLabel(item.jenis),
                          if (item.tahunPerkiraan != null) item.tahunPerkiraan!,
                        ].join(' • '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrangTile extends StatelessWidget {
  final OrangRingkas orang;
  final String subtitle;
  const _OrangTile({required this.orang, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: OrangAvatar(
        orangId: orang.id,
        jenisKelamin: orang.jenisKelamin,
        radius: 20,
      ),
      title: Row(
        children: [
          Flexible(
            child: OrangNama(
              nama: orang.name,
              terverifikasi: orang.terhubungAkun,
              maxLines: 1,
            ),
          ),
          if (!orang.masihHidup) ...[
            const SizedBox(width: 6),
            Text(
              '(Alm.)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(subtitle),
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
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: textColor ?? _kGreen1,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
