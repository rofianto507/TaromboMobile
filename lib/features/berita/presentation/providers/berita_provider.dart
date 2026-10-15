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
}

final beritaAksiProvider = Provider((ref) => BeritaAksi(ref));
