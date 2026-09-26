class OrangRingkas {
  final int id;
  final String name;
  final int sundut;
  final String jenisKelamin;
  final String? punguan;
  final int level; // relatif terhadap orang acuan: leluhur = jarak ke atas, keturunan = jarak ke bawah

  const OrangRingkas({
    required this.id,
    required this.name,
    required this.sundut,
    required this.jenisKelamin,
    this.punguan,
    this.level = 0,
  });
}

class ProfileDetail {
  final int id;
  final String name;
  final int sundut;
  final String jenisKelamin;
  final String status;
  final String? punguan;
  final int? ayahId;
  final String? ayahName;
  final List<OrangRingkas> leluhur; // urut dari ayah (terdekat) ke leluhur puncak
  final List<OrangRingkas> keturunan; // urut generasi, dibatasi server (maks 4 turunan / 200 simpul)
  final bool keturunanMungkinTerpotong;

  const ProfileDetail({
    required this.id,
    required this.name,
    required this.sundut,
    required this.jenisKelamin,
    required this.status,
    this.punguan,
    this.ayahId,
    this.ayahName,
    this.leluhur = const [],
    this.keturunan = const [],
    this.keturunanMungkinTerpotong = false,
  });
}
