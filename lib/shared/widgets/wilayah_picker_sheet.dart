import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profil_saya/domain/entities/profil_saya.dart';

const _kGreen1 = Color(0xFF2E5339);

/// Bottom sheet pencarian satu tingkat wilayah (tarombo.wilayah).
/// [tingkat]: '1' provinsi, '2' kabupaten/kota, '3' kecamatan, '4' desa.
/// [indukId] membatasi ke anak wilayah itu (mis. kabupaten dalam satu provinsi).
/// Mengembalikan wilayah yang dipilih, atau null bila dibatalkan.
Future<WilayahRef?> showWilayahPicker(
  BuildContext context, {
  required String tingkat,
  required String judul,
  int? indukId,
}) {
  return showModalBottomSheet<WilayahRef>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _WilayahPicker(tingkat: tingkat, judul: judul, indukId: indukId),
  );
}

class _WilayahPicker extends ConsumerStatefulWidget {
  final String tingkat;
  final String judul;
  final int? indukId;
  const _WilayahPicker({required this.tingkat, required this.judul, this.indukId});

  @override
  ConsumerState<_WilayahPicker> createState() => _WilayahPickerState();
}

class _WilayahPickerState extends ConsumerState<_WilayahPicker> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  List<WilayahRef> _hasil = const [];
  bool _loading = true;
  String? _error;
  int _permintaan = 0;

  // Daftar desa/kecamatan nasional terlalu panjang untuk ditampilkan utuh —
  // batasi dan minta pengguna mengetik untuk mempersempit.
  static const _batas = 80;

  @override
  void initState() {
    super.initState();
    _cari('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _cari(q));
  }

  Future<void> _cari(String q) async {
    final nomor = ++_permintaan;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows =
          await ref.read(apiClientProvider).callKw(
                model: 'tarombo.wilayah',
                method: 'search_read',
                args: [
                  [
                    ['tingkat', '=', widget.tingkat],
                    if (widget.indukId != null) ['induk_id', '=', widget.indukId],
                    if (q.trim().isNotEmpty) ['name', 'ilike', q.trim()],
                  ],
                ],
                kwargs: {
                  'fields': ['id', 'name'],
                  'order': 'name',
                  'limit': _batas,
                },
              )
              as List;
      // Abaikan jawaban dari ketikan yang sudah usang.
      if (!mounted || nomor != _permintaan) return;
      setState(() {
        _hasil = [
          for (final r in rows) WilayahRef((r as Map)['id'] as int, r['name'] as String),
        ];
        _loading = false;
      });
    } catch (_) {
      if (!mounted || nomor != _permintaan) return;
      setState(() {
        _error = 'Gagal memuat data. Periksa koneksi Anda.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.judul,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kGreen1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _ctrl,
                    autofocus: widget.tingkat != '1',
                    onChanged: _onChanged,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      hintText: 'Ketik nama untuk mencari',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(child: Text(_error!, textAlign: TextAlign.center))
                  : _hasil.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ditemukan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _hasil.length + (_hasil.length >= _batas ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _hasil.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Menampilkan sebagian. Ketik nama untuk mempersempit.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          );
                        }
                        final w = _hasil[i];
                        return ListTile(
                          title: Text(w.name),
                          onTap: () => Navigator.of(context).pop(w),
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
