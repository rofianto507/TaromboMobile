import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../../shared/widgets/lokasi_picker_screen.dart';
import '../../../../shared/widgets/orang_search_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/usulan_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

enum _Mode { tambah, edit }

class UsulanFormScreen extends ConsumerStatefulWidget {
  // Dipakai tombol "Perbarui Data Saya" di halaman profil sendiri — target
  // sudah pasti diri sendiri, jadi langsung dikunci ke mode edit tanpa
  // lewat pencarian lagi (lihat _modeTerkunci).
  final int? initialTargetId;
  final String? initialTargetName;
  const UsulanFormScreen({
    super.key,
    this.initialTargetId,
    this.initialTargetName,
  });

  @override
  ConsumerState<UsulanFormScreen> createState() => _UsulanFormScreenState();
}

class _UsulanFormScreenState extends ConsumerState<UsulanFormScreen> {
  final _formKey = GlobalKey<FormState>();
  _Mode _mode = _Mode.tambah;

  // Tambah
  final _namaCtrl = TextEditingController();
  String _jenisKelamin = 'L';
  Map<String, dynamic>? _ayah;

  // Edit (koreksi/lengkapi)
  Map<String, dynamic>? _target;
  bool _loadingTarget = false;
  String? _masihHidup; // null = tidak diubah, 'ya'/'tidak'
  int? _urutan;
  final _suamiNamaCtrl = TextEditingController();
  int? _suamiMargaId;
  List<Map<String, dynamic>> _margaList = [];
  DateTime? _tanggalWafat; // cuma relevan kalau _masihHidup == 'tidak'

  // Tanggal lahir — dipakai baik mode Tambah maupun Edit, boleh hanya tahu
  // tahunnya saja (isi 1 Januari tahun itu, lihat konvensi di backend).
  DateTime? _tanggalLahir;

  // Alamat & titik lokasi (opsional, berlaku untuk mode Tambah maupun Edit)
  final _alamatCtrl = TextEditingController();
  LatLng? _titikLokasi;

  // Bersama
  int? _punguanId;
  List<Map<String, dynamic>> _punguanList = [];
  final _sumberCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  String? _fotoBase64;
  bool _loadingLookup = true;
  bool _submitting = false;
  String? _error;

  bool get _modeTerkunci => widget.initialTargetId != null;

  @override
  void initState() {
    super.initState();
    _loadLookups();
    if (widget.initialTargetId != null) {
      _mode = _Mode.edit;
      _muatDataTarget({
        'id': widget.initialTargetId,
        'name': widget.initialTargetName ?? '',
      });
    }
  }

  Future<void> _loadLookups() async {
    try {
      final api = ref.read(apiClientProvider);
      final results = await Future.wait([
        api.callKw(
          model: 'tarombo.punguan',
          method: 'search_read',
          args: [[]],
          kwargs: {
            'fields': ['id', 'name'],
            'order': 'name',
            'limit': 100,
          },
        ),
        api.callKw(
          model: 'tarombo.marga',
          method: 'search_read',
          args: [[]],
          kwargs: {
            'fields': ['id', 'name'],
            'order': 'name',
            'limit': 200,
          },
        ),
      ]);
      setState(() {
        _punguanList = (results[0] as List).cast<Map<String, dynamic>>();
        _margaList = (results[1] as List).cast<Map<String, dynamic>>();
      });
    } catch (_) {
      setState(
        () => _error = 'Gagal memuat data referensi. Periksa koneksi Anda.',
      );
    } finally {
      setState(() => _loadingLookup = false);
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

  Future<void> _pickTarget() async {
    final result = await showOrangSearchSheet(
      context,
      ref,
      title: 'Pilih Orang yang Dikoreksi/Dilengkapi',
    );
    if (result == null) return;
    await _muatDataTarget(result);
  }

  Future<void> _muatDataTarget(Map<String, dynamic> target) async {
    setState(() {
      _target = target;
      _loadingTarget = true;
    });
    try {
      final api = ref.read(apiClientProvider);
      final rows =
          await api.callKw(
                model: 'tarombo.orang',
                method: 'search_read',
                args: [
                  [
                    ['id', '=', target['id']],
                  ],
                ],
                kwargs: {
                  'fields': [
                    'jenis_kelamin',
                    'masih_hidup',
                    'urutan',
                    'suami_nama',
                    'suami_marga_id',
                    'punguan_id',
                  ],
                },
              )
              as List;
      if (rows.isNotEmpty) {
        final r = rows.first as Map<String, dynamic>;
        setState(() {
          _jenisKelamin = r['jenis_kelamin'] as String;
          _urutan = r['urutan'] as int;
          _suamiNamaCtrl.text = asOdooString(r['suami_nama']) ?? '';
          _suamiMargaId = (r['suami_marga_id'] is List)
              ? r['suami_marga_id'][0] as int
              : null;
          _punguanId = (r['punguan_id'] is List)
              ? r['punguan_id'][0] as int
              : null;
        });
      }
    } catch (_) {
      setState(() => _error = 'Gagal memuat data orang. Periksa koneksi Anda.');
    } finally {
      setState(() => _loadingTarget = false);
    }
  }

  Future<void> _pickLokasi() async {
    final hasil = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LokasiPickerScreen(titikAwal: _titikLokasi),
      ),
    );
    if (hasil != null) setState(() => _titikLokasi = hasil);
  }

  Future<void> _pickTanggal({required bool wafat}) async {
    final awal = (wafat ? _tanggalWafat : _tanggalLahir) ?? DateTime(1950);
    final hasil = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: DateTime(1800),
      lastDate: DateTime.now(),
      helpText: wafat ? 'Pilih Tanggal Wafat' : 'Pilih Tanggal Lahir',
    );
    if (hasil == null) return;
    setState(() {
      if (wafat) {
        _tanggalWafat = hasil;
      } else {
        _tanggalLahir = hasil;
      }
    });
  }

  Future<void> _pickFoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() => _fotoBase64 = base64Encode(bytes));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mode == _Mode.tambah && _ayah == null) {
      setState(() => _error = 'Pilih ayah terlebih dahulu.');
      return;
    }
    if (_mode == _Mode.edit && _target == null) {
      setState(() => _error = 'Pilih orang yang akan dikoreksi/dilengkapi.');
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
      final service = ref.read(usulanSubmitProvider);
      if (_mode == _Mode.tambah) {
        await service.submitTambah(
          nama: _namaCtrl.text.trim(),
          jenisKelamin: _jenisKelamin,
          ayahId: _ayah!['id'] as int,
          punguanId: _punguanId!,
          sumberKet: _sumberCtrl.text.trim(),
          catatan: _catatanCtrl.text.trim(),
          fotoBase64: _fotoBase64,
          usulAlamatJalan: _alamatCtrl.text.trim(),
          usulLatitude: _titikLokasi?.latitude,
          usulLongitude: _titikLokasi?.longitude,
          usulTanggalLahir: _tanggalLahir == null
              ? null
              : DateFormat('yyyy-MM-dd').format(_tanggalLahir!),
        );
      } else {
        await service.submitEdit(
          jenis: 'koreksi',
          orangId: _target!['id'] as int,
          punguanId: _punguanId!,
          sumberKet: _sumberCtrl.text.trim(),
          usulNama: _namaCtrl.text.trim(),
          usulJenisKelamin: _jenisKelamin,
          usulMasihHidup: _masihHidup,
          usulUrutan: _urutan,
          usulSuamiNama: _jenisKelamin == 'P'
              ? _suamiNamaCtrl.text.trim()
              : null,
          usulSuamiMargaId: _jenisKelamin == 'P' ? _suamiMargaId : null,
          catatan: _catatanCtrl.text.trim(),
          fotoBase64: _fotoBase64,
          usulAlamatJalan: _alamatCtrl.text.trim(),
          usulLatitude: _titikLokasi?.latitude,
          usulLongitude: _titikLokasi?.longitude,
          usulTanggalLahir: _tanggalLahir == null
              ? null
              : DateFormat('yyyy-MM-dd').format(_tanggalLahir!),
          usulTanggalWafat: (_masihHidup == 'tidak' && _tanggalWafat != null)
              ? DateFormat('yyyy-MM-dd').format(_tanggalWafat!)
              : null,
        );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      setState(
        () => _error = e is ServerException
            ? e.message
            : 'Gagal mengirim usulan. Coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _suamiNamaCtrl.dispose();
    _sumberCtrl.dispose();
    _catatanCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modeTerkunci ? 'Perbarui Profil Saya' : 'Usulan Baru'),
      ),
      body: _loadingLookup
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_modeTerkunci) ...[
                      SegmentedButton<_Mode>(
                        segments: const [
                          ButtonSegment(
                            value: _Mode.tambah,
                            label: Text('Tambah Baru'),
                            icon: Icon(Icons.person_add_alt_1_outlined),
                          ),
                          ButtonSegment(
                            value: _Mode.edit,
                            label: Text('Perbarui Data'),
                            icon: Icon(Icons.edit_note_rounded),
                          ),
                        ],
                        selected: {_mode},
                        onSelectionChanged: (s) => setState(() {
                          _mode = s.first;
                          _error = null;
                        }),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_mode == _Mode.tambah)
                      ..._buildTambahFields()
                    else
                      ..._buildEditFields(),
                    const Divider(height: 32),
                    DropdownButtonFormField<int>(
                      initialValue: _punguanId,
                      decoration: const InputDecoration(
                        labelText: 'Punguan',
                        border: OutlineInputBorder(),
                      ),
                      items: _punguanList
                          .map(
                            (p) => DropdownMenuItem(
                              value: p['id'] as int,
                              child: Text(p['name'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _punguanId = v),
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _sumberCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Sumber Keterangan',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alamatCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Lengkap (opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildLokasiPicker(),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _catatanCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Catatan (opsional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildFotoPicker(),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kGold,
                        foregroundColor: _kGreen1,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Ajukan Usulan',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildTambahFields() {
    return [
      TextFormField(
        controller: _namaCtrl,
        decoration: const InputDecoration(
          labelText: 'Nama Lengkap',
          border: OutlineInputBorder(),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
      ),
      const SizedBox(height: 16),
      _buildJenisKelaminRadio(),
      const SizedBox(height: 8),
      _buildTanggalPicker(wafat: false, label: 'Tanggal Lahir'),
      const SizedBox(height: 16),
      ListTile(
        contentPadding: EdgeInsets.zero,
        tileColor: const Color(0xFFFAF9F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        leading: const Icon(Icons.man_rounded, color: _kGreen1),
        title: Text(_ayah?['name'] as String? ?? 'Pilih Ayah'),
        subtitle: const Text('Ketuk untuk mencari di pohon keluarga'),
        trailing: const Icon(Icons.search),
        onTap: _pickAyah,
      ),
    ];
  }

  List<Widget> _buildEditFields() {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        tileColor: const Color(0xFFFAF9F5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        leading: Icon(
          _modeTerkunci ? Icons.badge_outlined : Icons.person_search_rounded,
          color: _kGreen1,
        ),
        title: Text(_target?['name'] as String? ?? 'Pilih Orang'),
        subtitle: Text(
          _modeTerkunci
              ? 'Memperbarui profil Anda sendiri'
              : 'Ketuk untuk mencari di pohon keluarga',
        ),
        trailing: _modeTerkunci
            ? null
            : (_loadingTarget
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search)),
        onTap: (_modeTerkunci || _loadingTarget) ? null : _pickTarget,
      ),
      if (_target != null) ...[
        const SizedBox(height: 16),
        TextFormField(
          controller: _namaCtrl,
          decoration: const InputDecoration(
            labelText: 'Nama Baru (opsional, kosongkan jika tidak berubah)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        _buildJenisKelaminRadio(),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: _masihHidup,
          decoration: const InputDecoration(
            labelText: 'Masih Hidup?',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('(Tidak diubah)')),
            DropdownMenuItem(value: 'ya', child: Text('Ya')),
            DropdownMenuItem(value: 'tidak', child: Text('Tidak')),
          ],
          onChanged: (v) => setState(() => _masihHidup = v),
        ),
        const SizedBox(height: 16),
        _buildTanggalPicker(wafat: false, label: 'Tanggal Lahir'),
        if (_masihHidup == 'tidak') ...[
          const SizedBox(height: 16),
          _buildTanggalPicker(wafat: true, label: 'Tanggal Wafat'),
        ],
        const SizedBox(height: 16),
        TextFormField(
          initialValue: _urutan?.toString(),
          decoration: const InputDecoration(
            labelText: 'Anak ke-',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (v) => _urutan = int.tryParse(v),
        ),
        if (_jenisKelamin == 'P') ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _suamiNamaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama Suami',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int?>(
            initialValue: _suamiMargaId,
            decoration: const InputDecoration(
              labelText: 'Marga Suami',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('(Tidak diubah)'),
              ),
              ..._margaList.map(
                (m) => DropdownMenuItem(
                  value: m['id'] as int,
                  child: Text(m['name'] as String),
                ),
              ),
            ],
            onChanged: (v) => setState(() => _suamiMargaId = v),
          ),
        ],
      ],
    ];
  }

  Widget _buildJenisKelaminRadio() {
    return RadioGroup<String>(
      groupValue: _jenisKelamin,
      onChanged: (v) => setState(() => _jenisKelamin = v!),
      child: Row(
        children: const [
          Expanded(
            child: RadioListTile<String>(value: 'L', title: Text('Laki-laki')),
          ),
          Expanded(
            child: RadioListTile<String>(value: 'P', title: Text('Perempuan')),
          ),
        ],
      ),
    );
  }

  Widget _buildTanggalPicker({required bool wafat, required String label}) {
    final nilai = wafat ? _tanggalWafat : _tanggalLahir;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: const Color(0xFFFAF9F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      leading: Icon(
        wafat ? Icons.church_outlined : Icons.cake_outlined,
        color: nilai != null ? _kGreen1 : Colors.grey.shade500,
      ),
      title: Text(
        nilai != null
            ? DateFormat('d MMMM yyyy', 'id_ID').format(nilai)
            : label,
      ),
      subtitle: Text(
        nilai != null
            ? label
            : 'Ketuk untuk pilih tanggal (boleh cuma tahunnya saja)',
      ),
      trailing: nilai != null
          ? IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.grey.shade500,
              ),
              onPressed: () => setState(() {
                if (wafat) {
                  _tanggalWafat = null;
                } else {
                  _tanggalLahir = null;
                }
              }),
            )
          : const Icon(Icons.calendar_month_outlined),
      onTap: () => _pickTanggal(wafat: wafat),
    );
  }

  Widget _buildLokasiPicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      tileColor: const Color(0xFFFAF9F5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      leading: Icon(
        Icons.pin_drop_outlined,
        color: _titikLokasi != null ? _kGreen1 : Colors.grey.shade500,
      ),
      title: Text(
        _titikLokasi != null
            ? '${_titikLokasi!.latitude.toStringAsFixed(5)}, ${_titikLokasi!.longitude.toStringAsFixed(5)}'
            : 'Titik lokasi belum dipilih (opsional)',
      ),
      subtitle: const Text('Ketuk untuk pilih titik di peta'),
      trailing: _titikLokasi != null
          ? IconButton(
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: Colors.grey.shade500,
              ),
              onPressed: () => setState(() => _titikLokasi = null),
            )
          : const Icon(Icons.map_outlined),
      onTap: _pickLokasi,
    );
  }

  Widget _buildFotoPicker() {
    return GestureDetector(
      onTap: _pickFoto,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kGold.withValues(alpha: 0.12),
                border: Border.all(color: _kGold.withValues(alpha: 0.4)),
              ),
              child: _fotoBase64 != null
                  ? ClipOval(
                      child: Image.memory(
                        base64Decode(_fotoBase64!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Icon(
                      Icons.camera_alt_outlined,
                      color: _kGold,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _fotoBase64 != null
                    ? 'Foto dipilih'
                    : 'Tambahkan foto (opsional)',
                style: TextStyle(
                  color: _fotoBase64 != null
                      ? _kGreen1
                      : const Color(0xFF888888),
                  fontSize: 14,
                ),
              ),
            ),
            if (_fotoBase64 != null)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                onPressed: () => setState(() => _fotoBase64 = null),
              ),
          ],
        ),
      ),
    );
  }
}
