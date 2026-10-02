import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../shared/utils/arsip_labels.dart';
import '../../../../shared/widgets/arsip_thumbnail.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/arsip_item.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

Future<void> showArsipDetailSheet(BuildContext context, int arsipId) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ArsipDetailSheet(arsipId: arsipId),
  );
}

class _ArsipDetailSheet extends ConsumerStatefulWidget {
  final int arsipId;
  const _ArsipDetailSheet({required this.arsipId});

  @override
  ConsumerState<_ArsipDetailSheet> createState() => _ArsipDetailSheetState();
}

class _ArsipDetailSheetState extends ConsumerState<_ArsipDetailSheet> {
  ArsipItem? _item;
  bool _loading = true;
  String? _error;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final rows = await api.callKw(
        model: 'tarombo.arsip',
        method: 'search_read',
        args: [
          [
            ['id', '=', widget.arsipId]
          ]
        ],
        kwargs: {
          'fields': ['id', 'name', 'jenis', 'orang_id', 'punguan_id', 'tahun_perkiraan', 'sumber', 'keterangan', 'berkas_nama'],
        },
      ) as List;
      if (rows.isEmpty) {
        setState(() => _error = 'Arsip tidak ditemukan.');
        return;
      }
      setState(() => _item = ArsipItem.fromJson((rows.first as Map).cast<String, dynamic>()));
    } catch (_) {
      setState(() => _error = 'Gagal memuat data. Periksa koneksi Anda.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _bukaBerkas() async {
    setState(() => _opening = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final response = await dio.get<List<int>>(
        '/web/content/tarombo.arsip/${widget.arsipId}/berkas',
        options: Options(responseType: ResponseType.bytes),
      );
      final dir = await getTemporaryDirectory();
      final namaBerkas = _item?.berkasNama ?? 'arsip_${widget.arsipId}';
      final file = File('${dir.path}/$namaBerkas');
      await file.writeAsBytes(response.data!);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak ada aplikasi untuk membuka berkas ini (${result.message}).')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengunduh berkas. Periksa koneksi Anda.')),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!, textAlign: TextAlign.center))
                        : _buildContent(_item!, scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(ArsipItem item, ScrollController scrollController) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        ArsipThumbnail(
          arsipId: item.id,
          jenis: item.jenis,
          icon: jenisArsipIcon(item.jenis),
          height: 200,
          borderRadius: BorderRadius.circular(16),
        ),
        const SizedBox(height: 20),
        Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kGreen1)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Badge(icon: jenisArsipIcon(item.jenis), text: jenisArsipLabel(item.jenis)),
            if (item.punguan != null) _Badge(icon: Icons.groups_outlined, text: item.punguan!),
            if (item.tahunPerkiraan != null && item.tahunPerkiraan!.isNotEmpty)
              _Badge(icon: Icons.calendar_today_outlined, text: item.tahunPerkiraan!),
          ],
        ),
        const SizedBox(height: 20),
        if (item.orangName != null) _InfoRow(icon: Icons.person_outline_rounded, label: 'Terkait', value: item.orangName!),
        if (item.sumber != null && item.sumber!.isNotEmpty) _InfoRow(icon: Icons.source_outlined, label: 'Sumber', value: item.sumber!),
        if (item.keterangan != null && item.keterangan!.isNotEmpty) ...[
          const SizedBox(height: 10),
          const Text('Keterangan', style: TextStyle(fontWeight: FontWeight.w700, color: _kGreen1)),
          const SizedBox(height: 6),
          Text(item.keterangan!, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: _kGold, foregroundColor: _kGreen1),
            onPressed: _opening ? null : _bukaBerkas,
            icon: _opening
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.file_open_outlined),
            label: Text(_opening ? 'Mengunduh...' : 'Buka Berkas'),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  // Sama seperti sheet detail Usulan — lebar label tetap supaya titik dua &
  // value sejajar antar baris.
  static const _lebarLabel = 80.0;

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
            child: Text(label, style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          const Text(': ', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey.shade800, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Badge({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: _kGold.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _kGreen1),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, color: _kGreen1, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
