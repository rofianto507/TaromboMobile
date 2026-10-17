import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

/// Atur atau ganti kata sandi. Akun yang dibuat lewat Google belum punya kata
/// sandi; dengan mengaturnya, pengguna juga bisa masuk memakai email dan kata
/// sandi (mis. di iPhone yang tidak menyediakan login Google).
class AturSandiScreen extends ConsumerStatefulWidget {
  const AturSandiScreen({super.key});

  @override
  ConsumerState<AturSandiScreen> createState() => _AturSandiScreenState();
}

class _AturSandiScreenState extends ConsumerState<AturSandiScreen> {
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _ulangi = TextEditingController();
  bool? _sudahPunya; // null = sedang dicek
  bool _lihat = false;
  bool _menyimpan = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _cekStatus();
  }

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _ulangi.dispose();
    super.dispose();
  }

  Future<Map?> _panggil(String path, Map<String, dynamic> params) async {
    final res = await ref
        .read(apiClientProvider)
        .dio
        .post(
          path,
          data: {'jsonrpc': '2.0', 'method': 'call', 'params': params},
        );
    final body = res.data as Map;
    return body['result'] as Map?;
  }

  Future<void> _cekStatus() async {
    try {
      final r = await _panggil('/tarombo/mobile/status_sandi', {});
      if (!mounted) return;
      setState(() => _sudahPunya = r?['sudah_punya'] == true);
    } catch (_) {
      if (!mounted) return;
      // Gagal mengecek: anggap sudah punya (meminta sandi lama lebih aman).
      setState(() => _sudahPunya = true);
    }
  }

  Future<void> _simpan() async {
    final lama = _lama.text;
    final baru = _baru.text;
    if (_sudahPunya == true && lama.isEmpty) {
      setState(() => _galat = 'Isi kata sandi lama Anda.');
      return;
    }
    if (baru.length < 8) {
      setState(() => _galat = 'Kata sandi baru minimal 8 karakter.');
      return;
    }
    if (baru != _ulangi.text) {
      setState(() => _galat = 'Pengulangan kata sandi tidak sama.');
      return;
    }
    setState(() {
      _menyimpan = true;
      _galat = null;
    });
    try {
      final r = await _panggil('/tarombo/mobile/atur_sandi', {
        'password_baru': baru,
        if (_sudahPunya == true) 'password_lama': lama,
      });
      if (!mounted) return;
      if (r?['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kata sandi berhasil disimpan.')),
        );
        context.pop();
      } else {
        setState(() {
          _menyimpan = false;
          _galat = (r?['error'] as String?) ?? 'Gagal menyimpan kata sandi.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _galat = 'Gagal menyimpan. Periksa koneksi Anda lalu coba lagi.';
      });
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    border: const OutlineInputBorder(),
    isDense: true,
    suffixIcon: IconButton(
      icon: Icon(
        _lihat ? Icons.visibility_off_outlined : Icons.visibility_outlined,
      ),
      onPressed: () => setState(() => _lihat = !_lihat),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final punya = _sudahPunya;
    return Scaffold(
      appBar: AppBar(
        title: Text(punya == false ? 'Atur Kata Sandi' : 'Ganti Kata Sandi'),
      ),
      body: punya == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _kGold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    punya
                        ? 'Masukkan kata sandi lama, lalu pilih kata sandi baru.'
                        : 'Akun Anda masuk lewat Google dan belum punya kata sandi. '
                              'Dengan membuatnya, Anda juga bisa masuk memakai email '
                              'dan kata sandi, misalnya di perangkat yang tidak '
                              'menyediakan login Google.',
                    style: const TextStyle(height: 1.45, fontSize: 13.5),
                  ),
                ),
                const SizedBox(height: 18),
                if (punya) ...[
                  TextField(
                    controller: _lama,
                    obscureText: !_lihat,
                    decoration: _dec('Kata sandi lama'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _baru,
                  obscureText: !_lihat,
                  decoration: _dec('Kata sandi baru (minimal 8 karakter)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ulangi,
                  obscureText: !_lihat,
                  decoration: _dec('Ulangi kata sandi baru'),
                ),
                if (_galat != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _galat!,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _menyimpan ? null : _simpan,
                  style: FilledButton.styleFrom(
                    backgroundColor: _kGreen1,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _menyimpan
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
    );
  }
}
