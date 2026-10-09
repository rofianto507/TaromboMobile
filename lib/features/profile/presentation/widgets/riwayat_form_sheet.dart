import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/orang_labels.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

const _kGreen1 = Color(0xFF2E5339);

/// Bottom sheet tambah riwayat pendidikan. Mengembalikan true bila tersimpan.
Future<bool> showPendidikanFormSheet(BuildContext context, int orangId) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PendidikanForm(orangId: orangId),
  );
  return ok == true;
}

/// Bottom sheet tambah riwayat pekerjaan. Mengembalikan true bila tersimpan.
Future<bool> showPekerjaanFormSheet(BuildContext context, int orangId) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _PekerjaanForm(orangId: orangId),
  );
  return ok == true;
}

String? _validasiTahun(String? v) {
  if (v == null || v.trim().isEmpty) return null;
  final n = int.tryParse(v.trim());
  final maks = DateTime.now().year + 10;
  if (n == null || n < 1900 || n > maks) return 'Tahun tidak valid';
  return null;
}

int? _tahunAtauNull(String v) => int.tryParse(v.trim());

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool saving;
  final VoidCallback onSimpan;
  const _SheetFrame({
    required this.title,
    required this.children,
    required this.saving,
    required this.onSimpan,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kGreen1,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
            const SizedBox(height: 8),
            FilledButton(
              onPressed: saving ? null : onSimpan,
              style: FilledButton.styleFrom(
                backgroundColor: _kGreen1,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _dec(String label) => InputDecoration(
  labelText: label,
  border: const OutlineInputBorder(),
  isDense: true,
);

// ── Pendidikan ───────────────────────────────────────────────────────────

class _PendidikanForm extends ConsumerStatefulWidget {
  final int orangId;
  const _PendidikanForm({required this.orangId});

  @override
  ConsumerState<_PendidikanForm> createState() => _PendidikanFormState();
}

class _PendidikanFormState extends ConsumerState<_PendidikanForm> {
  final _formKey = GlobalKey<FormState>();
  final _institusi = TextEditingController();
  final _jurusan = TextEditingController();
  final _masuk = TextEditingController();
  final _lulusTahun = TextEditingController();
  String? _jenjang;
  bool _lulus = true;
  bool _saving = false;

  @override
  void dispose() {
    _institusi.dispose();
    _jurusan.dispose();
    _masuk.dispose();
    _lulusTahun.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final masuk = _tahunAtauNull(_masuk.text);
    final lulusTahun = _lulus ? _tahunAtauNull(_lulusTahun.text) : null;
    if (masuk != null && lulusTahun != null && lulusTahun < masuk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tahun lulus tidak boleh sebelum tahun masuk.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(riwayatRepositoryProvider).tambahPendidikan(widget.orangId, {
        'jenjang': _jenjang,
        'institusi': _institusi.text.trim(),
        if (_jurusan.text.trim().isNotEmpty) 'jurusan': _jurusan.text.trim(),
        'tahun_masuk': masuk ?? 0,
        'tahun_lulus': lulusTahun ?? 0,
        'lulus': _lulus,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _SheetFrame(
        title: 'Tambah Pendidikan',
        saving: _saving,
        onSimpan: _simpan,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _jenjang,
            decoration: _dec('Jenjang *'),
            items: [
              for (final e in jenjangLabels.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _jenjang = v),
            validator: (v) => v == null ? 'Pilih jenjang' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _institusi,
            decoration: _dec('Institusi *'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Institusi wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _jurusan,
            decoration: _dec('Jurusan'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _masuk,
                  decoration: _dec('Tahun masuk'),
                  keyboardType: TextInputType.number,
                  validator: _validasiTahun,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lulusTahun,
                  enabled: _lulus,
                  decoration: _dec('Tahun lulus'),
                  keyboardType: TextInputType.number,
                  validator: _validasiTahun,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sudah lulus'),
            subtitle: const Text('Matikan bila masih menempuh pendidikan'),
            value: _lulus,
            onChanged: (v) => setState(() => _lulus = v),
          ),
        ],
      ),
    );
  }
}

// ── Pekerjaan ────────────────────────────────────────────────────────────

class _PekerjaanForm extends ConsumerStatefulWidget {
  final int orangId;
  const _PekerjaanForm({required this.orangId});

  @override
  ConsumerState<_PekerjaanForm> createState() => _PekerjaanFormState();
}

class _PekerjaanFormState extends ConsumerState<_PekerjaanForm> {
  final _formKey = GlobalKey<FormState>();
  final _jabatan = TextEditingController();
  final _instansi = TextEditingController();
  final _mulai = TextEditingController();
  final _selesai = TextEditingController();
  List<Map<String, dynamic>> _bidangList = const [];
  int? _bidangId;
  bool _sekarang = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _muatBidang();
  }

  @override
  void dispose() {
    _jabatan.dispose();
    _instansi.dispose();
    _mulai.dispose();
    _selesai.dispose();
    super.dispose();
  }

  Future<void> _muatBidang() async {
    try {
      // tarombo.bidang dikelola pengurus (menu Konfigurasi) — selalu ambil dari server.
      final rows =
          await ref.read(apiClientProvider).callKw(
                model: 'tarombo.bidang',
                method: 'search_read',
                args: [[]],
                kwargs: {'fields': ['id', 'name'], 'order': 'name'},
              )
              as List;
      if (mounted) {
        setState(() => _bidangList = rows.cast<Map<String, dynamic>>());
      }
    } catch (_) {
      // Non-fatal: bidang opsional, form tetap bisa disimpan.
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    final mulai = _tahunAtauNull(_mulai.text);
    final selesai = _sekarang ? null : _tahunAtauNull(_selesai.text);
    if (mulai != null && selesai != null && selesai < mulai) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tahun selesai tidak boleh sebelum tahun mulai.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(riwayatRepositoryProvider).tambahPekerjaan(widget.orangId, {
        'jabatan': _jabatan.text.trim(),
        if (_instansi.text.trim().isNotEmpty) 'instansi': _instansi.text.trim(),
        if (_bidangId != null) 'bidang_id': _bidangId,
        'tahun_mulai': mulai ?? 0,
        'tahun_selesai': selesai ?? 0,
        'sekarang': _sekarang,
      });
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: _SheetFrame(
        title: 'Tambah Pekerjaan',
        saving: _saving,
        onSimpan: _simpan,
        children: [
          TextFormField(
            controller: _jabatan,
            decoration: _dec('Jabatan / pekerjaan *'),
            textCapitalization: TextCapitalization.words,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Jabatan wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _instansi,
            decoration: _dec('Instansi / perusahaan'),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _bidangId,
            isExpanded: true,
            decoration: _dec('Bidang'),
            items: [
              for (final b in _bidangList)
                DropdownMenuItem(
                  value: b['id'] as int,
                  child: Text(b['name'] as String),
                ),
            ],
            onChanged: (v) => setState(() => _bidangId = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mulai,
                  decoration: _dec('Tahun mulai'),
                  keyboardType: TextInputType.number,
                  validator: _validasiTahun,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _selesai,
                  enabled: !_sekarang,
                  decoration: _dec('Tahun selesai'),
                  keyboardType: TextInputType.number,
                  validator: _validasiTahun,
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Masih berjalan'),
            value: _sekarang,
            onChanged: (v) => setState(() => _sekarang = v),
          ),
        ],
      ),
    );
  }
}
