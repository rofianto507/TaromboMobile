import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/error/exceptions.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

const _kategori = <(String, String, IconData)>[
  ('umum', 'Masukan umum', Icons.lightbulb_outline_rounded),
  ('konten', 'Laporkan konten atau pengguna', Icons.flag_outlined),
  ('anak', 'Keselamatan anak', Icons.child_care_rounded),
  ('teknis', 'Gangguan teknis', Icons.bug_report_outlined),
];

/// Formulir masukan dan laporan di dalam aplikasi — pengguna tidak perlu
/// keluar dari aplikasi. Diterima pengurus lewat panel web.
class MasukanScreen extends ConsumerStatefulWidget {
  const MasukanScreen({super.key});

  @override
  ConsumerState<MasukanScreen> createState() => _MasukanScreenState();
}

class _MasukanScreenState extends ConsumerState<MasukanScreen> {
  final _isi = TextEditingController();
  String _kode = 'umum';
  bool _mengirim = false;

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    final teks = _isi.text.trim();
    if (teks.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tuliskan masukan Anda (minimal 5 huruf).'),
        ),
      );
      return;
    }
    setState(() => _mengirim = true);
    try {
      String? versi;
      try {
        final info = await PackageInfo.fromPlatform();
        versi = '${info.version} (${info.buildNumber})';
      } catch (_) {
        versi = null;
      }
      await ref
          .read(apiClientProvider)
          .callKw(
            model: 'tarombo.masukan',
            method: 'kirim_masukan',
            args: [_kode, teks, versi ?? false],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Terima kasih, masukan Anda sudah terkirim ke pengurus.',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ServerException
                ? e.message
                : 'Gagal mengirim. Periksa koneksi Anda lalu coba lagi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kirim Masukan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Sampaikan masukan, laporan konten, atau hal yang mengkhawatirkan '
            'langsung dari sini. Pengurus akan meninjaunya.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.45),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kategori',
            style: TextStyle(fontWeight: FontWeight.w700, color: _kGreen1),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (kode, label, ikon) in _kategori)
                ChoiceChip(
                  avatar: Icon(ikon, size: 18, color: _kGreen1),
                  label: Text(label),
                  selected: _kode == kode,
                  selectedColor: _kGold.withValues(alpha: 0.25),
                  onSelected: (_) => setState(() => _kode = kode),
                ),
            ],
          ),
          if (_kode == 'anak') ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Laporan keselamatan anak ditangani sebagai prioritas. '
                'Jangan menyertakan foto atau materi yang membahayakan anak; '
                'cukup jelaskan di mana Anda menemukannya.',
                style: TextStyle(color: Colors.red.shade900, fontSize: 12.5),
              ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _isi,
            maxLines: 7,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Isi masukan',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _mengirim ? null : _kirim,
            style: FilledButton.styleFrom(
              backgroundColor: _kGreen1,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _mengirim
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded),
            label: const Text('Kirim'),
          ),
        ],
      ),
    );
  }
}
