/// Satu wilayah beserta jumlah anggota yang berdomisili di sana.
class TitikWilayah {
  final int id;
  final String nama;
  final String namaLengkap;
  final int jumlah;
  final double? lat;
  final double? lng;

  /// True bila wilayah ini belum punya koordinat sendiri sehingga memakai
  /// koordinat induknya (mis. kecamatan memakai titik kabupaten).
  final bool perkiraan;

  const TitikWilayah({
    required this.id,
    required this.nama,
    required this.namaLengkap,
    required this.jumlah,
    this.lat,
    this.lng,
    this.perkiraan = false,
  });

  bool get punyaTitik => lat != null && lng != null;

  factory TitikWilayah.fromJson(Map<String, dynamic> json) => TitikWilayah(
    id: json['id'] as int,
    nama: json['nama'] as String,
    namaLengkap: (json['nama_lengkap'] as String?) ?? json['nama'] as String,
    jumlah: json['jumlah'] as int,
    lat: json['lat'] is num ? (json['lat'] as num).toDouble() : null,
    lng: json['lng'] is num ? (json['lng'] as num).toDouble() : null,
    perkiraan: json['perkiraan'] == true,
  );
}

/// Hasil `get_sebaran_wilayah` untuk satu tingkat wilayah.
class SebaranWilayah {
  final String tingkat;
  final int totalAnggota;
  final int totalBerwilayah;
  final List<TitikWilayah> items;

  const SebaranWilayah({
    required this.tingkat,
    required this.totalAnggota,
    required this.totalBerwilayah,
    required this.items,
  });

  factory SebaranWilayah.fromJson(Map<String, dynamic> json) => SebaranWilayah(
    tingkat: json['tingkat'].toString(),
    totalAnggota: json['total_anggota'] as int? ?? 0,
    totalBerwilayah: json['total_berwilayah'] as int? ?? 0,
    items: [
      for (final e in (json['items'] as List? ?? const []))
        TitikWilayah.fromJson((e as Map).cast<String, dynamic>()),
    ],
  );
}
