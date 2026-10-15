import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../utils/debouncer.dart';
import '../utils/orang_format.dart';
import 'orang_list_tile.dart';

const _kGold = Color(0xFFC8A24A);
const _kGreen1 = Color(0xFF2E5339);

/// Bottom sheet pencarian tarombo.orang. Mengembalikan satu baris hasil
/// (memuat 'id' dan 'name', serta 'sundut' dan 'ayah_id') kalau user memilih,
/// atau null kalau dibatalkan.
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
  final _debounce = Debouncer(kJedaCari);
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;
  int _seq = 0;

  void _onChanged(String q) {
    if (q.trim().length < kMinHurufCari) {
      _debounce.cancel();
      _seq++;
      setState(() {
        _results = [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce.run(() => _search(q));
  }

  Future<void> _search(String q) async {
    final saya = ++_seq;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final domain = [
        ...widget.extraDomain,
        ['name', 'ilike', q.trim()],
      ];
      final rows =
          await api.callKw(
                model: 'tarombo.orang',
                method: 'search_read',
                args: [domain],
                kwargs: {
                  'fields': kOrangSearchFields,
                  'limit': 30,
                  'order': 'name',
                },
              )
              as List;
      if (!mounted || saya != _seq) return;
      setState(() => _results = rows.cast<Map<String, dynamic>>());
    } catch (_) {
      if (!mounted || saya != _seq) return;
      setState(() => _error = 'Gagal memuat data. Periksa koneksi Anda.');
    } finally {
      if (mounted && saya == _seq) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _debounce.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cukup = _ctrl.text.trim().length >= kMinHurufCari;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kGreen1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (q) {
                  if (q.trim().length >= kMinHurufCari) _search(q);
                },
                decoration: InputDecoration(
                  hintText: 'Ketik nama...',
                  prefixIcon: const Icon(Icons.search, color: _kGold),
                  filled: true,
                  fillColor: const Color(0xFFFAF9F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    )
                  : !cukup
                  ? const Center(
                      child: Text(
                        'Ketik minimal 2 huruf untuk mencari.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _results.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ditemukan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: Colors.grey.shade200),
                      itemBuilder: (_, i) {
                        final o = _results[i];
                        return OrangListTile(
                          orang: o,
                          onTap: () => Navigator.of(context).pop(o),
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
