import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../../shared/utils/orang_labels.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class DirektoriKeahlianScreen extends ConsumerStatefulWidget {
  const DirektoriKeahlianScreen({super.key});

  @override
  ConsumerState<DirektoriKeahlianScreen> createState() => _DirektoriKeahlianScreenState();
}

class _DirektoriKeahlianScreenState extends ConsumerState<DirektoriKeahlianScreen> {
  final _ctrl = TextEditingController();
  int? _bidangFilter;
  List<Map<String, dynamic>> _bidangList = [];
  List<Map<String, dynamic>> _results = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBidangList();
    _search();
  }

  Future<void> _loadBidangList() async {
    try {
      final api = ref.read(apiClientProvider);
      // tarombo.bidang dikelola bebas oleh pengurus/admin (menu Konfigurasi),
      // jadi daftar chip filter di sini HARUS diambil langsung dari server,
      // bukan daftar tetap — supaya bidang baru yang ditambahkan otomatis
      // muncul tanpa perlu update aplikasi.
      final rows = await api.callKw(
        model: 'tarombo.bidang',
        method: 'search_read',
        args: [[]],
        kwargs: {'fields': ['id', 'name'], 'order': 'name'},
      ) as List;
      if (mounted) setState(() => _bidangList = rows.cast<Map<String, dynamic>>());
    } catch (_) {
      // Non-fatal: chip filter bidang cukup kosong, pencarian utama tetap jalan.
    }
  }

  Future<void> _search([String q = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final domain = [
        ['masih_hidup', '=', true],
        if (_bidangFilter != null) ['bidang_kini_id', '=', _bidangFilter],
        if (q.trim().isNotEmpty)
          '|',
        if (q.trim().isNotEmpty) ['name', 'ilike', q.trim()],
        if (q.trim().isNotEmpty) ['pekerjaan_kini', 'ilike', q.trim()],
      ];
      final rows = await api.callKw(
        model: 'tarombo.orang',
        method: 'search_read',
        args: [domain],
        kwargs: {
          'fields': ['id', 'name', 'jenis_kelamin', 'bidang_kini_id', 'pekerjaan_kini', 'pendidikan_tertinggi', 'wilayah_id'],
          'limit': 50,
          'order': 'name',
        },
      ) as List;
      setState(() => _results = rows.cast<Map<String, dynamic>>());
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
      appBar: AppBar(title: const Text('Direktori Keahlian')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _ctrl,
              textInputAction: TextInputAction.search,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama atau pekerjaan...',
                prefixIcon: const Icon(Icons.search, color: _kGold),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (_bidangList.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(label: 'Semua Bidang', selected: _bidangFilter == null, onTap: () {
                    setState(() => _bidangFilter = null);
                    _search(_ctrl.text);
                  }),
                  const SizedBox(width: 8),
                  ..._bidangList.map((b) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: b['name'] as String,
                          selected: _bidangFilter == b['id'],
                          onTap: () {
                            setState(() => _bidangFilter = _bidangFilter == b['id'] ? null : b['id'] as int);
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
                    ? Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade700)))
                    : _results.isEmpty
                        ? const Center(child: Text('Tidak ditemukan.', style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, _) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final o = _results[i];
                              final wilayah = (o['wilayah_id'] is List && (o['wilayah_id'] as List).length > 1) ? o['wilayah_id'][1] as String : null;
                              final bidang = (o['bidang_kini_id'] is List && (o['bidang_kini_id'] as List).length > 1) ? o['bidang_kini_id'][1] as String : null;
                              final pekerjaan = asOdooString(o['pekerjaan_kini']);
                              return ListTile(
                                leading: OrangAvatar(orangId: o['id'] as int, jenisKelamin: o['jenis_kelamin'] as String, radius: 20),
                                title: Text(o['name'] as String),
                                subtitle: Text(
                                  [
                                    if (pekerjaan != null && pekerjaan.isNotEmpty) pekerjaan,
                                    ?bidang,
                                    jenjangLabel(asOdooString(o['pendidikan_tertinggi'])),
                                    ?wilayah,
                                  ].join(' • '),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push('/profil/${o['id']}'),
                              );
                            },
                          ),
          ),
        ],
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
