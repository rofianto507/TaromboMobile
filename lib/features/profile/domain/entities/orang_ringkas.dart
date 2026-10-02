import '../../../arsip/domain/entities/arsip_item.dart';

class OrangRingkas {
  final int id;
  final String name;
  final int sundut;
  final String jenisKelamin;
  final String? punguan;
  // Relatif terhadap orang acuan: untuk leluhur = jarak generasi ke atas,
  // untuk anak = urutan lahir ("anak ke-N", dari field `urutan` backend).
  final int level;
  final bool masihHidup;
  final int
  jumlahAnak; // supaya kelihatan cabang ini masih berlanjut atau tidak, tanpa perlu buka profilnya

  const OrangRingkas({
    required this.id,
    required this.name,
    required this.sundut,
    required this.jenisKelamin,
    this.punguan,
    this.level = 0,
    this.masihHidup = true,
    this.jumlahAnak = 0,
  });
}

class PernikahanRingkas {
  final int id;
  final int urutan;
  final String istriNama;
  final String? istriMarga;
  final int? tahun;
  final int jumlahAnak;

  const PernikahanRingkas({
    required this.id,
    required this.urutan,
    required this.istriNama,
    this.istriMarga,
    this.tahun,
    this.jumlahAnak = 0,
  });
}

class PendidikanRingkas {
  final String? jenjang;
  final String institusi;
  final String? jurusan;
  final int? tahunMasuk;
  final int? tahunLulus;
  final bool lulus;

  const PendidikanRingkas({
    this.jenjang,
    required this.institusi,
    this.jurusan,
    this.tahunMasuk,
    this.tahunLulus,
    this.lulus = true,
  });
}

class PekerjaanRingkas {
  final String jabatan;
  final String? instansi;
  final String? bidang;
  final int? tahunMulai;
  final int? tahunSelesai;
  final bool sekarang;

  const PekerjaanRingkas({
    required this.jabatan,
    this.instansi,
    this.bidang,
    this.tahunMulai,
    this.tahunSelesai,
    this.sekarang = false,
  });
}

class DomisiliInfo {
  final String? lengkap;
  final String? alamatJalan;
  final String? catatan;
  final String? negara;
  final bool berbagiLokasi;
  final double? lat;
  final double? lng;

  const DomisiliInfo({
    this.lengkap,
    this.alamatJalan,
    this.catatan,
    this.negara,
    this.berbagiLokasi = false,
    this.lat,
    this.lng,
  });
}

class ProfileDetail {
  final int id;
  final String name;
  final int sundut;
  final int? umur;
  final String jenisKelamin;
  final String status;
  final String? punguan;
  final int? ayahId;
  final String? ayahName;
  final List<OrangRingkas>
  leluhur; // urut dari ayah (terdekat) ke leluhur puncak
  // Sengaja HANYA anak langsung (bukan seluruh sub-pohon keturunan diratakan)
  // — daftar keturunan sampai berpuluh-puluh generasi campur aduk bikin
  // halaman ini terasa penuh data yang tidak relevan. Untuk lihat keturunan
  // lebih jauh, buka profil salah satu anaknya (pola sama seperti leluhur).
  final List<OrangRingkas> anak;

  final DomisiliInfo domisili;
  // Untuk orang yang menikah keluar dari garis marga (biasanya perempuan) —
  // pasangannya bukan record tarombo.orang, cuma nama+marga.
  final String? suamiNama;
  final String? suamiMarga;
  final List<PernikahanRingkas> pernikahan;
  final List<PendidikanRingkas> pendidikan;
  final List<PekerjaanRingkas> pekerjaan;
  final List<ArsipItem> arsip;

  const ProfileDetail({
    required this.id,
    required this.name,
    required this.sundut,
    this.umur,
    required this.jenisKelamin,
    required this.status,
    this.punguan,
    this.ayahId,
    this.ayahName,
    this.leluhur = const [],
    this.anak = const [],
    this.domisili = const DomisiliInfo(),
    this.suamiNama,
    this.suamiMarga,
    this.pernikahan = const [],
    this.pendidikan = const [],
    this.pekerjaan = const [],
    this.arsip = const [],
  });
}
