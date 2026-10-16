import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/berita.dart';

/// Hingga 5 berita/agenda terbit paling baru untuk slider di beranda.
final beritaBerandaProvider = FutureProvider.autoDispose<List<BeritaRingkas>>((
  ref,
) async {
  final api = ref.read(apiClientProvider);
  final json =
      await api.callKw(
            model: 'tarombo.berita',
            method: 'get_beranda',
            args: const [],
          )
          as Map;
  return [
    for (final e in (json['items'] as List? ?? const []))
      BeritaRingkas.fromJson((e as Map).cast<String, dynamic>()),
  ];
});

/// Daftar lengkap. [jenis] null = berita dan agenda.
final beritaDaftarProvider = FutureProvider.autoDispose
    .family<List<BeritaRingkas>, String?>((ref, jenis) async {
      final api = ref.read(apiClientProvider);
      final rows =
          await api.callKw(
                model: 'tarombo.berita',
                method: 'get_daftar',
                args: [jenis ?? false],
              )
              as List;
      return [
        for (final e in rows)
          BeritaRingkas.fromJson((e as Map).cast<String, dynamic>()),
      ];
    });

final beritaDetailProvider = FutureProvider.autoDispose
    .family<BeritaDetail, int>((ref, id) async {
      final api = ref.read(apiClientProvider);
      final json =
          await api.callKw(
                model: 'tarombo.berita',
                method: 'get_detail',
                args: [id],
              )
              as Map;
      return BeritaDetail.fromJson(json.cast<String, dynamic>());
    });

/// Alasan laporan komentar: kode server -> label.
const alasanLaporan = <(String, String)>[
  ('spam', 'Spam atau iklan'),
  ('kasar', 'Kasar, menghina, atau melecehkan'),
  ('sara', 'Menyinggung SARA atau ujaran kebencian'),
  ('tidak_pantas', 'Konten tidak pantas atau berbahaya'),
  ('pribadi', 'Membocorkan data pribadi'),
  ('lainnya', 'Lainnya'),
];

const _kBlokir = 'berita_blokir_orang';
const _kAturan = 'aturan_komentar_diterima';

/// Daftar anggota (id orang) yang komentarnya disembunyikan di perangkat ini,
/// serta penanda bahwa pengguna sudah menyetujui Aturan Komentar. Disimpan
/// lokal (secure storage); tidak dikirim ke server.
class KomentarPrefs {
  final Ref ref;
  KomentarPrefs(this.ref);

  Future<Set<int>> ambilBlokir() async {
    final raw = await ref.read(secureStorageProvider).read(key: _kBlokir);
    if (raw == null || raw.isEmpty) return <int>{};
    return raw.split(',').map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> _simpanBlokir(Set<int> s) async {
    await ref
        .read(secureStorageProvider)
        .write(key: _kBlokir, value: s.join(','));
    ref.invalidate(blokirProvider);
  }

  Future<void> blokir(int orangId) async {
    final s = await ambilBlokir();
    await _simpanBlokir({...s, orangId});
  }

  Future<void> bukaSemuaBlokir() => _simpanBlokir(<int>{});

  Future<bool> aturanDiterima() async =>
      (await ref.read(secureStorageProvider).read(key: _kAturan)) == '1';

  Future<void> terimaAturan() =>
      ref.read(secureStorageProvider).write(key: _kAturan, value: '1');
}

final komentarPrefsProvider = Provider((ref) => KomentarPrefs(ref));

final blokirProvider = FutureProvider.autoDispose<Set<int>>(
  (ref) => ref.read(komentarPrefsProvider).ambilBlokir(),
);

class BeritaAksi {
  final Ref ref;
  BeritaAksi(this.ref);

  List<KomentarBerita> _komentar(dynamic rows) => [
    for (final k in (rows as List))
      KomentarBerita.fromJson((k as Map).cast<String, dynamic>()),
  ];

  Future<List<KomentarBerita>> kirimKomentar(int beritaId, String isi) async {
    final api = ref.read(apiClientProvider);
    final rows = await api.callKw(
      model: 'tarombo.berita',
      method: 'tambah_komentar',
      args: [beritaId, isi],
    );
    ref.invalidate(beritaDetailProvider(beritaId));
    ref.invalidate(beritaBerandaProvider);
    return _komentar(rows);
  }

  Future<void> hapusKomentar(int beritaId, int pesanId) async {
    final api = ref.read(apiClientProvider);
    await api.callKw(
      model: 'tarombo.berita',
      method: 'hapus_komentar',
      args: [pesanId],
    );
    ref.invalidate(beritaDetailProvider(beritaId));
    ref.invalidate(beritaBerandaProvider);
  }

  /// Laporkan komentar ke pengurus.
  Future<void> laporkanKomentar(
    int pesanId,
    String alasan, {
    String? catatan,
  }) async {
    final api = ref.read(apiClientProvider);
    await api.callKw(
      model: 'tarombo.berita',
      method: 'laporkan_komentar',
      args: [pesanId, alasan, catatan ?? false],
    );
  }
}

final beritaAksiProvider = Provider((ref) => BeritaAksi(ref));
