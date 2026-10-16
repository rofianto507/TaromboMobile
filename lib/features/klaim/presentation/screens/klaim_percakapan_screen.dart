import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/klaim_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

class PesanKlaim {
  final int id;
  final bool dariPengurus;
  final String penulis;
  final DateTime? tanggal;
  final String isi;
  const PesanKlaim({
    required this.id,
    required this.dariPengurus,
    required this.penulis,
    this.tanggal,
    required this.isi,
  });

  factory PesanKlaim.fromJson(Map<String, dynamic> j) {
    final t = asOdooString(j['tanggal']);
    return PesanKlaim(
      id: j['id'] as int,
      dariPengurus: j['dari_pengurus'] == true,
      penulis: (j['penulis'] as String?) ?? '',
      tanggal: t == null
          ? null
          : DateTime.tryParse('${t.replaceFirst(' ', 'T')}Z')?.toLocal(),
      isi: (j['isi'] as String?) ?? '',
    );
  }
}

class PercakapanKlaim {
  final int klaimId;
  final bool tutup;
  final List<PesanKlaim> pesan;
  const PercakapanKlaim({
    required this.klaimId,
    required this.tutup,
    required this.pesan,
  });

  factory PercakapanKlaim.fromJson(Map<String, dynamic> j) => PercakapanKlaim(
    klaimId: (j['record_id'] ?? j['klaim_id']) as int,
    tutup: j['tutup'] == true,
    pesan: [
      for (final m in (j['pesan'] as List? ?? const []))
        PesanKlaim.fromJson((m as Map).cast<String, dynamic>()),
    ],
  );
}

/// Percakapan sebuah pengajuan; kunci = (model Odoo, id rekaman).
final percakapanKlaimProvider = FutureProvider.autoDispose
    .family<PercakapanKlaim, (String, int)>((ref, kunci) async {
      final api = ref.read(apiClientProvider);
      final json =
          await api.callKw(
                model: kunci.$1,
                method: 'get_percakapan',
                args: [kunci.$2],
              )
              as Map;
      return PercakapanKlaim.fromJson(json.cast<String, dynamic>());
    });

/// Percakapan dua arah antara pengaju dan pengurus, tertaut ke pengajuan
/// klaim atau banding (chatter pengajuan di panel web).
class KlaimPercakapanScreen extends ConsumerWidget {
  const KlaimPercakapanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PercakapanScreen(
    model: 'tarombo.klaim_akun',
    recordId: ref.watch(klaimNotifierProvider).valueOrNull?.klaimId,
  );
}

/// Percakapan pada sebuah usulan.
class UsulanPercakapanScreen extends StatelessWidget {
  final int usulanId;
  const UsulanPercakapanScreen({super.key, required this.usulanId});

  @override
  Widget build(BuildContext context) =>
      PercakapanScreen(model: 'tarombo.usulan', recordId: usulanId);
}

/// Layar percakapan generik untuk model yang memakai tarombo.percakapan.mixin.
class PercakapanScreen extends ConsumerStatefulWidget {
  final String model;
  final int? recordId;
  const PercakapanScreen({super.key, required this.model, this.recordId});

  @override
  ConsumerState<PercakapanScreen> createState() => _PercakapanScreenState();
}

class _PercakapanScreenState extends ConsumerState<PercakapanScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool _mengirim = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _keBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _kirim(int klaimId) async {
    final teks = _ctrl.text.trim();
    if (teks.isEmpty || _mengirim) return;
    setState(() => _mengirim = true);
    try {
      await ref
          .read(apiClientProvider)
          .callKw(
            model: widget.model,
            method: 'kirim_pesan',
            args: [klaimId, teks],
          );
      _ctrl.clear();
      ref.invalidate(percakapanKlaimProvider((widget.model, klaimId)));
      _keBawah();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ServerException
                ? e.message
                : 'Gagal mengirim pesan. Periksa koneksi Anda.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _mengirim = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final klaimId = widget.recordId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Percakapan dengan Pengurus'),
        actions: [
          if (klaimId != null)
            IconButton(
              tooltip: 'Muat ulang',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => ref.invalidate(
                percakapanKlaimProvider((widget.model, klaimId)),
              ),
            ),
        ],
      ),
      body: klaimId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Belum ada pengajuan yang dapat dibicarakan.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : ref
                .watch(percakapanKlaimProvider((widget.model, klaimId)))
                .when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      'Gagal memuat percakapan.',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                  data: (p) {
                    _keBawah();
                    return Column(
                      children: [
                        Container(
                          width: double.infinity,
                          color: _kGold.withValues(alpha: 0.12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lock_outline_rounded,
                                size: 16,
                                color: _kGreen1,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Percakapan ini hanya dilihat pengurus. '
                                  'Gunakan bahasa yang sopan.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: p.pesan.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(28),
                                    child: Text(
                                      'Belum ada pesan. Tulis bila Anda ingin '
                                      'menambahkan keterangan atau bertanya '
                                      'kepada pengurus mengenai pengajuan ini.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scroll,
                                  padding: const EdgeInsets.all(16),
                                  itemCount: p.pesan.length,
                                  itemBuilder: (_, i) =>
                                      _Gelembung(pesan: p.pesan[i]),
                                ),
                        ),
                        if (p.tutup)
                          Container(
                            width: double.infinity,
                            color: const Color(0xFFFAF9F5),
                            padding: const EdgeInsets.all(14),
                            child: Text(
                              'Percakapan ditutup karena pengajuan sudah '
                              'selesai diproses.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.5,
                              ),
                            ),
                          )
                        else
                          SafeArea(
                            top: false,
                            child: Padding(
                              // Scaffold sudah menggeser isi ke atas keyboard; jangan
                              // menambahkan inset keyboard lagi (jadi terlalu tinggi).
                              padding: EdgeInsets.zero,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    top: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _ctrl,
                                        minLines: 1,
                                        maxLines: 4,
                                        maxLength: 1000,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: InputDecoration(
                                          hintText: 'Tulis pesan...',
                                          counterText: '',
                                          isDense: true,
                                          filled: true,
                                          fillColor: const Color(0xFFFAF9F5),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 10,
                                              ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _mengirim
                                          ? null
                                          : () => _kirim(klaimId),
                                      icon: _mengirim
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.send_rounded,
                                              color: _kGreen1,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
    );
  }
}

class _Gelembung extends StatelessWidget {
  final PesanKlaim pesan;
  const _Gelembung({required this.pesan});

  @override
  Widget build(BuildContext context) {
    final saya = !pesan.dariPengurus;
    final waktu = pesan.tanggal == null
        ? ''
        : DateFormat('d MMM, HH:mm', 'id_ID').format(pesan.tanggal!);
    return Align(
      alignment: saya ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: saya ? _kGreen1 : _kGold.withValues(alpha: 0.18),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(saya ? 16 : 4),
            bottomRight: Radius.circular(saya ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!saya)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  pesan.penulis.isEmpty ? 'Pengurus' : pesan.penulis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: _kGreen1,
                  ),
                ),
              ),
            Text(
              pesan.isi,
              style: TextStyle(
                color: saya ? Colors.white : Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              waktu,
              style: TextStyle(
                fontSize: 10.5,
                color: saya ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
