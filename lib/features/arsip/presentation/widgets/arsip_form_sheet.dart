import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/arsip_labels.dart';
import '../../../../shared/widgets/orang_search_sheet.dart';
import '../providers/arsip_provider.dart';

const _kGreen1 = Color(0xFF2E5339);

// Berkas dikirim sebagai base64 lewat JSON-RPC — batasi ukuran supaya tidak
// menghabiskan memori / membuat request timeout di jaringan seluler.
const _kMaksBytes = 15 * 1024 * 1024;

/// Bottom sheet tambah arsip ke profil sendiri. Mengembalikan true bila tersimpan.
Future<bool> showArsipFormSheet(BuildContext context, int orangId) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _ArsipForm(orangId: orangId),
  );
  return ok == true;
}

String _tebakJenis(String namaBerkas) {
  final ext = namaBerkas.contains('.')
      ? namaBerkas.split('.').last.toLowerCase()
      : '';
  if (const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic'].contains(ext)) {
    return 'foto';
  }
  if (const ['mp3', 'm4a', 'wav', 'aac', 'ogg'].contains(ext)) return 'audio';
  if (const ['mp4', 'mov', 'mkv', 'avi', '3gp', 'webm'].contains(ext)) {
    return 'video';
  }
  return 'dokumen';
}

String _tanpaEkstensi(String nama) {
  final i = nama.lastIndexOf('.');
  return i > 0 ? nama.substring(0, i) : nama;
}

String _ukuran(int bytes) => bytes >= 1024 * 1024
    ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB'
    : '${(bytes / 1024).toStringAsFixed(0)} KB';

class _ArsipForm extends ConsumerStatefulWidget {
  final int orangId;
  const _ArsipForm({required this.orangId});

  @override
  ConsumerState<_ArsipForm> createState() => _ArsipFormState();
}

class _ArsipFormState extends ConsumerState<_ArsipForm> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _tahun = TextEditingController();
  final _sumber = TextEditingController();
  final _keterangan = TextEditingController();
  PlatformFile? _berkas;
  // Anggota lain yang ikut ditautkan; profil sendiri selalu ikut dan tidak bisa dilepas.
  final List<Map<String, dynamic>> _terkait = [];
  String _jenis = 'dokumen';
  bool _publik = true;
  bool _saving = false;
  String? _errorBerkas;

  @override
  void dispose() {
    _nama.dispose();
    _tahun.dispose();
    _sumber.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _pilihBerkas() async {
    final hasil = await FilePicker.platform.pickFiles(withData: true);
    final f = hasil?.files.single;
    if (f == null) return;
    if (f.bytes == null) {
      setState(() => _errorBerkas = 'Berkas tidak dapat dibaca.');
      return;
    }
    if (f.size > _kMaksBytes) {
      setState(
        () => _errorBerkas =
            'Ukuran berkas ${_ukuran(f.size)} melebihi batas ${_ukuran(_kMaksBytes)}.',
      );
      return;
    }
    setState(() {
      _berkas = f;
      _errorBerkas = null;
      _jenis = _tebakJenis(f.name);
      if (_nama.text.trim().isEmpty) _nama.text = _tanpaEkstensi(f.name);
    });
  }

  Future<void> _tambahTerkait() async {
    final dipilih = await showOrangSearchSheet(
      context,
      ref,
      title: 'Tautkan Anggota',
    );
    if (dipilih == null) return;
    final id = dipilih['id'] as int;
    if (id == widget.orangId || _terkait.any((o) => o['id'] == id)) return;
    setState(() => _terkait.add(dipilih));
  }

  Future<void> _simpan() async {
    if (_berkas == null) {
      setState(() => _errorBerkas = 'Pilih berkas terlebih dahulu.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(arsipRepositoryProvider)
          .tambah(
            orangId: widget.orangId,
            orangIds: [for (final o in _terkait) o['id'] as int],
            nama: _nama.text.trim(),
            jenis: _jenis,
            berkasBase64: base64Encode(_berkas!.bytes!),
            berkasNama: _berkas!.name,
            tahunPerkiraan: _tahun.text.trim(),
            sumber: _sumber.text.trim(),
            keterangan: _keterangan.text.trim(),
            publik: _publik,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    isDense: true,
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tambah Arsip',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kGreen1,
                ),
              ),
              const SizedBox(height: 16),
              // Tampil sebagai kolom isian (sama dengan field lain); ketuk untuk memilih.
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: _saving ? null : _pilihBerkas,
                child: InputDecorator(
                  decoration: _dec('Berkas *').copyWith(
                    errorText: _errorBerkas,
                    errorMaxLines: 3,
                    suffixIcon: Icon(
                      _berkas == null
                          ? Icons.attach_file_rounded
                          : jenisArsipIcon(_jenis),
                      color: _kGreen1,
                    ),
                  ),
                  child: Text(
                    _berkas == null
                        ? 'Ketuk untuk memilih berkas'
                        : '${_berkas!.name} (${_ukuran(_berkas!.size)})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _berkas == null ? Colors.grey.shade600 : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nama,
                decoration: _dec('Nama arsip *'),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _jenis,
                key: ValueKey(_jenis),
                decoration: _dec('Jenis'),
                items: [
                  for (final e in jenisArsipLabels.entries)
                    DropdownMenuItem(value: e.key, child: Text(e.value)),
                ],
                onChanged: (v) => setState(() => _jenis = v ?? _jenis),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tahun,
                decoration: _dec('Tahun (perkiraan)'),
              ),
              const SizedBox(height: 12),
              TextFormField(controller: _sumber, decoration: _dec('Sumber')),
              const SizedBox(height: 12),
              TextFormField(
                controller: _keterangan,
                decoration: _dec('Keterangan'),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: _dec('Orang terkait'),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    const Chip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(
                        Icons.person_rounded,
                        size: 18,
                        color: _kGreen1,
                      ),
                      label: Text('Profil Anda'),
                    ),
                    for (final o in _terkait)
                      InputChip(
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        label: Text(o['name'] as String),
                        onDeleted: _saving
                            ? null
                            : () => setState(() => _terkait.remove(o)),
                      ),
                    ActionChip(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      avatar: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Tautkan anggota'),
                      onPressed: _saving ? null : _tambahTerkait,
                    ),
                  ],
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Boleh dilihat seluruh anggota'),
                subtitle: const Text(
                  'Matikan bila arsip ini hanya untuk Anda dan pengurus',
                ),
                value: _publik,
                onChanged: (v) => setState(() => _publik = v),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _saving ? null : _simpan,
                style: FilledButton.styleFrom(
                  backgroundColor: _kGreen1,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _saving
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
      ),
    );
  }
}
