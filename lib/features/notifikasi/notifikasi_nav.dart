/// Pemetaan tipe notifikasi -> rute tujuan saat di-tap, dipakai bareng oleh
/// PushService (notifikasi dari FCM) dan layar daftar Notifikasi (riwayat
/// dari tarombo.notifikasi) supaya keduanya konsisten, tidak drift.
///
/// [data] memuat payload tambahan (mis. `berita_id`); nilainya dari FCM
/// berupa String, dari riwayat berupa int, jadi keduanya ditangani.
String pathUntukTipeNotifikasi(String? tipe, [Map<String, dynamic>? data]) {
  switch (tipe) {
    case 'berita':
      final id = int.tryParse('${data?['berita_id'] ?? ''}');
      return id != null ? '/berita/$id' : '/berita';
    case 'usulan':
      return '/usulan';
    case 'klaim_akun':
      return '/home';
    default:
      return '/notifikasi';
  }
}
