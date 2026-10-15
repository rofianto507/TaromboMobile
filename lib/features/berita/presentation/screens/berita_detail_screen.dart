import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/widgets/app_dialog.dart';
import '../../../../shared/widgets/orang_avatar.dart';
import '../../../klaim/domain/entities/klaim_info.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../domain/entities/berita.dart';
import '../providers/berita_provider.dart';
import '../widgets/berita_gambar.dart';
import '../widgets/berita_slider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

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

  Future<void> _kirim() async {
    final teks = _ctrl.text.trim();
    if (teks.isEmpty || _mengirim) return;
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

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(beritaDetailProvider(widget.beritaId));
    final terverifikasi =
        ref.watch(klaimNotifierProvider).valueOrNull?.status ==
        KlaimStatus.disetujui;

    return Scaffold(
      appBar: AppBar(title: const Text('Berita & Agenda')),
      body: async.when(
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
        data: (d) =>
            _Isi(detail: d, terverifikasi: terverifikasi, onHapus: _hapus),
      ),
      bottomNavigationBar: async.hasValue
          ? SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: terverifikasi
                    ? _InputKomentar(
                        controller: _ctrl,
                        mengirim: _mengirim,
                        onKirim: _kirim,
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
            )
          : null,
    );
  }
}

class _Isi extends StatelessWidget {
  final BeritaDetail detail;
  final bool terverifikasi;
  final void Function(KomentarBerita) onHapus;
  const _Isi({
    required this.detail,
    required this.terverifikasi,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final b = detail.ringkas;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        BeritaGambar(
          beritaId: b.id,
          punyaGambar: b.punyaGambar,
          agenda: b.agenda,
          height: 210,
        ),
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
                  if (b.tanggalTerbit != null) formatTanggal(b.tanggalTerbit!),
                ].join(' • '),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
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
                              : formatTanggal(b.tanggalMulai!, denganJam: true),
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
                'Komentar (${detail.komentar.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: _kGreen1,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        if (detail.komentar.isEmpty)
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
          for (final k in detail.komentar)
            _ItemKomentar(komentar: k, onHapus: () => onHapus(k)),
        const SizedBox(height: 24),
      ],
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

class _ItemKomentar extends StatelessWidget {
  final KomentarBerita komentar;
  final VoidCallback onHapus;
  const _ItemKomentar({required this.komentar, required this.onHapus});

  @override
  Widget build(BuildContext context) {
    final k = komentar;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
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
          if (k.milikSendiri)
            IconButton(
              visualDensity: VisualDensity.compact,
              tooltip: 'Hapus komentar',
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: Colors.grey.shade500,
              ),
              onPressed: onHapus,
            ),
        ],
      ),
    );
  }
}

class _InputKomentar extends StatelessWidget {
  final TextEditingController controller;
  final bool mengirim;
  final VoidCallback onKirim;
  const _InputKomentar({
    required this.controller,
    required this.mengirim,
    required this.onKirim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
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
    );
  }
}
