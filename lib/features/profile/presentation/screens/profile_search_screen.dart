import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../../shared/utils/orang_labels.dart';

const _kGold = Color(0xFFC8A24A);

class ProfileSearchScreen extends ConsumerStatefulWidget {
  const ProfileSearchScreen({super.key});

  @override
  ConsumerState<ProfileSearchScreen> createState() => _ProfileSearchScreenState();
}

class _ProfileSearchScreenState extends ConsumerState<ProfileSearchScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String q) async {
    if (q.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final rows = await api.callKw(
        model: 'tarombo.orang',
        method: 'search_read',
        args: [
          [
            ['name', 'ilike', q.trim()],
          ]
        ],
        kwargs: {
          'fields': ['id', 'name', 'sundut', 'jenis_kelamin', 'punguan_id', 'status'],
          'limit': 30,
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
      appBar: AppBar(title: const Text('Profil Keluarga')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Cari nama anggota keluarga...',
                prefixIcon: const Icon(Icons.search, color: _kGold),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: TextStyle(color: Colors.red.shade700)))
                    : _ctrl.text.trim().length < 2
                        ? const Center(child: Text('Ketik minimal 2 huruf untuk mencari.', style: TextStyle(color: Colors.grey)))
                        : _results.isEmpty
                            ? const Center(child: Text('Tidak ditemukan.', style: TextStyle(color: Colors.grey)))
                            : ListView.separated(
                                itemCount: _results.length,
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final o = _results[i];
                                  final punguan = (o['punguan_id'] is List && (o['punguan_id'] as List).length > 1)
                                      ? o['punguan_id'][1] as String
                                      : '';
                                  return ListTile(
                                    leading: OrangAvatar(orangId: o['id'] as int, jenisKelamin: o['jenis_kelamin'] as String, radius: 20),
                                    title: Text(o['name'] as String),
                                    subtitle: Text('Sundut ${o['sundut']}${punguan.isNotEmpty ? ' • $punguan' : ''} • ${statusLabel(asOdooString(o['status']))}'),
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
