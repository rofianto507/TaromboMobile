import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/domain/entities/klaim_info.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../domain/entities/berita.dart';
import '../providers/berita_provider.dart';
import '../widgets/berita_gambar.dart';
import '../widgets/berita_slider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);
const _kLinkPlayStore =
    'https://play.google.com/store/apps/details?id=id.selstudio.tarombo_mobile';

class BeritaDetailScreen extends ConsumerStatefulWidget {
  final int beritaId;
  const BeritaDetailScreen({super.key, required this.beritaId});

  @override
  ConsumerState<BeritaDetailScreen> createState() => _BeritaDetailScreenState();
}

class _BeritaDetailScreenState extends ConsumerState<BeritaDetailScreen> {
  final _ctrl = TextEditingController();
  bool _mengirim = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  /// Unduh gambar sampul (butuh sesi login) ke berkas sementara agar bisa
  /// dilampirkan pada share. Null bila tidak ada gambar atau gagal.
  Future<XFile?> _berkasGambar(BeritaRingkas b) async {
    if (!b.punyaGambar || kIsWeb) return null;
    try {
      final token = await ref
          .read(secureStorageProvider)
          .read(key: AppConstants.tokenKey);
      final res = await Dio().get<List<int>>(
        '${AppConfig.baseUrl}/web/image/tarombo.berita/${b.id}/gambar',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Cookie': 'session_id=$token'},
        ),
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/tarombo_berita_${b.id}.jpg');
      await f.writeAsBytes(bytes, flush: true);
      return XFile(f.path, mimeType: 'image/jpeg');
    } catch (_) {
      return null;
    }
  }

  String _teksBagikan(BeritaDetail d) {
    final b = d.ringkas;
    var isi = (b.ringkasan ?? '').trim();
    if (isi.isEmpty) {
      isi = (d.isiHtml ?? '')
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'&nbsp;'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (isi.length > 200) isi = '${isi.substring(0, 200).trimRight()}...';
    }
    return [
      b.judul,
      if (b.agenda && b.tanggalMulai != null)
        'Waktu: ${formatTanggal(b.tanggalMulai!, denganJam: true)}',
      if (b.agenda && b.lokasi != null) 'Lokasi: ${b.lokasi}',
      if (isi.isNotEmpty) '\n$isi',
      // Di iOS tidak menyebut toko/platform lain (pedoman App Review 2.3.10).
      if (Platform.isIOS)
        '\nKabar keluarga dan silsilah marga ada di aplikasi Tarombo.'
      else
        '\nKabar keluarga dan silsilah marga ada di aplikasi Tarombo. '
            'Unduh gratis di Play Store:\n$_kLinkPlayStore',
    ].join('\n');
  }

  bool _membagikan = false;

  Future<void> _bagikan(BeritaDetail d) async {
    if (_membagikan) return;
    setState(() => _membagikan = true);
    try {
      final gambar = await _berkasGambar(d.ringkas);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: _teksBagikan(d),
          subject: d.ringkas.judul,
          files: gambar == null ? null : [gambar],
        ),
      );
    } catch (_) {
      _pesan('Gagal membagikan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _membagikan = false);
    }
  }

  Future<void> _bukaAturan() async {
    await launchUrl(
      Uri.parse('${AppConfig.baseUrl}/aturan-komentar'),
      mode: LaunchMode.externalApplication,
    );
  }

  /// Persetujuan Aturan Komentar, sekali saja sebelum komentar pertama.
  Future<bool> _setujuAturan() async {
    final prefs = ref.read(komentarPrefsProvider);
    if (await prefs.aturanDiterima()) return true;
    if (!mounted) return false;
    final ya = await showAppConfirmDialog(
      context,
      title: 'Aturan Komentar',
      icon: Icons.rule_rounded,
      confirmLabel: 'Setuju dan Lanjut',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gunakan bahasa yang sopan. Dilarang kata kasar, hinaan, '
            'ujaran kebencian atau SARA, spam, membuka data pribadi orang '
            'lain, serta konten yang membahayakan anak. Komentar yang '
            'melanggar dapat dilaporkan dan dihapus pengurus.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.45),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _bukaAturan,
            child: const Text('Baca aturan lengkap'),
          ),
        ],
      ),
    );
    if (ya) await prefs.terimaAturan();
    return ya;
  }

  Future<void> _kirim() async {
    final teks = _ctrl.text.trim();
    if (teks.isEmpty || _mengirim) return;
    if (!await _setujuAturan()) return;
    setState(() => _mengirim = true);
    try {
      await ref.read(beritaAksiProvider).kirimKomentar(widget.beritaId, teks);
      _ctrl.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      _pesan(
        e is ServerException
            ? e.message
            : 'Gagal mengirim komentar. Coba lagi.',
      );
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  Future<void> _hapus(KomentarBerita k) async {
    final ya = await showAppConfirmDialog(
      context,
      title: 'Hapus Komentar?',
      message: 'Komentar Anda akan dihapus.',
      icon: Icons.delete_outline_rounded,
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ya) return;
    try {
      await ref.read(beritaAksiProvider).hapusKomentar(widget.beritaId, k.id);
    } catch (e) {
      _pesan(e is ServerException ? e.message : 'Gagal menghapus komentar.');
    }
  }

  Future<void> _laporkan(KomentarBerita k) async {
    final hasil = await showModalBottomSheet<(String, String?)>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _LembarLaporan(),
    );
    if (hasil == null) return;
    try {
      await ref
          .read(beritaAksiProvider)
          .laporkanKomentar(k.id, hasil.$1, catatan: hasil.$2);
      _pesan('Laporan terkirim. Pengurus akan meninjaunya.');
    } catch (e) {
      _pesan(e is ServerException ? e.message : 'Gagal mengirim laporan.');
    }
  }

  Future<void> _blokir(KomentarBerita k) async {
    final ya = await showAppConfirmDialog(
      context,
      title: 'Blokir ${k.penulis}?',
      message:
          'Komentar dari pengguna ini tidak akan ditampilkan di perangkat '
          'Anda. Anda dapat membukanya kembali kapan saja.',
      icon: Icons.block_rounded,
      confirmLabel: 'Blokir',
      destructive: true,
    );
    if (!ya || k.orangId == null) return;
    await ref.read(komentarPrefsProvider).blokir(k.orangId!);
    _pesan('Pengguna diblokir.');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(beritaDetailProvider(widget.beritaId));
    final blokir = ref.watch(blokirProvider).valueOrNull ?? const <int>{};
    final terverifikasi =
        ref.watch(klaimNotifierProvider).valueOrNull?.status ==
        KlaimStatus.disetujui;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Berita & Agenda'),
        actions: [
          if (async.hasValue)
            IconButton(
              tooltip: 'Bagikan',
              icon: _membagikan
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.share_rounded),
              onPressed: _membagikan ? null : () => _bagikan(async.value!),
            ),
        ],
      ),
      // Kotak komentar ada di dalam body: bottomNavigationBar TIDAK ikut naik
      // di atas keyboard, sedangkan body dikecilkan Scaffold saat keyboard muncul.
      body: Column(
        children: [
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Gagal memuat. Periksa koneksi Anda.',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
              data: (d) => _Isi(
                detail: d,
                terverifikasi: terverifikasi,
                blokir: blokir,
                onHapus: _hapus,
                onLaporkan: _laporkan,
                onBlokir: _blokir,
                onBukaBlokir: () =>
                    ref.read(komentarPrefsProvider).bukaSemuaBlokir(),
              ),
            ),
          ),
          if (async.hasValue)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.zero,
                child: terverifikasi
                    ? _InputKomentar(
                        controller: _ctrl,
                        mengirim: _mengirim,
                        onKirim: _kirim,
                        onAturan: _bukaAturan,
                      )
                    : Container(
                        width: double.infinity,
                        color: const Color(0xFFFAF9F5),
                        padding: const EdgeInsets.all(14),
                        child: Text(
                          'Komentar hanya untuk akun yang sudah terverifikasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Isi extends StatelessWidget {
  final BeritaDetail detail;
  final bool terverifikasi;
  final Set<int> blokir;
  final void Function(KomentarBerita) onHapus;
  final void Function(KomentarBerita) onLaporkan;
  final void Function(KomentarBerita) onBlokir;
  final VoidCallback onBukaBlokir;
  const _Isi({
    required this.detail,
    required this.terverifikasi,
    required this.blokir,
    required this.onHapus,
    required this.onLaporkan,
    required this.onBlokir,
    required this.onBukaBlokir,
  });

  @override
  Widget build(BuildContext context) {
    final b = detail.ringkas;
    final tampil = [
      for (final k in detail.komentar)
        if (k.orangId == null || !blokir.contains(k.orangId)) k,
    ];
    final tersembunyi = detail.komentar.length - tampil.length;
    // Gambar tampil utuh (tinggi mengikuti rasio) dan ikut tergulir. Isi di
    // bawahnya diberi tinggi minimal setinggi layar, sehingga gambar selalu
    // bisa digulir sampai hilang sebelum daftar berhenti.
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        padding: EdgeInsets.zero,
        children: [
          BeritaGambar(
            beritaId: b.id,
            punyaGambar: b.punyaGambar,
            agenda: b.agenda,
            fit: BoxFit.fitWidth,
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabelJenis(item: b),
                      const SizedBox(height: 10),
                      Text(
                        b.judul,
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: _kGreen1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (detail.penulis != null) detail.penulis!,
                          if (b.tanggalTerbit != null)
                            formatTanggal(b.tanggalTerbit!),
                        ].join(' • '),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                        ),
                      ),
                      if (b.agenda) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _kGold.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (b.tanggalMulai != null)
                                _BarisAgenda(
                                  ikon: Icons.event_rounded,
                                  teks: b.tanggalSelesai != null
                                      ? '${formatTanggal(b.tanggalMulai!, denganJam: true)}\n'
                                            's.d. ${formatTanggal(b.tanggalSelesai!, denganJam: true)}'
                                      : formatTanggal(
                                          b.tanggalMulai!,
                                          denganJam: true,
                                        ),
                                ),
                              if (b.lokasi != null)
                                _BarisAgenda(
                                  ikon: Icons.place_rounded,
                                  teks: b.lokasi!,
                                ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if ((detail.isiHtml ?? '').trim().isNotEmpty)
                        Html(
                          data: detail.isiHtml!,
                          style: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              fontSize: FontSize(15),
                              lineHeight: const LineHeight(1.55),
                            ),
                            'img': Style(width: Width(100, Unit.percent)),
                          },
                        )
                      else if (b.ringkasan != null)
                        Text(
                          b.ringkasan!,
                          style: const TextStyle(fontSize: 15, height: 1.55),
                        ),
                      const SizedBox(height: 18),
                      Divider(color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text(
                        'Komentar (${tampil.length})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _kGreen1,
                        ),
                      ),
                      if (tersembunyi > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '$tersembunyi komentar dari pengguna yang Anda blokir disembunyikan.',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: onBukaBlokir,
                                child: const Text('Buka blokir'),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                if (tampil.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    child: Text(
                      terverifikasi
                          ? 'Belum ada komentar. Jadilah yang pertama.'
                          : 'Belum ada komentar.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                else
                  for (final k in tampil)
                    _ItemKomentar(
                      komentar: k,
                      onHapus: () => onHapus(k),
                      onLaporkan: () => onLaporkan(k),
                      onBlokir: () => onBlokir(k),
                    ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BarisAgenda extends StatelessWidget {
  final IconData ikon;
  final String teks;
  const _BarisAgenda({required this.ikon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, size: 19, color: _kGreen1),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              teks,
              style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

enum _AksiKomentar { hapus, laporkan, blokir }

class _ItemKomentar extends StatelessWidget {
  final KomentarBerita komentar;
  final VoidCallback onHapus;
  final VoidCallback onLaporkan;
  final VoidCallback onBlokir;
  const _ItemKomentar({
    required this.komentar,
    required this.onHapus,
    required this.onLaporkan,
    required this.onBlokir,
  });

  @override
  Widget build(BuildContext context) {
    final k = komentar;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 6, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (k.orangId != null)
            GestureDetector(
              onTap: () => context.push('/profil/${k.orangId}'),
              child: OrangAvatar(
                orangId: k.orangId!,
                jenisKelamin: 'L',
                radius: 18,
              ),
            )
          else
            CircleAvatar(
              radius: 18,
              backgroundColor: _kGold.withValues(alpha: 0.2),
              child: const Icon(Icons.person_rounded, color: _kGreen1),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        k.penulis,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    if (k.pengurus) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _kGreen1,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Pengurus',
                          style: TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    if (k.tanggal != null)
                      Text(
                        formatTanggal(k.tanggal!, denganJam: true),
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(k.isi, style: const TextStyle(height: 1.4)),
              ],
            ),
          ),
          // Menu: pemilik dapat menghapus; komentar orang lain dapat
          // dilaporkan atau penulisnya diblokir.
          PopupMenuButton<_AksiKomentar>(
            tooltip: 'Opsi komentar',
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: Colors.grey.shade500,
            ),
            onSelected: (a) {
              switch (a) {
                case _AksiKomentar.hapus:
                  onHapus();
                case _AksiKomentar.laporkan:
                  onLaporkan();
                case _AksiKomentar.blokir:
                  onBlokir();
              }
            },
            itemBuilder: (_) => [
              if (k.milikSendiri)
                const PopupMenuItem(
                  value: _AksiKomentar.hapus,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Hapus komentar'),
                  ),
                )
              else ...[
                const PopupMenuItem(
                  value: _AksiKomentar.laporkan,
                  child: ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.flag_outlined),
                    title: Text('Laporkan komentar'),
                  ),
                ),
                if (k.orangId != null)
                  const PopupMenuItem(
                    value: _AksiKomentar.blokir,
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.block_rounded),
                      title: Text('Blokir pengguna'),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Lembar pilih alasan laporan. Mengembalikan (kodeAlasan, catatan).
class _LembarLaporan extends StatefulWidget {
  const _LembarLaporan();

  @override
  State<_LembarLaporan> createState() => _LembarLaporanState();
}

class _LembarLaporanState extends State<_LembarLaporan> {
  String? _alasan;
  final _catatan = TextEditingController();

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Laporkan Komentar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _kGreen1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih alasan. Laporan Anda dikirim ke pengurus untuk ditinjau.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _alasan,
              onChanged: (v) => setState(() => _alasan = v),
              child: Column(
                children: [
                  for (final (kode, label) in alasanLaporan)
                    RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: kode,
                      title: Text(label),
                    ),
                ],
              ),
            ),
            TextField(
              controller: _catatan,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _alasan == null
                  ? null
                  : () => Navigator.of(context).pop((
                      _alasan!,
                      _catatan.text.trim().isEmpty
                          ? null
                          : _catatan.text.trim(),
                    )),
              style: FilledButton.styleFrom(
                backgroundColor: _kGreen1,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Kirim Laporan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputKomentar extends StatelessWidget {
  final TextEditingController controller;
  final bool mengirim;
  final VoidCallback onKirim;
  final VoidCallback onAturan;
  const _InputKomentar({
    required this.controller,
    required this.mengirim,
    required this.onKirim,
    required this.onAturan,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 1000,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Tulis komentar...',
                    counterText: '',
                    isDense: true,
                    filled: true,
                    fillColor: const Color(0xFFFAF9F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: mengirim ? null : onKirim,
                icon: mengirim
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: _kGreen1),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4),
            child: GestureDetector(
              onTap: onAturan,
              child: Text(
                'Dengan berkomentar Anda menyetujui Aturan Komentar.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
