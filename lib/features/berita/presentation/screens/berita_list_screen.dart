import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/berita_provider.dart';
import '../widgets/berita_gambar.dart';
import '../widgets/berita_slider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

const _filter = <(String?, String)>[
  (null, 'Semua'),
  ('berita', 'Berita'),
  ('agenda', 'Agenda'),
];

class BeritaListScreen extends ConsumerStatefulWidget {
  const BeritaListScreen({super.key});

  @override
  ConsumerState<BeritaListScreen> createState() => _BeritaListScreenState();
}

class _BeritaListScreenState extends ConsumerState<BeritaListScreen> {
  String? _jenis;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(beritaDaftarProvider(_jenis));
    return Scaffold(
      appBar: AppBar(title: const Text('Berita & Agenda')),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final (kode, label) in _filter)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _jenis == kode,
                      selectedColor: _kGold.withValues(alpha: 0.25),
                      labelStyle: TextStyle(
                        color: _jenis == kode ? _kGreen1 : Colors.grey.shade700,
                        fontWeight: _jenis == kode
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _jenis = kode),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat. Periksa koneksi Anda.',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
              data: (items) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(beritaDaftarProvider(_jenis)),
                child: items.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 120),
                          Center(
                            child: Text(
                              'Belum ada berita atau agenda.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final b = items[i];
                          return Material(
                            color: Colors.white,
                            elevation: 1,
                            borderRadius: BorderRadius.circular(14),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/berita/${b.id}'),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 104,
                                    child: BeritaGambar(
                                      beritaId: b.id,
                                      punyaGambar: b.punyaGambar,
                                      agenda: b.agenda,
                                      height: 104,
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          LabelJenis(item: b),
                                          const SizedBox(height: 6),
                                          Text(
                                            b.judul,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              height: 1.25,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            keteranganBerita(b),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
