import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/utils/debouncer.dart';
import '../../../../shared/utils/orang_format.dart';
import '../../../../shared/widgets/orang_list_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/klaim_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

class KlaimSearchScreen extends ConsumerStatefulWidget {
  const KlaimSearchScreen({super.key});

  @override
  ConsumerState<KlaimSearchScreen> createState() => _KlaimSearchScreenState();
}

class _KlaimSearchScreenState extends ConsumerState<KlaimSearchScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _loading = false;
  // id orang yang sedang dikirim; spinner hanya tampil di baris ini.
  int? _mengirimId;
  bool get _submitting => _mengirimId != null;
  String? _error;

  final _debounce = Debouncer(kJedaCari);
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
                // Semua anggota ditampilkan, termasuk yang sudah tertaut ke akun
                // lain (lencana terverifikasi). Yang sudah tertaut hanya bisa
                // diajukan banding, bukan klaim biasa.
                args: [
                  [
                    ['name', 'ilike', q.trim()],
                  ],
                ],
                kwargs: {
                  'fields': kOrangSearchFields,
                  'limit': 20,
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

  /// Banding atas orang yang sudah tertaut ke akun lain. Alasan wajib diisi;
  /// pengurus memeriksa lalu memutuskan.
  Future<void> _banding(Map<String, dynamic> orang) async {
    // Teks alasan dipegang ValueNotifier ringan; TextEditingController-nya
    // dimiliki dan dibuang oleh widget isian itu sendiri. Membuang controller
    // dari sini (saat dialog masih animasi tutup) memicu assertion
    // "_dependents.isEmpty" karena TextField masih memakainya.
    final teksAlasan = ValueNotifier<String>('');
    String? alasan;
    while (alasan == null) {
      final ok = await showAppConfirmDialog(
        context,
        title: 'Ajukan Banding',
        icon: Icons.gavel_rounded,
        confirmLabel: 'Kirim Banding',
        content: _IsianAlasanBanding(
          nama: orang['name'] as String,
          teks: teksAlasan,
        ),
      );
      if (!ok) return;
      final teks = teksAlasan.value.trim();
      if (teks.length >= 10) {
        alasan = teks;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alasan banding wajib diisi (minimal 10 huruf).'),
          ),
        );
      }
    }

    setState(() => _mengirimId = orang['id'] as int);
    try {
      await ref
          .read(klaimNotifierProvider.notifier)
          .ajukanBanding(orangId: orang['id'] as int, alasan: alasan);
      _keStatus('Banding terkirim. Pengurus akan memeriksanya.');
    } catch (e) {
      if (!mounted) return;
      final msg = e is ServerException
          ? e.message
          : 'Gagal mengirim banding. Coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _mengirimId = null);
    }
  }

  /// Setelah pengajuan berhasil: konfirmasi singkat lalu pindah ke halaman
  /// Status Klaim (router sengaja tidak memindahkan otomatis dari rute /klaim).
  void _keStatus(String pesan) {
    if (!mounted) return;
    // Tutup keyboard dulu supaya halaman Status Klaim tidak tampil sempit.
    FocusManager.instance.primaryFocus?.unfocus();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
    context.go('/klaim/pending');
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

    setState(() => _mengirimId = orang['id'] as int);
    try {
      await ref
          .read(klaimNotifierProvider.notifier)
          .ajukanOrangAda(orangId: orang['id'] as int);
      _keStatus('Klaim terkirim. Pengurus akan memeriksanya.');
    } catch (e) {
      if (!mounted) return;
      final msg = e is ServerException
          ? e.message
          : 'Gagal mengirim klaim. Coba lagi.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) setState(() => _mengirimId = null);
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _kGold,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      ref.read(klaimReminderDismissedProvider.notifier).state =
                          true;
                      context.go('/home');
                    },
                    child: const Text(
                      'Lewati untuk sekarang',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
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
              onChanged: _onChanged,
              decoration: InputDecoration(
                hintText: 'Ketik nama Anda...',
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
                      final tertaut = o['terhubung_akun'] == true;
                      return OrangListTile(
                        orang: o,
                        keterangan: tertaut
                            ? 'Sudah terhubung ke akun lain • ketuk untuk banding'
                            : null,
                        trailing: _mengirimId == o['id']
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: _submitting
                            ? null
                            : () => tertaut ? _banding(o) : _klaim(o),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: _submitting
                    ? null
                    : () => context.push('/klaim/orang-baru'),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text(
                  'Nama saya tidak ada, ajukan sebagai orang baru',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Isian alasan banding di dalam dialog. Memiliki dan membuang
/// TextEditingController-nya sendiri sehingga aman terhadap animasi tutup.
class _IsianAlasanBanding extends StatefulWidget {
  final String nama;
  final ValueNotifier<String> teks;
  const _IsianAlasanBanding({required this.nama, required this.teks});

  @override
  State<_IsianAlasanBanding> createState() => _IsianAlasanBandingState();
}

class _IsianAlasanBandingState extends State<_IsianAlasanBanding> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.teks.value,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '"${widget.nama}" sudah terhubung ke akun lain. Bila Anda adalah '
          'orang ini dan akun tersebut keliru, jelaskan alasannya. Pengurus '
          'akan memeriksa; bila disetujui, tautan akun lama dicabut dan nama '
          'ini terhubung ke akun Anda.',
          style: TextStyle(color: Colors.grey.shade700, height: 1.45),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) => widget.teks.value = v,
          decoration: const InputDecoration(
            hintText: 'Mis. saya anak dari ..., akun lain bukan milik saya',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
