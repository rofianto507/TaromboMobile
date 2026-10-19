import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/usulan_detail.dart';
import '../../domain/entities/usulan_ringkas.dart';
import '../providers/usulan_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

Future<void> showUsulanDetailSheet(BuildContext context, int usulanId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _UsulanDetailSheet(usulanId: usulanId),
  );
}

class _UsulanDetailSheet extends ConsumerWidget {
  final int usulanId;
  const _UsulanDetailSheet({required this.usulanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(usulanDetailProvider(usulanId));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: detailAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Gagal memuat usulan.\n$e',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (d) => _DetailContent(
                    detail: d,
                    scrollController: scrollController,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailContent extends ConsumerStatefulWidget {
  final UsulanDetail detail;
  final ScrollController scrollController;
  const _DetailContent({required this.detail, required this.scrollController});

  @override
  ConsumerState<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends ConsumerState<_DetailContent> {
  int? _mengunduhId;

  Future<void> _bukaLampiran(LampiranItem item) async {
    setState(() => _mengunduhId = item.id);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get<List<int>>(
        '/web/content/${item.id}?download=true',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/${item.name}');
      await file.writeAsBytes(response.data!);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak ada aplikasi untuk membuka berkas ini (${result.message}).',
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunduh lampiran.')),
        );
      }
    } finally {
      if (mounted) setState(() => _mengunduhId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.detail;
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                d.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kGreen1,
                ),
              ),
            ),
            _StatusBadge(state: d.state),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          jenisUsulanLabel(d.jenis),
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        if (d.targetName != null)
          Text(
            d.jenis == 'tambah'
                ? 'Anak dari ${d.targetName}'
                : d.jenis == 'istri'
                ? 'Suami: ${d.targetName}'
                : 'Untuk: ${d.targetName}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        if (d.state == 'ditolak' && d.alasanTolak != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Alasan Ditolak: ${d.alasanTolak}',
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
          ),
        ],
        const Divider(height: 28),

        if (d.adaFoto) ...[
          Center(child: _FotoUsulan(usulanId: d.id)),
          const SizedBox(height: 20),
        ],

        const Text(
          'Data yang Diusulkan',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kGreen1),
        ),
        const SizedBox(height: 10),
        if (d.usulNama != null)
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'Nama',
            value: d.usulNama!,
          ),
        if (d.jenis == 'istri')
          _InfoRow(
            icon: Icons.favorite_border_rounded,
            label: 'Aksi',
            value: d.istriDiperbarui != null
                ? 'Memperbarui data istri: ${d.istriDiperbarui}'
                : 'Melengkapi data istri',
          ),
        if (d.usulIstriNama != null)
          _InfoRow(
            icon: Icons.woman_rounded,
            label: 'Nama Istri',
            value: d.usulIstriNama!,
          ),
        if (d.usulIstriMarga != null)
          _InfoRow(
            icon: Icons.groups_outlined,
            label: 'Marga Istri',
            value: d.usulIstriMarga!,
          ),
        if (d.usulIstriTahun != null)
          _InfoRow(
            icon: Icons.event_outlined,
            label: 'Tahun Menikah',
            value: '${d.usulIstriTahun}',
          ),
        if (d.usulJenisKelamin != null)
          _InfoRow(
            icon: Icons.wc_rounded,
            label: 'Jenis Kelamin',
            value: d.usulJenisKelamin == 'P' ? 'Perempuan' : 'Laki-laki',
          ),
        if (d.usulMasihHidup != null)
          _InfoRow(
            icon: Icons.favorite_border_rounded,
            label: 'Masih Hidup',
            value: d.usulMasihHidup == 'ya' ? 'Ya' : 'Tidak',
          ),
        if (d.usulUrutan != null)
          _InfoRow(
            icon: Icons.format_list_numbered_rounded,
            label: 'Anak ke-',
            value: '${d.usulUrutan}',
          ),
        if ((d.usulTahunLahir ?? d.usulTanggalLahir?.year) != null)
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Tahun Lahir',
            value: '${d.usulTahunLahir ?? d.usulTanggalLahir!.year}',
          ),
        if ((d.usulTahunWafat ?? d.usulTanggalWafat?.year) != null)
          _InfoRow(
            icon: Icons.church_outlined,
            label: 'Tahun Wafat',
            value: '${d.usulTahunWafat ?? d.usulTanggalWafat!.year}',
          ),
        if (d.usulSuamiNama != null)
          _InfoRow(
            icon: Icons.man_rounded,
            label: 'Nama Suami',
            value: d.usulSuamiNama!,
          ),
        if (d.usulSuamiMarga != null)
          _InfoRow(
            icon: Icons.groups_outlined,
            label: 'Marga Suami',
            value: d.usulSuamiMarga!,
          ),
        if (d.usulWilayah != null)
          _InfoRow(
            icon: Icons.map_outlined,
            label: 'Wilayah',
            value: d.usulWilayah!,
          ),
        if (d.usulAlamatJalan != null)
          _InfoRow(
            icon: Icons.home_outlined,
            label: 'Alamat',
            value: d.usulAlamatJalan!,
          ),
        if (d.usulNoTelp != null)
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Telepon',
            value: d.usulNoTelp!,
          ),
        if (d.usulEmailKontak != null)
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: d.usulEmailKontak!,
          ),

        if (d.usulLatitude != null && d.usulLongitude != null) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 160,
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(d.usulLatitude!, d.usulLongitude!),
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'id.selstudio.tarombo_mobile',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(d.usulLatitude!, d.usulLongitude!),
                          width: 36,
                          height: 36,
                          child: const Icon(
                            Icons.location_on,
                            color: _kGreen1,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (d.catatan != null && d.catatan!.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Catatan',
            style: TextStyle(fontWeight: FontWeight.w700, color: _kGreen1),
          ),
          const SizedBox(height: 6),
          Text(
            d.catatan!,
            style: TextStyle(color: Colors.grey.shade700, height: 1.4),
          ),
        ],

        const Divider(height: 28),
        const Text(
          'Jejak Pengajuan',
          style: TextStyle(fontWeight: FontWeight.w700, color: _kGreen1),
        ),
        const SizedBox(height: 10),
        _InfoRow(
          icon: Icons.source_outlined,
          label: 'Sumber Keterangan',
          value: d.sumberKet,
        ),
        if (d.tanggalAjukan != null)
          _InfoRow(
            icon: Icons.send_outlined,
            label: 'Diajukan',
            value: DateFormat(
              'd MMM yyyy, HH:mm',
              'id_ID',
            ).format(d.tanggalAjukan!),
          ),
        if (d.peninjau != null)
          _InfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Peninjau',
            value: d.peninjau!,
          ),
        if (d.tanggalTinjau != null)
          _InfoRow(
            icon: Icons.event_available_outlined,
            label: 'Ditinjau',
            value: DateFormat(
              'd MMM yyyy, HH:mm',
              'id_ID',
            ).format(d.tanggalTinjau!),
          ),

        if (d.state == 'diajukan' || d.state == 'draft') ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _kGreen1,
              side: const BorderSide(color: _kGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.of(context).pop();
              router.push('/usulan/percakapan/${d.id}');
            },
            icon: const Icon(Icons.forum_outlined, size: 20),
            label: const Text('Percakapan dengan Pengurus'),
          ),
        ],

        if (d.lampiran.isNotEmpty) ...[
          const Divider(height: 28),
          const Text(
            'Lampiran',
            style: TextStyle(fontWeight: FontWeight.w700, color: _kGreen1),
          ),
          const SizedBox(height: 6),
          ...d.lampiran.map(
            (l) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_rounded, color: _kGold),
              title: Text(l.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: _mengunduhId == l.id
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download_rounded, size: 20),
              onTap: _mengunduhId != null ? null : () => _bukaLampiran(l),
            ),
          ),
        ],
      ],
    );
  }
}

class _FotoUsulan extends ConsumerWidget {
  final int usulanId;
  const _FotoUsulan({required this.usulanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = ref.watch(secureStorageProvider);
    return FutureBuilder<String?>(
      future: kIsWeb
          ? Future.value(null)
          : storage.read(key: AppConstants.tokenKey),
      builder: (context, snapshot) {
        if (!kIsWeb && !snapshot.hasData)
          return const SizedBox(width: 96, height: 96);
        final url =
            '${AppConfig.baseUrl}/web/image/tarombo.usulan/$usulanId/usul_foto';
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: url,
            httpHeaders: kIsWeb
                ? const {}
                : {'Cookie': 'session_id=${snapshot.data}'},
            width: 160,
            height: 160,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(
              width: 160,
              height: 160,
              color: const Color(0xFFEFEDE5),
            ),
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String state;
  const _StatusBadge({required this.state});

  Color get _color {
    switch (state) {
      case 'disetujui':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      case 'diajukan':
        return _kGold;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        usulanStateLabel(usulanStateFromServer(state)),
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  // Lebar tetap untuk kolom label — supaya titik dua & value sejajar antar
  // baris, cukup untuk label terpanjang di sheet ini ("Sumber Keterangan").
  static const _lebarLabel = 128.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _kGold),
          const SizedBox(width: 10),
          SizedBox(
            width: _lebarLabel,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
