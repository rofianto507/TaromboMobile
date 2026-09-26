import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

const _kGold = Color(0xFFC8A24A);
const _kGreen1 = Color(0xFF2E5339);

/// Bottom sheet pencarian tarombo.orang. Mengembalikan {'id':..,'name':..}
/// kalau user memilih satu hasil, atau null kalau dibatalkan.
Future<Map<String, dynamic>?> showOrangSearchSheet(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Cari Orang',
  List extraDomain = const [],
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _OrangSearchSheet(title: title, extraDomain: extraDomain),
  );
}

class _OrangSearchSheet extends ConsumerStatefulWidget {
  final String title;
  final List extraDomain;
  const _OrangSearchSheet({required this.title, required this.extraDomain});

  @override
  ConsumerState<_OrangSearchSheet> createState() => _OrangSearchSheetState();
}

class _OrangSearchSheetState extends ConsumerState<_OrangSearchSheet> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String q) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final domain = [
        ...widget.extraDomain,
        if (q.trim().isNotEmpty) ['name', 'ilike', q.trim()],
      ];
      final rows = await api.callKw(
        model: 'tarombo.orang',
        method: 'search_read',
        args: [domain],
        kwargs: {
          'fields': ['id', 'name', 'sundut', 'jenis_kelamin', 'punguan_id'],
          'limit': 30,
          'order': 'name',
        },
      ) as List;
      setState(() => _results = rows.cast<Map<String, dynamic>>());
    } catch (e) {
      setState(() => _error = 'Gagal memuat data. Periksa koneksi Anda.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _kGreen1)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
                decoration: InputDecoration(
                  hintText: 'Ketik nama...',
                  prefixIcon: const Icon(Icons.search, color: _kGold),
                  filled: true,
                  fillColor: const Color(0xFFFAF9F5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade700)))
                      : _results.isEmpty
                          ? const Center(child: Text('Tidak ada hasil.', style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _results.length,
                              separatorBuilder: (_, _) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (_, i) {
                                final o = _results[i];
                                final punguan = (o['punguan_id'] is List && (o['punguan_id'] as List).length > 1)
                                    ? o['punguan_id'][1] as String
                                    : '';
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _kGold.withValues(alpha: 0.15),
                                    child: Icon(
                                      o['jenis_kelamin'] == 'P' ? Icons.woman_rounded : Icons.man_rounded,
                                      color: _kGreen1,
                                    ),
                                  ),
                                  title: Text(o['name'] as String),
                                  subtitle: Text('Sundut ${o['sundut']}${punguan.isNotEmpty ? ' • $punguan' : ''}'),
                                  onTap: () => Navigator.of(context).pop({'id': o['id'], 'name': o['name']}),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
