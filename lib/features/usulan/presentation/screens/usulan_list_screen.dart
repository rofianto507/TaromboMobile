import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/usulan_ringkas.dart';
import '../providers/usulan_provider.dart';

const _kGreen1 = Color(0xFF2E5339);
const _kGold   = Color(0xFFC8A24A);

class UsulanListScreen extends ConsumerWidget {
  const UsulanListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(usulanListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Usulan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _kGold,
        foregroundColor: _kGreen1,
        icon: const Icon(Icons.add),
        label: const Text('Usulan Baru'),
        onPressed: () async {
          await context.push('/usulan/baru');
          ref.invalidate(usulanListProvider);
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(usulanListProvider),
        child: listAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Gagal memuat usulan.\n$e', textAlign: TextAlign.center)),
          data: (items) => items.isEmpty
              ? ListView(
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('Belum ada usulan. Ketuk "Usulan Baru" untuk mengajukan.', style: TextStyle(color: Colors.grey))),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _UsulanCard(item: items[i]),
                ),
        ),
      ),
    );
  }
}

class _UsulanCard extends StatelessWidget {
  final UsulanRingkas item;
  const _UsulanCard({required this.item});

  Color get _color {
    switch (item.state) {
      case UsulanState.disetujui:
        return Colors.green;
      case UsulanState.ditolak:
        return Colors.red;
      case UsulanState.diajukan:
        return _kGold;
      case UsulanState.draft:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700, color: _kGreen1)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(usulanStateLabel(item.state), style: TextStyle(color: _color, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(jenisUsulanLabel(item.jenis), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          if (item.targetName != null)
            Text(
              item.jenis == 'tambah' ? 'Anak dari ${item.targetName}' : 'Untuk: ${item.targetName}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          if (item.state == UsulanState.ditolak && item.alasanTolak != null && item.alasanTolak!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Alasan: ${item.alasanTolak}', style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }
}
