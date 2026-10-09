import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/arsip_labels.dart';
import '../../../../shared/widgets/arsip_thumbnail.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/arsip_item.dart';
import 'arsip_detail_sheet.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class ArsipListScreen extends ConsumerStatefulWidget {
  const ArsipListScreen({super.key});

  @override
  ConsumerState<ArsipListScreen> createState() => _ArsipListScreenState();
}

class _ArsipListScreenState extends ConsumerState<ArsipListScreen> {
  final _ctrl = TextEditingController();
  String? _jenisFilter;
  List<ArsipItem> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  Future<void> _search([String q = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final domain = [
        if (_jenisFilter != null) ['jenis', '=', _jenisFilter],
        if (q.trim().isNotEmpty) ['name', 'ilike', q.trim()],
      ];
      final rows = await api.callKw(
        model: 'tarombo.arsip',
        method: 'search_read',
        args: [domain],
        kwargs: {
          'fields': ['id', 'name', 'jenis', 'orang_id', 'punguan_id', 'tahun_perkiraan'],
          'limit': 60,
          'order': 'name',
        },
      ) as List;
      setState(() => _results = rows.cast<Map<String, dynamic>>().map(ArsipItem.fromJson).toList());
    } catch (_) {
      setState(() => _error = 'Gagal memuat data. Periksa koneksi Anda.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arsip')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama arsip...',
                prefixIcon: const Icon(Icons.search, color: _kGold),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(label: 'Semua', selected: _jenisFilter == null, onTap: () {
                  setState(() => _jenisFilter = null);
                  _search(_ctrl.text);
                }),
                const SizedBox(width: 8),
                ...jenisArsipLabels.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: e.value,
                        selected: _jenisFilter == e.key,
                        onTap: () {
                          setState(() => _jenisFilter = _jenisFilter == e.key ? null : e.key);
                          _search(_ctrl.text);
                        },
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => _search(_ctrl.text),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? const Center(child: Text('Belum ada arsip.', style: TextStyle(color: Colors.grey)))
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                            itemCount: _results.length,
                            itemBuilder: (_, i) => _ArsipCard(
                              item: _results[i],
                              onDihapus: () => _search(_ctrl.text),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _ArsipCard extends StatelessWidget {
  final ArsipItem item;
  final VoidCallback onDihapus;
  const _ArsipCard({required this.item, required this.onDihapus});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final dihapus = await showArsipDetailSheet(context, item.id);
          if (dihapus) onDihapus();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ArsipThumbnail(arsipId: item.id, jenis: item.jenis, icon: jenisArsipIcon(item.jenis), height: 120),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _kGreen1)),
                  const SizedBox(height: 4),
                  Text(
                    [jenisArsipLabel(item.jenis), if (item.orangName != null) item.orangName!].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _kGold.withValues(alpha: 0.25),
      labelStyle: TextStyle(color: selected ? _kGreen1 : Colors.grey.shade700, fontWeight: selected ? FontWeight.w700 : FontWeight.normal),
    );
  }
}
