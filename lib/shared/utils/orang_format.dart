// Format seragam daftar orang di seluruh pencarian aplikasi:
//
//     Horas
//     Sundut 17 • Pungu Robinson
//
// Baris pertama nama lengkap, baris kedua "Sundut N • Nama Ayah" (tanpa
// bagian ayah bila ayah tidak tercatat). Pemisahnya titik tengah "•", sama
// seperti subtitel di bagian lain aplikasi.

/// Field yang perlu diminta ke server agar [subtitleOrang] bisa disusun.
const kOrangSearchFields = ['id', 'name', 'sundut', 'jenis_kelamin', 'ayah_id'];

/// Pencarian baru dijalankan setelah sekurang-kurangnya sekian huruf diketik.
const kMinHurufCari = 2;

/// Jeda ketikan sebelum pencarian dikirim ke server.
const kJedaCari = Duration(milliseconds: 350);

final _akhiranSundut = RegExp(r'\s*\(sundut\s+\d+\)\s*$', caseSensitive: false);

/// display_name Odoo untuk orang berbentuk "Pungu Robinson (sundut 16)";
/// ambil nama murninya saja.
String namaTanpaSundut(String s) => s.replaceFirst(_akhiranSundut, '').trim();

/// Nama ayah dari hasil search_read (ayah_id = [id, display_name] atau false).
String? namaAyah(Map<String, dynamic> row) {
  final v = row['ayah_id'];
  if (v is List && v.length > 1 && v[1] is String) {
    final nama = namaTanpaSundut(v[1] as String);
    return nama.isEmpty ? null : nama;
  }
  return null;
}

/// "Sundut 17 • Pungu Robinson", atau "Sundut 17" bila ayah tidak tercatat.
String subtitleOrang(Map<String, dynamic> row) {
  final sundut = row['sundut'];
  final awal = (sundut == null || sundut == false) ? '' : 'Sundut $sundut';
  final ayah = namaAyah(row);
  if (awal.isEmpty) return ayah ?? '';
  return ayah == null ? awal : '$awal • $ayah';
}
