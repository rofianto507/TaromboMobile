enum KlaimStatus { belum, menunggu, disetujui, ditolak }

class MyOrang {
  final int id;
  final String name;
  final int sundut;
  final bool punyaFoto;
  final bool berbagiLokasi;

  const MyOrang({
    required this.id,
    required this.name,
    required this.sundut,
    required this.punyaFoto,
    required this.berbagiLokasi,
  });

  factory MyOrang.fromJson(Map<String, dynamic> json) => MyOrang(
    id: json['id'] as int,
    name: json['name'] as String,
    sundut: json['sundut'] as int,
    punyaFoto: json['punya_foto'] as bool,
    berbagiLokasi: json['berbagi_lokasi'] as bool,
  );
}

class KlaimInfo {
  final KlaimStatus status;
  final String? alasanTolak;
  final MyOrang? orang;
  // Jenis klaim terakhir ('orang_ada', 'orang_baru', 'banding') dan nama
  // orang yang diklaim, untuk teks halaman Status Klaim.
  final String? jenis;
  // id klaim yang sedang menunggu, untuk tombol Batalkan Pengajuan.
  final int? klaimId;
  final String? namaDiklaim;

  const KlaimInfo({
    required this.status,
    this.alasanTolak,
    this.orang,
    this.jenis,
    this.klaimId,
    this.namaDiklaim,
  });

  bool get banding => jenis == 'banding';

  static KlaimStatus statusFromServer(String state) {
    switch (state) {
      case 'menunggu':
        return KlaimStatus.menunggu;
      case 'disetujui':
        return KlaimStatus.disetujui;
      case 'ditolak':
        return KlaimStatus.ditolak;
      default:
        return KlaimStatus.belum;
    }
  }
}
