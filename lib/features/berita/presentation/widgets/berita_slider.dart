import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/berita.dart';
import '../providers/berita_provider.dart';
import 'berita_gambar.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

/// "dd MMM yyyy" dalam bahasa Indonesia; bila locale belum siap, jatuh ke
/// format bawaan agar tidak pernah melempar error di beranda.
String formatTanggal(DateTime d, {bool denganJam = false}) {
  try {
    return DateFormat(
      denganJam ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy',
      'id_ID',
    ).format(d);
  } catch (_) {
    return DateFormat(denganJam ? 'd MMM yyyy, HH:mm' : 'd MMM yyyy').format(d);
  }
}

/// Keterangan satu baris di bawah judul: agenda = jadwal dan lokasi, berita =
/// tanggal terbit.
String keteranganBerita(BeritaRingkas b) {
  if (b.agenda) {
    return [
      if (b.tanggalMulai != null)
        formatTanggal(b.tanggalMulai!, denganJam: true),
      if (b.lokasi != null) b.lokasi!,
    ].join(' • ');
  }
  return b.tanggalTerbit != null ? formatTanggal(b.tanggalTerbit!) : '';
}

/// Area "Berita & Agenda" di beranda: judul dengan tautan "Lihat semua" di
/// kanan atas, lalu slider geser kiri-kanan berisi hingga 5 yang terbaru.
class BeritaSlider extends ConsumerStatefulWidget {
  const BeritaSlider({super.key});

  @override
  ConsumerState<BeritaSlider> createState() => _BeritaSliderState();
}

class _BeritaSliderState extends ConsumerState<BeritaSlider> {
  final _controller = PageController(viewportFraction: 0.88);
  int _halaman = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(beritaBerandaProvider);
    return async.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      // Gangguan jaringan tidak boleh merusak beranda: area ini cukup hilang.
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Berita & Agenda',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: _kGreen1,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/berita'),
                    child: const Text(
                      'Lihat semua',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 228,
              child: PageView.builder(
                controller: _controller,
                itemCount: items.length,
                onPageChanged: (i) => setState(() => _halaman = i),
                padEnds: false,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 20 : 6,
                    right: i == items.length - 1 ? 20 : 6,
                  ),
                  child: KartuBerita(item: items[i]),
                ),
              ),
            ),
            if (items.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _halaman ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _halaman ? _kGold : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Kartu satu berita/agenda untuk slider beranda.
class KartuBerita extends StatelessWidget {
  final BeritaRingkas item;
  const KartuBerita({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final ket = keteranganBerita(item);
    return Material(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/berita/${item.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                BeritaGambar(
                  beritaId: item.id,
                  punyaGambar: item.punyaGambar,
                  agenda: item.agenda,
                  height: 104,
                ),
                Positioned(top: 8, left: 8, child: LabelJenis(item: item)),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.judul,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                    if (item.ringkasan != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.ringkasan!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ket,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                        if (item.jumlahKomentar > 0) ...[
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 13,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${item.jumlahKomentar}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lencana "Berita" / "Agenda" (dan "Selesai" untuk agenda yang sudah lewat).
class LabelJenis extends StatelessWidget {
  final BeritaRingkas item;
  const LabelJenis({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final teks = item.agenda
        ? (item.sudahLewat ? 'Agenda • Selesai' : 'Agenda')
        : 'Berita';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: item.agenda ? _kGold : _kGreen1,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        teks,
        style: TextStyle(
          color: item.agenda ? _kGreen1 : Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
