import '../../../../shared/utils/odoo_json.dart';

/// Waktu dari server (UTC, "YYYY-MM-DD HH:MM:SS") menjadi waktu lokal.
DateTime? _waktu(dynamic v) {
  final s = asOdooString(v);
  if (s == null) return null;
  return DateTime.tryParse('${s.replaceFirst(' ', 'T')}Z')?.toLocal();
}

class BeritaRingkas {
  final int id;
  final String judul;
  final String jenis; // 'berita' | 'agenda'
  final String? ringkasan;
  final DateTime? tanggalTerbit;
  final DateTime? tanggalMulai;
  final DateTime? tanggalSelesai;
  final String? lokasi;
  final bool sudahLewat;
  final bool punyaGambar;
  final int jumlahKomentar;

  const BeritaRingkas({
    required this.id,
    required this.judul,
    required this.jenis,
    this.ringkasan,
    this.tanggalTerbit,
    this.tanggalMulai,
    this.tanggalSelesai,
    this.lokasi,
    this.sudahLewat = false,
    this.punyaGambar = false,
    this.jumlahKomentar = 0,
  });

  bool get agenda => jenis == 'agenda';

  factory BeritaRingkas.fromJson(Map<String, dynamic> j) => BeritaRingkas(
    id: j['id'] as int,
    judul: j['judul'] as String,
    jenis: (j['jenis'] as String?) ?? 'berita',
    ringkasan: asOdooString(j['ringkasan']),
    tanggalTerbit: _waktu(j['tanggal_terbit']),
    tanggalMulai: _waktu(j['tanggal_mulai']),
    tanggalSelesai: _waktu(j['tanggal_selesai']),
    lokasi: asOdooString(j['lokasi']),
    sudahLewat: j['sudah_lewat'] == true,
    punyaGambar: j['punya_gambar'] == true,
    jumlahKomentar: (j['jumlah_komentar'] as num?)?.toInt() ?? 0,
  );
}

class KomentarBerita {
  final int id;
  final String penulis;
  final int? orangId;
  final DateTime? tanggal;
  final String isi;
  final bool milikSendiri;
  final bool pengurus;

  const KomentarBerita({
    required this.id,
    required this.penulis,
    this.orangId,
    this.tanggal,
    required this.isi,
    this.milikSendiri = false,
    this.pengurus = false,
  });

  factory KomentarBerita.fromJson(Map<String, dynamic> j) => KomentarBerita(
    id: j['id'] as int,
    penulis: (j['penulis'] as String?) ?? 'Anggota',
    orangId: j['orang_id'] is int ? j['orang_id'] as int : null,
    tanggal: _waktu(j['tanggal']),
    isi: (j['isi'] as String?) ?? '',
    milikSendiri: j['milik_sendiri'] == true,
    pengurus: j['pengurus'] == true,
  );
}

class BeritaDetail {
  final BeritaRingkas ringkas;
  final String? isiHtml;
  final String? penulis;
  final List<KomentarBerita> komentar;

  const BeritaDetail({
    required this.ringkas,
    this.isiHtml,
    this.penulis,
    this.komentar = const [],
  });

  factory BeritaDetail.fromJson(Map<String, dynamic> j) => BeritaDetail(
    ringkas: BeritaRingkas.fromJson(j),
    isiHtml: asOdooString(j['isi']),
    penulis: asOdooString(j['penulis']),
    komentar: [
      for (final k in (j['komentar'] as List? ?? const []))
        KomentarBerita.fromJson((k as Map).cast<String, dynamic>()),
    ],
  );
}
