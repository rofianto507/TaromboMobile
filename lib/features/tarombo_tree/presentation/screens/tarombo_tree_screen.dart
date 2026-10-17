import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/graphview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/notifikasi_button.dart';
import '../../../../shared/widgets/verified_badge.dart';
import '../../../../shared/utils/debouncer.dart';
import '../../../../shared/utils/orang_format.dart';
import '../../../../shared/widgets/orang_list_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/pohon_node.dart';
import '../providers/pohon_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);
const _kPink = Color(0xFFE0729A);
const _kLinkPlayStore =
    'https://play.google.com/store/apps/details?id=id.selstudio.tarombo_mobile';

// Ukuran kartu node SENGAJA tetap (bukan dihitung dari widget asli) —
// graphview butuh node.size TERISI SEBELUM algoritma jalan (dipakai untuk
// spacing antar-saudara), jadi tidak bisa menunggu hasil layout widget
// sungguhan seperti pola bawaan package ini.
const _kCardW = 96.0;
const _kCardH = 132.0;

// Token sesi dibaca SEKALI di sini (di luar graphview), bukan lewat
// OrangAvatar (ConsumerWidget dengan ref.watch di dalamnya) — builder node
// graphview dipanggil lewat invokeLayoutCallback() di FASE LAYOUT, bukan
// fase build biasa, dan ref.watch di situ ternyata membuat SELURUH pohon
// gagal ter-paint tanpa exception yang terlihat (root cause paling sulit
// dilacak di fitur ini). Widget kartu node jadi StatelessWidget polos yang
// cuma menerima token sebagai String biasa.
final _pohonAuthTokenProvider = FutureProvider<String?>((ref) async {
  if (kIsWeb) return null;
  final storage = ref.watch(secureStorageProvider);
  return storage.read(key: AppConstants.tokenKey);
});

class TaromboTreeScreen extends ConsumerStatefulWidget {
  const TaromboTreeScreen({super.key});

  @override
  ConsumerState<TaromboTreeScreen> createState() => _TaromboTreeScreenState();
}

class _TaromboTreeScreenState extends ConsumerState<TaromboTreeScreen> {
  final _config = BuchheimWalkerConfiguration()
    ..siblingSeparation = 24
    ..levelSeparation = 56
    ..subtreeSeparation = 28
    ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;

  // Dipakai untuk memaksa InteractiveViewer balik ke posisi awal (identity)
  // tiap kanvas berganti fokus/mode — lihat pemakaiannya di _buildTree.
  final _transformCtrl = TransformationController();
  String? _viewKeyTerakhir;
  final _kanvasKey = GlobalKey();
  bool _membagikan = false;

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pohonAsync = ref.watch(pohonNotifierProvider);
    final token = ref.watch(_pohonAuthTokenProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.account_tree_outlined, size: 22),
            SizedBox(width: 10),
            Text('Tarombo'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Cari orang di pohon',
            onPressed: () => _bukaPencarian(context, ref),
          ),
          const NotifikasiButton(),
        ],
      ),
      body: Stack(
        children: [
          // Sama seperti Beranda/Akun — tekstur Danau Toba di-tint hijau &
          // fade di tepi atas, dipatok ke dasar layar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.white],
                stops: [0.0, 0.5],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Opacity(
                opacity: 0.35,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(
                    _kGreen1,
                    BlendMode.color,
                  ),
                  child: Image.asset(
                    'assets/images/toba.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          pohonAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Gagal memuat pohon silsilah.\n$e',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => ref.invalidate(pohonNotifierProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
            data: (root) {
              if (root == null)
                return _EmptyState(onCari: () => _bukaPencarian(context, ref));
              return _buildTree(context, root, token);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTree(BuildContext context, PohonNode root, String? token) {
    final graph = Graph()..isTree = true;
    final byId = <int, PohonNode>{root.id: root};
    graph.addNode(Node.Id(root.id));
    _tambahAnak(graph, root, byId);

    for (final n in graph.nodes) {
      n.size = const Size(_kCardW, _kCardH);
    }
    // Dijalankan manual di sini (bukan diserahkan ke widget GraphView) —
    // GraphView.builder/RenderCustomLayoutBox milik package ini ternyata
    // kadang gagal mem-paint anak-anaknya pada frame pertama tanpa exception
    // apa pun (lolos flutter analyze, tidak ada error di logcat, tapi layar
    // kosong — hanya "sembuh" kalau di-invalidate manual). Root cause-nya
    // ada di RenderObjectElement kustom mereka (giliran build lewat
    // invokeLayoutCallback), bukan di algoritma tata letaknya sendiri.
    // Makanya di sini `Graph`/`BuchheimWalkerAlgorithm` HANYA dipakai untuk
    // MENGHITUNG posisi (murni matematika) — perakitan tampilannya balik ke
    // Stack + CustomPaint + Positioned biasa, yang sudah pasti stabil.
    final algorithm = BuchheimWalkerAlgorithm(_config, null);
    algorithm.run(graph, 0, 0);
    final bounds = graph.calculateGraphBounds();
    const pad = 24.0;
    final canvasSize = Size(bounds.width + pad * 2, bounds.height + pad * 2);
    final dx = pad - bounds.left;
    final dy = pad - bounds.top;

    // Posisikan ulang viewport tiap fokus/mode berpindah — TANPA ini,
    // InteractiveViewer memakai ulang transform (posisi geser/zoom) lama
    // untuk kanvas yang ukuran & isinya sudah beda sama sekali. Sengaja
    // BUKAN cuma reset ke identity (pojok kiri-atas): algoritma tata letak
    // selalu menaruh node akar di TENGAH lebar kanvas (di atas rata-rata
    // posisi anak-anaknya), bukan di kiri. Untuk pohon lebar (mode Radial
    // dengan banyak keturunan sejajar), identity transform cuma menunjukkan
    // ujung kiri kanvas yang jauh dari akar — kelihatan seperti kosong
    // padahal akarnya ada, cuma di luar layar ke arah kanan. Makanya di sini
    // kita hitung translasi X supaya AKAR-nya yang berada tepat di tengah
    // viewport saat pertama dibuka, bukan cuma titik (0,0) kanvas.
    final viewKey = '${root.id}-${ref.watch(pohonModeProvider).name}';
    if (_viewKeyTerakhir != viewKey) {
      _viewKeyTerakhir = viewKey;
      final rootNode = graph.nodes.firstWhere((n) => n == Node.Id(root.id));
      final rootCenterX = rootNode.position.dx + dx + _kCardW / 2;
      final vpWidth = MediaQuery.sizeOf(context).width;
      final targetX = vpWidth / 2 - rootCenterX;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _transformCtrl.value = Matrix4.translationValues(targetX, 0.0, 0.0);
      });
    }

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: _transformCtrl,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(120),
          minScale: 0.4,
          maxScale: 2.5,
          child: RepaintBoundary(
            key: _kanvasKey,
            child: SizedBox(
              width: canvasSize.width,
              height: canvasSize.height,
              child: Stack(
                children: [
                  CustomPaint(
                    size: canvasSize,
                    painter: _PohonEdgePainter(
                      graph: graph,
                      offset: Offset(dx, dy),
                    ),
                  ),
                  for (final node in graph.nodes)
                    Positioned(
                      left: node.position.dx + dx,
                      top: node.position.dy + dy,
                      width: _kCardW,
                      height: _kCardH,
                      child: Builder(
                        builder: (context) {
                          final data = byId[node.key!.value as int]!;
                          return _PohonCard(
                            key: ValueKey(data.id),
                            data: data,
                            token: token,
                            onTap: () {
                              if (data.tertutup) {
                                ref
                                    .read(pohonNotifierProvider.notifier)
                                    .pindahFokus(data.id);
                              } else {
                                context.push('/profil/${data.id}');
                              }
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Kontrol kanvas (mode, kembali ke posisi saya, muat ulang) sengaja
        // dipindah ke sini (gaya kontrol peta) — sebelumnya numpuk di AppBar
        // bareng cari & notifikasi, jadi terlalu ramai.
        Positioned(
          right: 16,
          bottom: 16,
          child: _PohonControls(
            isOverride: ref.watch(pohonRootIdProvider) != null,
            onRecenter: () =>
                ref.read(pohonNotifierProvider.notifier).kembaliKeDiriSendiri(),
            onRefresh: () => ref.invalidate(pohonNotifierProvider),
            membagikan: _membagikan,
            onShare: () => _bagikan(root),
          ),
        ),
      ],
    );
  }

  /// Memotret seluruh kanvas pohon (bukan hanya bagian yang terlihat di layar),
  /// memberinya judul dan ajakan unduh, lalu membagikannya sebagai gambar.
  Future<void> _bagikan(PohonNode root) async {
    if (_membagikan) return;
    final boundary =
        _kanvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _membagikan = true);
    try {
      final w = boundary.size.width;
      final h = boundary.size.height;
      final rasio = (4096 / math.max(w, h)).clamp(1.0, 3.0).toDouble();
      final pohon = await boundary.toImage(pixelRatio: rasio);

      const header = 88.0;
      const footer = 76.0;
      final lebar = math.max(w, 360.0);
      final tinggi = header + h + footer;

      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      c.scale(rasio);
      c.drawRect(
        Rect.fromLTWH(0, 0, lebar, tinggi),
        Paint()..color = Colors.white,
      );
      c.drawRect(Rect.fromLTWH(0, 0, lebar, 6), Paint()..color = _kGreen1);

      void teks(String t, double y, double ukuran, Color warna, FontWeight b) {
        final tp = TextPainter(
          text: TextSpan(
            text: t,
            style: TextStyle(fontSize: ukuran, color: warna, fontWeight: b),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
          maxLines: 2,
          ellipsis: '…',
        )..layout(maxWidth: lebar - 40);
        tp.paint(c, Offset((lebar - tp.width) / 2, y));
      }

      teks('Tarombo ${root.name}', 22, 22, _kGreen1, FontWeight.w800);
      teks(
        'Silsilah marga Silaen',
        54,
        13,
        Colors.grey.shade600,
        FontWeight.w500,
      );
      c.drawImageRect(
        pohon,
        Rect.fromLTWH(0, 0, pohon.width.toDouble(), pohon.height.toDouble()),
        Rect.fromLTWH((lebar - w) / 2, header, w, h),
        Paint()..filterQuality = FilterQuality.high,
      );
      c.drawRect(
        Rect.fromLTWH(lebar * 0.2, header + h + 8, lebar * 0.6, 1.5),
        Paint()..color = _kGold,
      );
      teks(
        'Unduh aplikasi Tarombo di Play Store',
        header + h + 20,
        13,
        _kGreen1,
        FontWeight.w700,
      );
      teks(
        'play.google.com/store/apps/details?id=id.selstudio.tarombo_mobile',
        header + h + 42,
        10,
        Colors.grey.shade600,
        FontWeight.w400,
      );

      final hasil = await rec.endRecording().toImage(
        (lebar * rasio).round(),
        (tinggi * rasio).round(),
      );
      final bytes = await hasil.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('gagal membuat gambar');
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/tarombo_${root.id}.png');
      await f.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Tarombo ${root.name}. Telusuri silsilah marga di aplikasi '
              'Tarombo. Unduh gratis di Play Store:\n$_kLinkPlayStore',
          subject: 'Tarombo ${root.name}',
          files: [XFile(f.path, mimeType: 'image/png')],
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membagikan pohon. Coba lagi.')),
        );
      }
    } finally {
      if (mounted) setState(() => _membagikan = false);
    }
  }

  // Sengaja HANYA `addEdge` di sini (bukan `addNode` lagi) — addEdge sudah
  // otomatis mendaftarkan node tujuan yang belum ada. Memanggil addNode DUA
  // KALI untuk node yang sama (sekali di sini, sekali lewat addEdge) membuat
  // graphview punya dua instance Node "kembar" untuk satu id yang sama —
  // salah satunya yatim tanpa edge, yang ternyata cukup untuk mengacaukan
  // algoritma tata letak sampai seluruh pohon tidak tergambar sama sekali.
  void _tambahAnak(Graph graph, PohonNode node, Map<int, PohonNode> byId) {
    for (final anak in node.children) {
      byId[anak.id] = anak;
      graph.addEdge(Node.Id(node.id), Node.Id(anak.id));
      _tambahAnak(graph, anak, byId);
    }
  }

  Future<void> _bukaPencarian(BuildContext context, WidgetRef ref) async {
    final id = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const _PencarianFokusSheet(),
    );
    if (id != null) {
      ref.read(pohonNotifierProvider.notifier).pindahFokus(id);
    }
  }
}

/// Kelompok tombol kontrol kanvas, gaya kontrol peta (Google Maps dkk.) —
/// lingkaran putih melayang di pojok kanan-bawah, ditumpuk vertikal.
///
/// Toggle mode Cabang/Radial SENGAJA disembunyikan dulu (bukan dihapus) —
/// membingungkan pengguna tanpa penjelasan lebih dulu soal bedanya. Logika
/// pohonModeProvider/gantiMode di provider tetap ada, tinggal tampilkan lagi
/// tombolnya kalau nanti sudah ada cara yang lebih jelas untuk menjelaskan
/// pilihan ini ke pengguna.
class _PohonControls extends StatelessWidget {
  final bool isOverride;
  final VoidCallback onRecenter;
  final VoidCallback onRefresh;
  final VoidCallback onShare;
  final bool membagikan;

  const _PohonControls({
    required this.isOverride,
    required this.onRecenter,
    required this.onRefresh,
    required this.onShare,
    required this.membagikan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isOverride) ...[
          _tombol(
            icon: Icons.my_location_rounded,
            tooltip: 'Kembali ke posisi saya',
            onTap: onRecenter,
          ),
          const SizedBox(height: 10),
        ],
        _tombol(
          icon: Icons.ios_share_rounded,
          tooltip: 'Bagikan gambar pohon',
          onTap: membagikan ? () {} : onShare,
        ),
        const SizedBox(height: 10),
        _tombol(
          icon: Icons.refresh_rounded,
          tooltip: 'Muat ulang pohon',
          onTap: onRefresh,
        ),
      ],
    );
  }

  Widget _tombol({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black45,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: _kGreen1),
          ),
        ),
      ),
    );
  }
}

/// Menggambar garis penghubung ayah-anak lewat CustomPainter biasa —
/// dihitung dari posisi Node yang sudah diberikan BuchheimWalkerAlgorithm,
/// bukan lewat renderer bawaan graphview (lihat komentar di _buildTree).
class _PohonEdgePainter extends CustomPainter {
  final Graph graph;
  final Offset offset;
  _PohonEdgePainter({required this.graph, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kGold.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final edge in graph.edges) {
      final from =
          edge.source.position + offset + const Offset(_kCardW / 2, _kCardH);
      final to =
          edge.destination.position + offset + const Offset(_kCardW / 2, 0);
      final midY = (from.dy + to.dy) / 2;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, midY, to.dx, midY, to.dx, to.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PohonEdgePainter oldDelegate) =>
      oldDelegate.graph != graph;
}

class _PohonCard extends StatelessWidget {
  final PohonNode data;
  final String? token;
  final VoidCallback onTap;
  const _PohonCard({
    super.key,
    required this.data,
    required this.token,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warnaGender = data.jenisKelamin == 'P' ? _kPink : _kGreen1;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: data.selected ? _kGold : Colors.grey.shade300,
            width: data.selected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _FotoOrang(
                  orangId: data.id,
                  jenisKelamin: data.jenisKelamin,
                  token: token,
                  radius: 24,
                ),
                // Ada KETURUNAN di bawah yang tidak ditampilkan (batas
                // kedalaman/jumlah simpul, atau saudara yang sengaja
                // ditutup) — beda arah dari hasMoreAtas, jadi ikon & posisi
                // sengaja dibedakan (bawah-kanan, panah bawah).
                if (data.collapsed || data.hasMore)
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: _kGold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                // Ada LELUHUR di atas node ini yang tidak ditampilkan (cuma
                // berlaku untuk node akar/ayah hasil mode 'cabang'). Tanpa
                // ini, pohon terlihat berhenti total di titik teratas padahal
                // datanya masih ada.
                if (data.hasMoreAtas)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: _kGreen1,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            OrangNama(
              nama: data.name,
              terverifikasi: data.terhubungAkun,
              badgeSize: 13,
              maxLines: 2,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _kGreen1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sundut ${data.sundut}',
              style: TextStyle(fontSize: 9, color: warnaGender),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sengaja StatelessWidget POLOS (bukan ConsumerWidget seperti OrangAvatar)
/// — lihat komentar di _pohonAuthTokenProvider di atas untuk alasannya.
class _FotoOrang extends StatelessWidget {
  final int orangId;
  final String jenisKelamin;
  final String? token;
  final double radius;
  const _FotoOrang({
    required this.orangId,
    required this.jenisKelamin,
    required this.token,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final fallbackIcon = jenisKelamin == 'P'
        ? Icons.woman_rounded
        : Icons.man_rounded;
    if (!kIsWeb && token == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: _kGold.withValues(alpha: 0.15),
        child: Icon(fallbackIcon, color: _kGreen1),
      );
    }
    final url = '${AppConfig.baseUrl}/web/image/tarombo.orang/$orangId/foto';
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        httpHeaders: kIsWeb ? const {} : {'Cookie': 'session_id=$token'},
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, _) => CircleAvatar(
          radius: radius,
          backgroundColor: _kGold.withValues(alpha: 0.15),
        ),
        errorWidget: (_, _, _) => CircleAvatar(
          radius: radius,
          backgroundColor: _kGold.withValues(alpha: 0.15),
          child: Icon(fallbackIcon, color: _kGreen1),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCari;
  const _EmptyState({required this.onCari});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 64,
              color: _kGreen1.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pohon untuk Ditampilkan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _kGreen1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Identitas Anda belum tertaut ke data anggota. Cari nama seseorang '
              'untuk mulai menjelajahi pohon silsilah dari orang itu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: _kGreen1),
              onPressed: onCari,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Cari Orang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PencarianFokusSheet extends ConsumerStatefulWidget {
  const _PencarianFokusSheet();

  @override
  ConsumerState<_PencarianFokusSheet> createState() =>
      _PencarianFokusSheetState();
}

class _PencarianFokusSheetState extends ConsumerState<_PencarianFokusSheet> {
  final _ctrl = TextEditingController();
  final _debounce = Debouncer(kJedaCari);
  List<Map<String, dynamic>> _hasil = [];
  bool _loading = false;
  int _seq = 0;

  void _onChanged(String q) {
    if (q.trim().length < kMinHurufCari) {
      _debounce.cancel();
      _seq++;
      setState(() {
        _hasil = [];
        _loading = false;
      });
      return;
    }
    _debounce.run(() => _cari(q));
  }

  Future<void> _cari(String q) async {
    final saya = ++_seq;
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      final rows =
          await api.callKw(
                model: 'tarombo.orang',
                method: 'search_read',
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
      if (mounted && saya == _seq) {
        setState(() => _hasil = rows.cast<Map<String, dynamic>>());
      }
    } catch (_) {
      if (mounted && saya == _seq) setState(() => _hasil = []);
    } finally {
      if (mounted && saya == _seq) setState(() => _loading = false);
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
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _ctrl,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Ketik nama orang...',
                  prefixIcon: const Icon(Icons.search, color: _kGold),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasil.isEmpty
                  ? Center(
                      child: Text(
                        _ctrl.text.trim().length < kMinHurufCari
                            ? 'Ketik minimal 2 huruf untuk mencari.'
                            : 'Tidak ditemukan.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _hasil.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final o = _hasil[i];
                        return OrangListTile(
                          orang: o,
                          onTap: () => Navigator.pop(context, o['id'] as int),
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
