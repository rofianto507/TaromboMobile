import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../shared/utils/arsip_labels.dart';
import '../../../../shared/utils/orang_labels.dart';
import '../../../../shared/widgets/arsip_thumbnail.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../tarombo_tree/presentation/providers/pohon_provider.dart';
import '../../domain/entities/orang_ringkas.dart';
import '../providers/profile_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class ProfileDetailScreen extends ConsumerStatefulWidget {
  final int orangId;
  const ProfileDetailScreen({super.key, required this.orangId});

  @override
  ConsumerState<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends ConsumerState<ProfileDetailScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Domisili'),
    Tab(text: 'Keluarga'),
    Tab(text: 'Riwayat'),
    Tab(text: 'Arsip'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(profileDetailProvider(widget.orangId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat profil.\n$e', textAlign: TextAlign.center)),
        data: (d) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(profileDetailProvider(widget.orangId)),
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(child: _HeaderSection(d: d)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: _tabs,
                    labelColor: _kGreen1,
                    unselectedLabelColor: Colors.grey.shade500,
                    indicatorColor: _kGold,
                    indicatorWeight: 3,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _DomisiliTab(d: d),
                _KeluargaTab(d: d),
                _RiwayatTab(d: d),
                _ArsipTab(d: d),
              ],
            ),
          ),
        ),
      ),
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
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => oldDelegate.tabBar != tabBar;
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
                    _Badge(
                      text: statusLabel(d.status),
                      color: d.status == 'sahih' ? Colors.green.shade50 : Colors.orange.shade50,
                      textColor: d.status == 'sahih' ? Colors.green.shade800 : Colors.orange.shade800,
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
                  style: OutlinedButton.styleFrom(foregroundColor: _kGreen1, side: const BorderSide(color: _kGold)),
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

// ── Tab: Domisili ───────────────────────────────────────────────────────

class _DomisiliTab extends StatelessWidget {
  final ProfileDetail d;
  const _DomisiliTab({required this.d});

  @override
  Widget build(BuildContext context) {
    final info = d.domisili;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            const Icon(Icons.place_rounded, color: _kGold),
            const SizedBox(width: 8),
            const Text('Domisili', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: _kGreen1)),
          ],
        ),
        const SizedBox(height: 12),
        if (info.alamatJalan == null && info.lengkap == null)
          const Text('Belum ada data domisili.', style: TextStyle(color: Colors.grey))
        else ...[
          if (info.alamatJalan != null)
            Text(info.alamatJalan!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          if (info.lengkap != null)
            Text(info.lengkap!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          if (info.negara != null) Text(info.negara!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          if (info.catatan != null) ...[
            const SizedBox(height: 4),
            Text(info.catatan!, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
        const SizedBox(height: 16),
        if (info.berbagiLokasi && info.lat != null && info.lng != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 200,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(initialCenter: LatLng(info.lat!, info.lng!), initialZoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'id.selstudio.tarombo_mobile',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(info.lat!, info.lng!),
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on, color: d.jenisKelamin == 'P' ? Colors.pink.shade400 : _kGreen1, size: 40),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.location_off_outlined, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Titik lokasi tidak dibagikan oleh orang ini.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
      ],
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
        _SectionHeader(icon: Icons.arrow_upward_rounded, title: 'Leluhur', subtitle: '${d.leluhur.length} generasi ke atas'),
        if (d.leluhur.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada data leluhur.', style: TextStyle(color: Colors.grey)))
        else
          ...d.leluhur.map((o) => _OrangTile(orang: o, subtitle: '${o.level}× ke atas • Sundut ${o.sundut}')),
        const Divider(height: 32),
        _SectionHeader(icon: Icons.favorite_rounded, title: 'Pernikahan', subtitle: d.pernikahan.length > 1 ? '${d.pernikahan.length} pernikahan tercatat' : ''),
        if (d.pernikahan.isNotEmpty)
          ...d.pernikahan.map((p) {
            final namaAda = p.istriNama.trim().isNotEmpty;
            final tahunValid = p.tahun != null && p.tahun! >= 1000;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(backgroundColor: Color(0x1FC8A24A), child: Icon(Icons.woman_rounded, color: _kGreen1)),
              title: Text(namaAda ? p.istriNama : (p.istriMarga ?? 'Tidak diketahui')),
              subtitle: Text([
                if (namaAda && p.istriMarga != null) 'Marga ${p.istriMarga}',
                if (tahunValid) 'Menikah ${p.tahun}',
                if (p.jumlahAnak > 0) '${p.jumlahAnak} anak',
              ].join(' • ')),
            );
          })
        else if (d.suamiNama != null)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Color(0x1FC8A24A), child: Icon(Icons.man_rounded, color: _kGreen1)),
            title: Text('Suami: ${d.suamiNama}'),
            subtitle: d.suamiMarga != null ? Text('Marga ${d.suamiMarga}') : null,
          )
        else
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada data pernikahan.', style: TextStyle(color: Colors.grey))),
        const Divider(height: 32),
        _SectionHeader(icon: Icons.arrow_downward_rounded, title: 'Anak', subtitle: '${d.anak.length} anak tercatat'),
        if (d.anak.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada data anak.', style: TextStyle(color: Colors.grey)))
        else
          ...d.anak.map((o) => _OrangTile(
                orang: o,
                subtitle: 'Anak ke-${o.level} • ${jenisKelaminLabel(o.jenisKelamin)}'
                    '${o.jumlahAnak > 0 ? ' • ${o.jumlahAnak} anak' : ''}',
              )),
      ],
    );
  }
}

// ── Tab: Riwayat ────────────────────────────────────────────────────────

class _RiwayatTab extends StatelessWidget {
  final ProfileDetail d;
  const _RiwayatTab({required this.d});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _SectionHeader(icon: Icons.school_rounded, title: 'Pendidikan', subtitle: ''),
        if (d.pendidikan.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada data pendidikan.', style: TextStyle(color: Colors.grey)))
        else
          ...d.pendidikan.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Color(0x1FC8A24A), child: Icon(Icons.school_outlined, color: _kGreen1)),
                title: Text(p.institusi),
                subtitle: Text([
                  if (p.jenjang != null) jenjangLabel(p.jenjang),
                  if (p.jurusan != null) p.jurusan!,
                  if (p.tahunMasuk != null || p.tahunLulus != null) '${p.tahunMasuk ?? '?'}–${p.lulus ? (p.tahunLulus ?? '?') : 'sekarang'}',
                ].join(' • ')),
              )),
        const Divider(height: 32),
        _SectionHeader(icon: Icons.work_rounded, title: 'Pekerjaan', subtitle: ''),
        if (d.pekerjaan.isEmpty)
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Belum ada data pekerjaan.', style: TextStyle(color: Colors.grey)))
        else
          ...d.pekerjaan.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: Color(0x1FC8A24A), child: Icon(Icons.work_outline_rounded, color: _kGreen1)),
                title: Text(p.jabatan),
                subtitle: Text([
                  if (p.instansi != null) p.instansi!,
                  if (p.bidang != null) p.bidang!,
                  if (p.tahunMulai != null) '${p.tahunMulai}–${p.sekarang ? 'sekarang' : (p.tahunSelesai ?? '?')}',
                ].join(' • ')),
              )),
      ],
    );
  }
}

// ── Tab: Arsip ──────────────────────────────────────────────────────────

class _ArsipTab extends StatelessWidget {
  final ProfileDetail d;
  const _ArsipTab({required this.d});

  @override
  Widget build(BuildContext context) {
    if (d.arsip.isEmpty) {
      return const Center(child: Text('Belum ada arsip terkait.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: d.arsip.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final item = d.arsip[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/arsip/${item.id}'),
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 72,
                  child: ArsipThumbnail(arsipId: item.id, jenis: item.jenis, icon: jenisArsipIcon(item.jenis)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, color: _kGreen1)),
                      const SizedBox(height: 2),
                      Text(
                        [jenisArsipLabel(item.jenis), if (item.tahunPerkiraan != null) item.tahunPerkiraan!].join(' • '),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
      leading: OrangAvatar(orangId: orang.id, jenisKelamin: orang.jenisKelamin, radius: 20),
      title: Row(
        children: [
          Flexible(child: Text(orang.name, overflow: TextOverflow.ellipsis)),
          if (!orang.masihHidup) ...[
            const SizedBox(width: 6),
            Text('(Alm.)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
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
      child: Text(text, style: TextStyle(fontSize: 12, color: textColor ?? _kGreen1, fontWeight: FontWeight.w600)),
    );
  }
}
