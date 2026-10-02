/// Pemetaan tipe notifikasi -> rute tujuan saat di-tap, dipakai bareng oleh
/// PushService (notifikasi dari FCM) dan layar daftar Notifikasi (riwayat
/// dari tarombo.notifikasi) supaya keduanya konsisten, tidak drift.
String pathUntukTipeNotifikasi(String? tipe) {
  switch (tipe) {
    case 'usulan':
      return '/usulan';
    case 'klaim_akun':
      return '/home';
    default:
      return '/notifikasi';
  }
}
