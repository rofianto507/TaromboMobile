import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exceptions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/orang_search_sheet.dart';
import '../providers/klaim_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class KlaimOrangBaruScreen extends ConsumerStatefulWidget {
  const KlaimOrangBaruScreen({super.key});

  @override
  ConsumerState<KlaimOrangBaruScreen> createState() => _KlaimOrangBaruScreenState();
}

class _KlaimOrangBaruScreenState extends ConsumerState<KlaimOrangBaruScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController();
  final _sumberCtrl = TextEditingController(text: 'Diajukan sendiri lewat aplikasi mobile saat registrasi akun.');
  final _catatanCtrl = TextEditingController();

  String _jenisKelamin = 'L';
  Map<String, dynamic>? _ayah;
  int? _punguanId;
  List<Map<String, dynamic>> _punguanList = [];
  bool _loadingPunguan = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPunguan();
  }

  Future<void> _loadPunguan() async {
    try {
      final api = ref.read(apiClientProvider);
      final rows = await api.callKw(
        model: 'tarombo.punguan',
        method: 'search_read',
        args: [[]],
        kwargs: {'fields': ['id', 'name'], 'order': 'name', 'limit': 100},
      ) as List;
      setState(() => _punguanList = rows.cast<Map<String, dynamic>>());
    } catch (_) {
      setState(() => _error = 'Gagal memuat daftar punguan. Periksa koneksi Anda.');
    } finally {
      setState(() => _loadingPunguan = false);
    }
  }

  Future<void> _pickAyah() async {
    final result = await showOrangSearchSheet(
      context,
      ref,
      title: 'Pilih Ayah',
      extraDomain: const [
        ['jenis_kelamin', '=', 'L'],
      ],
    );
    if (result != null) setState(() => _ayah = result);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ayah == null) {
      setState(() => _error = 'Pilih ayah terlebih dahulu.');
      return;
    }
    if (_punguanId == null) {
      setState(() => _error = 'Pilih punguan terlebih dahulu.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(klaimNotifierProvider.notifier).ajukanOrangBaru(
        usulanVals: {
          'jenis': 'tambah',
          'punguan_id': _punguanId,
          'ayah_id': _ayah!['id'],
          'usul_nama': _namaCtrl.text.trim(),
          'usul_jenis_kelamin': _jenisKelamin,
          'sumber_ket': _sumberCtrl.text.trim(),
        },
        catatan: _catatanCtrl.text.trim(),
      );
    } catch (e) {
      final msg = e is ServerException ? e.message : 'Gagal mengirim usulan. Coba lagi.';
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _sumberCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajukan Sebagai Orang Baru')),
      body: _loadingPunguan
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Data ini akan menjadi usulan penambahan data baru sekaligus klaim identitas Anda. '
                      'Keduanya akan ditinjau pengurus.',
                      style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _namaCtrl,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Jenis Kelamin', style: TextStyle(fontWeight: FontWeight.w600)),
                    RadioGroup<String>(
                      groupValue: _jenisKelamin,
                      onChanged: (v) => setState(() => _jenisKelamin = v!),
                      child: Row(
                        children: const [
                          Expanded(child: RadioListTile<String>(value: 'L', title: Text('Laki-laki'))),
                          Expanded(child: RadioListTile<String>(value: 'P', title: Text('Perempuan'))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      tileColor: const Color(0xFFFAF9F5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                      leading: const Icon(Icons.man_rounded, color: _kGreen1),
                      title: Text(_ayah?['name'] as String? ?? 'Pilih Ayah'),
                      subtitle: const Text('Ketuk untuk mencari di pohon keluarga'),
                      trailing: const Icon(Icons.search),
                      onTap: _pickAyah,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _punguanId,
                      decoration: const InputDecoration(labelText: 'Punguan', border: OutlineInputBorder()),
                      items: _punguanList
                          .map((p) => DropdownMenuItem(value: p['id'] as int, child: Text(p['name'] as String)))
                          .toList(),
                      onChanged: (v) => setState(() => _punguanId = v),
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sumberCtrl,
                      decoration: const InputDecoration(labelText: 'Sumber Keterangan', border: OutlineInputBorder()),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _catatanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan Tambahan (opsional)',
                        hintText: 'Mis. "Saya anak dari ... sundut ..."',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: _kGold, foregroundColor: _kGreen1, padding: const EdgeInsets.symmetric(vertical: 16)),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : const Text('Ajukan', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
