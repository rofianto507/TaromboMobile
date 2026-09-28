import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/klaim_info.dart';

final klaimNotifierProvider = AsyncNotifierProvider<KlaimNotifier, KlaimInfo>(KlaimNotifier.new);

/// Sengaja StateProvider biasa (in-memory, BUKAN secure storage/shared
/// preferences): begitu proses aplikasi di-restart (cold start), nilainya
/// balik ke false lagi — ini yang bikin pengingat klaim identitas "selalu
/// muncul lagi tiap kali buka app dari awal" walau tadinya sempat di-skip,
/// sesuai permintaan eksplisit user. Kalau ini disimpan permanen, pengguna
/// yang sekali skip tidak akan pernah diingatkan lagi selamanya.
final klaimReminderDismissedProvider = StateProvider<bool>((ref) => false);

class KlaimNotifier extends AsyncNotifier<KlaimInfo> {
  @override
  Future<KlaimInfo> build() async {
    // WAJIB nunggu authNotifierProvider selesai resolve duluan (bukan cuma
    // ref.read yang bisa balikin state lama) — sebelumnya build() ini
    // langsung memanggil API begitu appRouterProvider dibuat, lewat
    // ref.listen(klaimNotifierProvider, ...) di app_router.dart yang secara
    // tidak sengaja membuat provider ini instantiate SEJAK APLIKASI BARU
    // DIBUKA, sebelum ada sesi login sama sekali. Panggilan API tanpa sesi
    // itu gagal, provider ini KETERUSAN nyangkut di state error itu, dan
    // TIDAK ADA yang otomatis memicu fetch ulang setelah login berhasil —
    // makanya selalu nyangkut di layar Klaim Identitas sampai tombol reload
    // ditekan manual. Dengan ref.watch(...future) di sini, provider ini
    // otomatis rebuild kapan pun status login berubah (termasuk begitu login
    // sukses), dan tidak pernah memanggil API sama sekali selagi belum login.
    final authUser = await ref.watch(authNotifierProvider.future);
    if (authUser == null) {
      return const KlaimInfo(status: KlaimStatus.belum);
    }

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
