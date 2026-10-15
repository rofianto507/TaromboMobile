import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../shared/utils/orang_format.dart';
import '../../../../shared/widgets/orang_search_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../klaim/presentation/providers/klaim_provider.dart';
import '../../domain/entities/partuturan_result.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold = Color(0xFFC8A24A);

class PartuturanScreen extends ConsumerStatefulWidget {
  const PartuturanScreen({super.key});

  @override
  ConsumerState<PartuturanScreen> createState() => _PartuturanScreenState();
}

class _PartuturanScreenState extends ConsumerState<PartuturanScreen> {
  Map<String, dynamic>? _orangA;
  Map<String, dynamic>? _orangB;
  bool _loading = false;
  String? _error;
  PartuturanResult? _result;

  @override
  void initState() {
    super.initState();
    // Prefill pihak A dengan profil sendiri kalau klaim sudah disetujui —
    // pemakaian paling umum adalah "saya panggil apa ke si X".
    final myOrang = ref.read(klaimNotifierProvider).valueOrNull?.orang;
    if (myOrang != null) {
      _orangA = {'id': myOrang.id, 'name': myOrang.name};
    }
  }

  Future<void> _pick(bool isA) async {
    final result = await showOrangSearchSheet(
      context,
      ref,
      title: isA ? 'Pilih Orang Pertama' : 'Pilih Orang Kedua',
    );
    if (result == null) return;
    setState(() {
      if (isA) {
        _orangA = result;
      } else {
        _orangB = result;
      }
      _result = null;
      _error = null;
    });
  }

  void _swap() {
    setState(() {
      final tmp = _orangA;
      _orangA = _orangB;
      _orangB = tmp;
      _result = null;
    });
  }

  Future<void> _hitung() async {
    if (_orangA == null || _orangB == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final json = await api.callKw(
        model: 'tarombo.orang',
        method: 'hitung_partuturan_mobile',
        args: [_orangA!['id'], _orangB!['id']],
      );
      setState(
        () => _result = PartuturanResult.fromJson(
          (json as Map).cast<String, dynamic>(),
        ),
      );
    } catch (e) {
      setState(
        () => _error = e is ServerException
            ? e.message
            : 'Gagal menghitung. Periksa koneksi Anda.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hitung Partuturan')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Pilih dua orang di pohon keluarga untuk mengetahui istilah panggilan kekerabatan Batak di antara keduanya.',
            style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          _PersonSlot(
            label: 'Orang Pertama',
            orang: _orangA,
            onTap: () => _pick(true),
          ),
          Center(
            child: IconButton(
              onPressed: (_orangA != null || _orangB != null) ? _swap : null,
              icon: const Icon(Icons.swap_vert_rounded, color: _kGold),
              tooltip: 'Tukar',
            ),
          ),
          _PersonSlot(
            label: 'Orang Kedua',
            orang: _orangB,
            onTap: () => _pick(false),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _kGold,
                foregroundColor: _kGreen1,
              ),
              onPressed: (_orangA != null && _orangB != null && !_loading)
                  ? _hitung
                  : null,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text(
                      'Hitung Partuturan',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
          if (_result != null)
            _ResultCard(
              result: _result!,
              namaA: _orangA!['name'] as String,
              namaB: _orangB!['name'] as String,
            ),
        ],
      ),
    );
  }
}

class _PersonSlot extends StatelessWidget {
  final String label;
  final Map<String, dynamic>? orang;
  final VoidCallback onTap;
  const _PersonSlot({
    required this.label,
    required this.orang,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF9F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _kGold.withValues(alpha: 0.15),
              child: const Icon(Icons.person_rounded, color: _kGreen1),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  Text(
                    orang?['name'] as String? ?? 'Ketuk untuk memilih',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: orang != null ? _kGreen1 : Colors.grey.shade500,
                    ),
                  ),
                  if (orang != null && subtitleOrang(orang!).isNotEmpty)
                    Text(
                      subtitleOrang(orang!),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.search),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final PartuturanResult result;
  final String namaA;
  final String namaB;
  const _ResultCard({
    required this.result,
    required this.namaA,
    required this.namaB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kGreen1,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SebutanChip(nama: namaA, sebutan: result.sebutanA),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.compare_arrows_rounded,
                  color: Colors.white70,
                ),
              ),
              Expanded(
                child: _SebutanChip(nama: namaB, sebutan: result.sebutanB),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            result.keterangan,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          if (result.ancName != null) ...[
            const Divider(color: Colors.white24, height: 28),
            Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  color: _kGold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Leluhur bersama: ${result.ancName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SebutanChip extends StatelessWidget {
  final String nama;
  final String sebutan;
  const _SebutanChip({required this.nama, required this.sebutan});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          nama,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          sebutan,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _kGold,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
