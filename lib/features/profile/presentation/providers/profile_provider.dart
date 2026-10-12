import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/odoo_json.dart';
import '../../../arsip/domain/entities/arsip_item.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../profil_saya/presentation/providers/profil_saya_provider.dart';
import '../../domain/entities/orang_ringkas.dart';

final profileDetailProvider = FutureProvider.autoDispose.family<ProfileDetail, int>((
  ref,
  orangId,
) async {
  final api = ref.read(apiClientProvider);

  final rows =
      await api.callKw(
            model: 'tarombo.orang',
            method: 'search_read',
            args: [
              [
                ['id', '=', orangId],
              ],
            ],
            kwargs: {
              'fields': [
                'name',
                'jenis_kelamin',
                'sundut',
                'status',
                'punguan_id',
                'ayah_id',
                'parent_path',
                'umur',
                'domisili_lengkap',
                'alamat_catatan',
                'negara_id',
                'suami_nama',
                'suami_marga_id',
              ],
              'limit': 1,
            },
          )
          as List;
  if (rows.isEmpty) {
    throw Exception('Data orang tidak ditemukan.');
  }
  final row = rows.first as Map<String, dynamic>;

  // ── Leluhur: dibaca langsung dari parent_path ("1/5/12/"), field bawaan
  // Odoo untuk _parent_store — tidak perlu panggilan tambahan ke pohon.
  final pathIds = (asOdooString(row['parent_path']) ?? '')
      .split('/')
      .where((s) => s.isNotEmpty)
      .map(int.parse)
      .toList();
  final ancestorIds = pathIds.length > 1
      ? pathIds.sublist(0, pathIds.length - 1).reversed.toList()
      : <int>[];

  final results = await Future.wait([
    // Leluhur
    ancestorIds.isEmpty
        ? Future.value(const <Map<String, dynamic>>[])
        : api
              .callKw(
                model: 'tarombo.orang',
                method: 'search_read',
                args: [
                  [
                    ['id', 'in', ancestorIds],
                  ],
                ],
                kwargs: {
                  'fields': [
                    'id',
                    'name',
                    'sundut',
                    'jenis_kelamin',
                    'punguan_id',
                    'masih_hidup',
                    'anak_ids',
                  ],
                },
              )
              .then((r) => (r as List).cast<Map<String, dynamic>>()),
    // Anak — sengaja HANYA anak langsung, bukan seluruh sub-pohon keturunan
    // diratakan jadi satu daftar panjang campur generasi.
    api
        .callKw(
          model: 'tarombo.orang',
          method: 'search_read',
          args: [
            [
              ['ayah_id', '=', orangId],
            ],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'sundut',
              'jenis_kelamin',
              'punguan_id',
              'masih_hidup',
              'anak_ids',
            ],
            'order': 'urutan',
          },
        )
        .then((r) => (r as List).cast<Map<String, dynamic>>()),
    // Pernikahan (kalau orang ini suami di satu/lebih pernikahan)
    api
        .callKw(
          model: 'tarombo.pernikahan',
          method: 'search_read',
          args: [
            [
              ['suami_id', '=', orangId],
            ],
          ],
          kwargs: {
            'fields': [
              'id',
              'urutan',
              'istri_nama',
              'istri_marga_id',
              'tahun',
              'anak_ids',
            ],
            'order': 'urutan',
          },
        )
        .then((r) => (r as List).cast<Map<String, dynamic>>()),
    // Riwayat pendidikan
    api
        .callKw(
          model: 'tarombo.pendidikan',
          method: 'search_read',
          args: [
            [
              ['orang_id', '=', orangId],
            ],
          ],
          kwargs: {
            'fields': [
              'id',
              'jenjang',
              'institusi',
              'jurusan',
              'tahun_masuk',
              'tahun_lulus',
              'lulus',
            ],
          },
        )
        .then((r) => (r as List).cast<Map<String, dynamic>>()),
    // Riwayat pekerjaan
    api
        .callKw(
          model: 'tarombo.pekerjaan',
          method: 'search_read',
          args: [
            [
              ['orang_id', '=', orangId],
            ],
          ],
          kwargs: {
            'fields': [
              'id',
              'jabatan',
              'instansi',
              'bidang_id',
              'tahun_mulai',
              'tahun_selesai',
              'sekarang',
            ],
          },
        )
        .then((r) => (r as List).cast<Map<String, dynamic>>()),
    // Arsip terkait — ir.rule sudah menyaring anggota hanya lihat yang publik
    api
        .callKw(
          model: 'tarombo.arsip',
          method: 'search_read',
          args: [
            [
              ['orang_id', '=', orangId],
            ],
          ],
          kwargs: {
            'fields': [
              'id',
              'name',
              'jenis',
              'orang_id',
              'punguan_id',
              'tahun_perkiraan',
            ],
          },
        )
        .then((r) => (r as List).cast<Map<String, dynamic>>()),
    // Titik lokasi domisili — cuma terisi kalau orang ini berbagi_lokasi=True
    api
        .callKw(
          model: 'tarombo.orang',
          method: 'get_domisili_orang',
          args: [orangId],
        )
        .then((r) => r as Map<String, dynamic>),
    // Kontak (telepon & email) — server mengembalikan kosong untuk akun yang
    // belum terverifikasi, jadi tidak perlu cek status di sini.
    api
        .callKw(
          model: 'tarombo.orang',
          method: 'get_kontak_orang',
          args: [orangId],
        )
        .then((r) => r as Map<String, dynamic>)
        .catchError((_) => <String, dynamic>{}),
  ]);

  final ancestorRows = results[0] as List<Map<String, dynamic>>;
  final anakRows = results[1] as List<Map<String, dynamic>>;
  final pernikahanRows = results[2] as List<Map<String, dynamic>>;
  final pendidikanRows = results[3] as List<Map<String, dynamic>>;
  final pekerjaanRows = results[4] as List<Map<String, dynamic>>;
  final arsipRows = results[5] as List<Map<String, dynamic>>;
  final domisiliMap = results[6] as Map<String, dynamic>;
  final kontakMap = results[7] as Map<String, dynamic>;

  final byId = {for (final r in ancestorRows) r['id'] as int: r};
  final leluhur = [
    for (var i = 0; i < ancestorIds.length; i++)
      if (byId[ancestorIds[i]] != null)
        _toRingkas(byId[ancestorIds[i]]!, level: i + 1),
  ];
  // level di sini dipakai sebagai urutan lahir ("Anak ke-1", "Anak ke-2", ...)
  // — beda makna dari level pada leluhur (jarak generasi), lihat komentar di
  // OrangRingkas.level.
  final anak = [
    for (var i = 0; i < anakRows.length; i++)
      _toRingkas(anakRows[i], level: i + 1),
  ];

  final pernikahan = pernikahanRows
      .map(
        (r) => PernikahanRingkas(
          id: r['id'] as int,
          urutan: r['urutan'] as int? ?? 1,
          istriNama: asOdooString(r['istri_nama']) ?? '',
          istriMarga: _m2oName(r['istri_marga_id']),
          tahun: r['tahun'] == false ? null : r['tahun'] as int?,
          jumlahAnak: (r['anak_ids'] as List? ?? const []).length,
        ),
      )
      .toList();

  final pendidikan = pendidikanRows
      .map(
        (r) => PendidikanRingkas(
          id: r['id'] as int,
          jenjang: asOdooString(r['jenjang']),
          institusi: asOdooString(r['institusi']) ?? '-',
          jurusan: asOdooString(r['jurusan']),
          tahunMasuk: _tahun(r['tahun_masuk']),
          tahunLulus: _tahun(r['tahun_lulus']),
          lulus: r['lulus'] == true,
        ),
      )
      .toList();

  final pekerjaan = pekerjaanRows
      .map(
        (r) => PekerjaanRingkas(
          id: r['id'] as int,
          jabatan: asOdooString(r['jabatan']) ?? '-',
          instansi: asOdooString(r['instansi']),
          bidang: _m2oName(r['bidang_id']),
          tahunMulai: _tahun(r['tahun_mulai']),
          tahunSelesai: _tahun(r['tahun_selesai']),
          sekarang: r['sekarang'] == true,
        ),
      )
      .toList();

  final arsip = arsipRows.map(ArsipItem.fromJson).toList();

  final domisili = DomisiliInfo(
    lengkap: asOdooString(row['domisili_lengkap']),
    alamatJalan: asOdooString(domisiliMap['alamat_jalan']),
    catatan: asOdooString(row['alamat_catatan']),
    negara: _m2oName(row['negara_id']),
    berbagiLokasi: domisiliMap['berbagi_lokasi'] == true,
    lat: domisiliMap['lat'] is num
        ? (domisiliMap['lat'] as num).toDouble()
        : null,
    lng: domisiliMap['lng'] is num
        ? (domisiliMap['lng'] as num).toDouble()
        : null,
  );

  return ProfileDetail(
    id: row['id'] as int,
    name: row['name'] as String,
    jenisKelamin: row['jenis_kelamin'] as String,
    sundut: row['sundut'] as int,
    umur: row['umur'] == false ? null : row['umur'] as int?,
    status: asOdooString(row['status']) ?? 'rumpang',
    punguan: _m2oName(row['punguan_id']),
    ayahId: _m2oId(row['ayah_id']),
    ayahName: _m2oName(row['ayah_id']),
    leluhur: leluhur,
    anak: anak,
    domisili: domisili,
    kontakTerverifikasi: kontakMap['terverifikasi'] == true,
    noTelp: asOdooString(kontakMap['no_telp']),
    emailKontak: asOdooString(kontakMap['email_kontak']),
    suamiNama: asOdooString(row['suami_nama']),
    suamiMarga: _m2oName(row['suami_marga_id']),
    pernikahan: pernikahan,
    pendidikan: pendidikan,
    pekerjaan: pekerjaan,
    arsip: arsip,
  );
});

OrangRingkas _toRingkas(Map<String, dynamic> r, {int level = 0}) =>
    OrangRingkas(
      id: r['id'] as int,
      name: r['name'] as String,
      sundut: r['sundut'] as int,
      jenisKelamin: r['jenis_kelamin'] as String,
      punguan: _m2oName(r['punguan_id']),
      level: level,
      masihHidup: r['masih_hidup'] == true,
      jumlahAnak: (r['anak_ids'] as List? ?? const []).length,
    );

/// Integer Odoo yang kosong dikirim 0 (bukan false) — anggap bukan tahun.
int? _tahun(dynamic v) => (v is int && v > 0) ? v : null;

/// Tambah / hapus riwayat pendidikan & pekerjaan milik sendiri. Tanpa
/// persetujuan pengurus: dibatasi ir.rule backend (orang_id.user_id = akun ini).
class RiwayatRepository {
  final Ref ref;
  RiwayatRepository(this.ref);

  Future<void> tambahPendidikan(int orangId, Map<String, dynamic> vals) =>
      _create('tarombo.pendidikan', orangId, vals);

  Future<void> tambahPekerjaan(int orangId, Map<String, dynamic> vals) =>
      _create('tarombo.pekerjaan', orangId, vals);

  Future<void> hapusPendidikan(int orangId, int id) =>
      _delete('tarombo.pendidikan', orangId, id);

  Future<void> hapusPekerjaan(int orangId, int id) =>
      _delete('tarombo.pekerjaan', orangId, id);

  Future<void> _create(
    String model,
    int orangId,
    Map<String, dynamic> vals,
  ) async {
    await ref
        .read(apiClientProvider)
        .callKw(
          model: model,
          method: 'create',
          args: [
            {...vals, 'orang_id': orangId},
          ],
        );
    ref.invalidate(profileDetailProvider(orangId));
    // Riwayat ikut dihitung di kartu kelengkapan profil.
    ref.invalidate(profilSayaProvider);
  }

  Future<void> _delete(String model, int orangId, int id) async {
    await ref
        .read(apiClientProvider)
        .callKw(
          model: model,
          method: 'unlink',
          args: [
            [id],
          ],
        );
    ref.invalidate(profileDetailProvider(orangId));
    // Riwayat ikut dihitung di kartu kelengkapan profil.
    ref.invalidate(profilSayaProvider);
  }
}

final riwayatRepositoryProvider = Provider<RiwayatRepository>(
  (ref) => RiwayatRepository(ref),
);

String? _m2oName(dynamic v) =>
    (v is List && v.length > 1) ? v[1] as String : null;
int? _m2oId(dynamic v) => (v is List && v.isNotEmpty) ? v[0] as int : null;
