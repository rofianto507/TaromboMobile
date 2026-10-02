import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/notifikasi_item.dart';

final notifikasiListProvider = FutureProvider.autoDispose<List<NotifikasiItem>>((ref) async {
  final api = ref.read(apiClientProvider);
  final rows = await api.callKw(
    model: 'tarombo.notifikasi',
    method: 'search_read',
    args: [[]],
    kwargs: {
      'fields': ['id', 'judul', 'isi', 'tipe', 'data', 'dibaca', 'create_date'],
      'order': 'create_date desc',
      'limit': 100,
    },
  ) as List;
  return rows.cast<Map<String, dynamic>>().map(NotifikasiItem.fromJson).toList();
});

final notifikasiUnreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final api = ref.read(apiClientProvider);
  final count = await api.callKw(
    model: 'tarombo.notifikasi',
    method: 'search_count',
    args: [
      [
        ['dibaca', '=', false]
      ]
    ],
  );
  return count as int? ?? 0;
});

final notifikasiServiceProvider = Provider((ref) => NotifikasiService(ref));

class NotifikasiService {
  final Ref ref;
  NotifikasiService(this.ref);

  Future<void> tandaiSemuaDibaca() async {
    final api = ref.read(apiClientProvider);
    await api.callKw(model: 'tarombo.notifikasi', method: 'tandai_semua_dibaca', args: const []);
    ref.invalidate(notifikasiListProvider);
    ref.invalidate(notifikasiUnreadCountProvider);
  }
}
