import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/utils/debouncer.dart';
import '../../../../shared/utils/orang_format.dart';
import '../../../../shared/widgets/orang_list_tile.dart';

const _kGold = Color(0xFFC8A24A);

class ProfileSearchScreen extends ConsumerStatefulWidget {
  const ProfileSearchScreen({super.key});

  @override
  ConsumerState<ProfileSearchScreen> createState() =>
      _ProfileSearchScreenState();
}

class _ProfileSearchScreenState extends ConsumerState<ProfileSearchScreen> {
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
      final rows =
          await api.callKw(
                model: 'tarombo.orang',
                method: 'search_read',
                args: [
                  [
                    ['name', 'ilike', q.trim()],
                  ],
                ],
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Keluarga')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Cari nama anggota keluarga...',
                prefixIcon: const Icon(Icons.search, color: _kGold),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
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
                : _ctrl.text.trim().length < kMinHurufCari
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
                    itemCount: _results.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final o = _results[i];
                      return OrangListTile(
                        orang: o,
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
