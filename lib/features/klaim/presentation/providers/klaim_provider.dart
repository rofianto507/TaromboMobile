import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/klaim_info.dart';

final klaimNotifierProvider = AsyncNotifierProvider<KlaimNotifier, KlaimInfo>(KlaimNotifier.new);

class KlaimNotifier extends AsyncNotifier<KlaimInfo> {
  @override
  Future<KlaimInfo> build() async {
    final api = ref.read(apiClientProvider);

    // get_my_orang() dicek DULUAN sebagai fakta pasti — action_setujui() di
    // backend selalu menulis orang.user_id dalam transaksi yang sama saat
    // menyetujui klaim, jadi ini satu-satunya sumber yang tidak bisa keliru.
    // SENGAJA TIDAK mengandalkan "baris tarombo.klaim_akun ber-id terbaru"
    // untuk menentukan status: satu akun bisa punya beberapa baris klaim
    // (klaim ke orang yang salah lalu klaim ulang ke orang yang benar, atau
    // baris "draft" yatim karena action_ajukan() gagal kena race guard) —
    // insiden nyata pernah terjadi: baris draft/menunggu yang lebih baru
    // menutupi klaim lain yang sebenarnya sudah disetujui pengurus.
    final myOrangJson = await api.callKw(model: 'tarombo.orang', method: 'get_my_orang', args: const []);
    if (myOrangJson is Map) {
      return KlaimInfo(status: KlaimStatus.disetujui, orang: MyOrang.fromJson(myOrangJson.cast<String, dynamic>()));
    }

    // Belum tertaut ke siapa pun — cari riwayat pengajuan klaim TERAKHIR
    // yang benar-benar berhasil diajukan (tanggal_ajukan terisi), supaya
    // baris "draft" yatim (create() sukses, action_ajukan() gagal) tidak
    // pernah dianggap sebagai status yang sah.
    final rows = await api.callKw(
      model: 'tarombo.klaim_akun',
      method: 'search_read',
      args: [
        [
          ['tanggal_ajukan', '!=', false]
        ]
      ],
      kwargs: {
        'fields': ['state', 'alasan_tolak'],
        'order': 'id desc',
        'limit': 1,
      },
    ) as List;

    if (rows.isEmpty) {
      return const KlaimInfo(status: KlaimStatus.belum);
    }

    final row = rows.first as Map<String, dynamic>;
    return KlaimInfo(
      status: KlaimInfo.statusFromServer(row['state'] as String),
      alasanTolak: asOdooString(row['alasan_tolak']),
    );
  }

  Future<void> ajukanOrangAda({required int orangId, String? catatan}) async {
    final api = ref.read(apiClientProvider);
    final klaimId = await api.callKw(
      model: 'tarombo.klaim_akun',
      method: 'create',
      args: [
        {
          'jenis': 'orang_ada',
          'orang_id': orangId,
          if (catatan != null && catatan.isNotEmpty) 'catatan_pengklaim': catatan,
        }
      ],
    );
    await api.callKw(model: 'tarombo.klaim_akun', method: 'action_ajukan', args: [
      [klaimId]
    ]);
    ref.invalidateSelf();
    await future;
  }

  Future<void> ajukanOrangBaru({
    required Map<String, dynamic> usulanVals,
    String? catatan,
  }) async {
    final api = ref.read(apiClientProvider);
    final usulanId = await api.callKw(model: 'tarombo.usulan', method: 'create', args: [usulanVals]);
    final klaimId = await api.callKw(
      model: 'tarombo.klaim_akun',
      method: 'create',
      args: [
        {
          'jenis': 'orang_baru',
          'usulan_id': usulanId,
          if (catatan != null && catatan.isNotEmpty) 'catatan_pengklaim': catatan,
        }
      ],
    );
    await api.callKw(model: 'tarombo.klaim_akun', method: 'action_ajukan', args: [
      [klaimId]
    ]);
    ref.invalidateSelf();
    await future;
  }
}
