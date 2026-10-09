import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/klaim_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class KlaimSearchScreen extends ConsumerStatefulWidget {
  const KlaimSearchScreen({super.key});

  @override
  ConsumerState<KlaimSearchScreen> createState() => _KlaimSearchScreenState();
}

class _KlaimSearchScreenState extends ConsumerState<KlaimSearchScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  bool _submitting = false;
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
        // Hanya orang yang belum ditautkan akun siapa pun — aman dievaluasi
        // anggota biasa karena user_id sengaja tidak dibatasi groups=.
        args: [
          [
            ['user_id', '=', false],
            ['name', 'ilike', q.trim()],
          ]
        ],
        kwargs: {
          'fields': ['id', 'name', 'sundut', 'jenis_kelamin', 'punguan_id'],
          'limit': 20,
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

  Future<void> _klaim(Map<String, dynamic> orang) async {
    final confirm = await showAppConfirmDialog(
      context,
      title: 'Konfirmasi Klaim',
      message:
          'Apakah "${orang['name']}" adalah diri Anda sendiri di pohon keluarga?\n\nPengurus akan meninjau klaim ini sebelum disetujui.',
      icon: Icons.verified_user_outlined,
      confirmLabel: 'Ya, Ini Saya',
    );
    if (!confirm) return;

    setState(() => _submitting = true);
    try {
      await ref.read(klaimNotifierProvider.notifier).ajukanOrangAda(orangId: orang['id'] as int);
    } catch (e) {
      if (!mounted) return;
      final msg = e is ServerException ? e.message : 'Gagal mengirim klaim. Coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
      appBar: AppBar(
        title: const Text('Klaim Identitas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Sudah pernah mengajukan? Muat ulang status',
            onPressed: () => ref.invalidate(klaimNotifierProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: _kGreen1,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cari nama Anda di pohon keluarga Tarombo, lalu klaim sebagai diri sendiri. '
                  'Klaim akan ditinjau pengurus sebelum disetujui.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(foregroundColor: _kGold, padding: const EdgeInsets.symmetric(horizontal: 8)),
                    onPressed: () {
                      ref.read(klaimReminderDismissedProvider.notifier).state = true;
                      context.go('/home');
                    },
                    child: const Text('Lewati untuk sekarang', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: 'Ketik nama Anda...',
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
                                    leading: CircleAvatar(
                                      backgroundColor: _kGold.withValues(alpha: 0.15),
                                      child: Icon(o['jenis_kelamin'] == 'P' ? Icons.woman_rounded : Icons.man_rounded, color: _kGreen1),
                                    ),
                                    title: Text(o['name'] as String),
                                    subtitle: Text('Sundut ${o['sundut']}${punguan.isNotEmpty ? ' • $punguan' : ''}'),
                                    trailing: _submitting
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                        : const Icon(Icons.chevron_right),
                                    onTap: _submitting ? null : () => _klaim(o),
                                  );
                                },
                              ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _submitting ? null : () => context.push('/klaim/orang-baru'),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Nama saya tidak ada, ajukan sebagai orang baru'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
