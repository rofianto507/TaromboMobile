<p align="center">
  <img src="docs/banner.png" alt="Tarombo - Silsilah Marga Silaen" width="100%">
</p>

<h1 align="center">TaromboMobile</h1>

<p align="center">
  <b>Aplikasi silsilah keluarga marga Silaen</b><br>
  <i>Telusuri tarombo &bull; Kenali kerabat</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.12-2E5339?style=flat-square&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/versi-1.0.11%2B16-C8A24A?style=flat-square" alt="Versi 1.0.11+16">
  <img src="https://img.shields.io/badge/backend-Odoo%2019-2E5339?style=flat-square" alt="Odoo 19">
  <a href="https://play.google.com/store/apps/details?id=id.selstudio.tarombo_mobile"><img src="https://img.shields.io/badge/Google%20Play-Unduh-2E5339?style=flat-square&logo=googleplay&logoColor=white" alt="Google Play"></a>
  <a href="https://apps.apple.com/id/app/tarombo/id6824446485"><img src="https://img.shields.io/badge/App%20Store-Unduh-C8A24A?style=flat-square&logo=apple&logoColor=white" alt="App Store"></a>
</p>

---

<img src="docs/logo.png" alt="Logo Punguan Raja Silaen & Boruna" width="96" align="left" hspace="12">

Aplikasi mobile yang terhubung ke backend **Odoo 19** ([modul `tarombo`](https://github.com/rofianto507/tarombo)). Dibangun dengan Flutter, aplikasi ini memungkinkan anggota menelusuri pohon keluarga, mengenali hubungan kekerabatan adat (partuturan), mengikuti berita dan agenda punguan, mengajukan usulan data, serta mengelola arsip keluarga.

Tersedia di **Google Play** (Android) dan **App Store** (iOS, target iOS 15.0).

<br clear="left">

---

## Tampilan Aplikasi

<table>
  <tr>
    <td><img src="docs/screenshots/01-pohon-tarombo.png" width="200" alt="Pohon tarombo"/></td>
    <td><img src="docs/screenshots/02-beranda.png" width="200" alt="Beranda"/></td>
    <td><img src="docs/screenshots/03-partuturan.png" width="200" alt="Partuturan"/></td>
    <td><img src="docs/screenshots/04-usulan.png" width="200" alt="Usulan data"/></td>
  </tr>
  <tr>
    <td><img src="docs/screenshots/05-kontak.png" width="200" alt="Kontak dan domisili"/></td>
    <td><img src="docs/screenshots/06-berita-agenda.png" width="200" alt="Berita dan agenda"/></td>
    <td><img src="docs/screenshots/07-sebaran-anggota.png" width="200" alt="Sebaran anggota"/></td>
    <td><img src="docs/screenshots/08-arsip.png" width="200" alt="Arsip keluarga"/></td>
  </tr>
</table>

> Seluruh tangkapan layar memakai data uji.

---

## Fitur Utama

| Fitur | Deskripsi |
|---|---|
| 🔐 **Autentikasi** | Login dengan akun biasa atau Google; sesi disimpan aman (`flutter_secure_storage`) |
| 🌲 **Pohon Tarombo** | Penelusuran silsilah antar generasi (sundut), lengkap dengan marga dan daftar istri; pohon dapat dibagikan |
| ✅ **Akun Terverifikasi** | Lencana centang biru untuk anggota yang akunnya sudah diverifikasi pengurus |
| 🧮 **Partuturan** | Hubungan dan sebutan kekerabatan adat antara dua anggota, lengkap dengan penjelasannya |
| 📰 **Berita & Agenda** | Kabar dan jadwal punguan di beranda, bisa dibagikan, dengan komentar (laporkan dan blokir tersedia) |
| 📇 **Kontak & Domisili** | Telepon, email, dan domisili sampai desa/kelurahan; hanya untuk akun terverifikasi |
| 🗺️ **Sebaran Anggota** | Jumlah anggota per provinsi atau kabupaten/kota di peta (`flutter_map`), tanpa lokasi rumah |
| 📝 **Usulan Data** | Ajukan penambahan anggota (nomor "Anak ke-" disarankan otomatis), koreksi, atau data istri untuk ditinjau pengurus, dengan percakapan dua arah |
| 👤 **Profil Saya** | Lengkapi foto, tahun lahir, domisili, kontak, serta riwayat pendidikan dan pekerjaan sendiri tanpa menunggu pengurus |
| 📂 **Arsip Keluarga** | Dokumen, foto, audio, dan video; satu arsip dapat terkait banyak anggota |
| 📋 **Direktori Keahlian** | Cari anggota berdasarkan profesi atau keahlian |
| 🪪 **Klaim Akun & Banding** | Tautkan akun ke nama di pohon; ajukan banding bila nama sudah diklaim akun lain |
| 🔔 **Notifikasi & Masukan** | Push notification (FCM) dan kotak notifikasi untuk status pengajuan, berita, dan pesan pengurus; kirim masukan dari menu Akun |
| 🔑 **Kata Sandi** | Akun yang masuk lewat Google dapat menetapkan kata sandi; yang sudah punya dapat mengubahnya (menu Akun) |

---

## Teknologi & Dependensi

| Kategori | Package |
|---|---|
| State Management | `flutter_riverpod` ^2.6.1 |
| Navigasi | `go_router` ^14.8.1 |
| HTTP Client | `dio` ^5.8.0 |
| Penyimpanan Aman | `flutter_secure_storage` ^9.2.2 |
| Peta & GPS | `flutter_map` ^7.0.2 · `geolocator` ^13.0.2 · `latlong2` ^0.9.1 |
| Gambar | `image_picker` ^1.1.2 · `cached_network_image` ^3.4.1 |
| Arsip / File | `path_provider` ^2.1.5 · `open_filex` ^4.5.0 |
| Berbagi | `share_plus` ^12.0.2 |
| Visualisasi Pohon | `graphview` ^1.5.1 |
| Login Google | `google_sign_in` ^6.2.2 |
| Push Notification | `firebase_core` · `firebase_messaging` · `flutter_local_notifications` |
| Konten Berita | `flutter_html` ^3.0.0 · `file_picker` · `url_launcher` |
| Lokalisasi | `flutter_localizations` · `intl` ^0.20.2 |
| Backend | Odoo 19 (modul `tarombo`) via JSON-RPC / REST |

---

## Struktur Proyek

```
lib/
├── main.dart
├── core/
│   ├── config/         # Konfigurasi environment (BASE_URL, DB_NAME, dll.)
│   ├── constants/      # Konstanta aplikasi
│   ├── error/          # Penanganan error global
│   ├── network/        # Dio client & interceptor session
│   ├── router/         # go_router — definisi semua rute
│   └── theme/          # Tema Material (warna, tipografi)
├── features/
│   ├── auth/           # Login, logout, provider autentikasi
│   ├── home/           # Beranda: menu utama, slider berita & agenda
│   ├── shell/          # Navigasi bawah (Beranda, Tarombo, Akun)
│   ├── tarombo_tree/   # Pohon silsilah (tab Tarombo), bagikan pohon
│   ├── profile/        # Profil anggota lain (tab Kontak, Riwayat, dst.)
│   ├── profil_saya/    # Lengkapi & ubah data diri sendiri
│   ├── partuturan/     # Hubungan kekerabatan adat
│   ├── usulan/         # Usulan perubahan data + percakapan
│   ├── klaim/          # Klaim akun, banding, percakapan klaim
│   ├── registration/   # Pendaftaran akun
│   ├── berita/         # Berita & agenda, komentar (laporkan/blokir)
│   ├── notifikasi/     # Kotak notifikasi
│   ├── push/           # Layanan push notification (FCM)
│   ├── masukan/        # Kirim masukan/laporan
│   ├── account/        # Menu Akun, atur kata sandi
│   ├── nearby_map/     # Sebaran Anggota per wilayah (route /peta-kerabat)
│   ├── arsip/          # Arsip dokumen keluarga
│   ├── direktori_keahlian/ # Direktori anggota berdasar keahlian
│   └── splash/         # Splash screen & pengecekan sesi
└── shared/             # Widget, model, dan utilitas bersama
```

---

## Prasyarat

- **Flutter SDK** `^3.12.2`  
- **Dart SDK** `^3.12.2`  
- **Android**: minSdk mengikuti default Flutter (`flutter.minSdkVersion`)  
- **iOS**: Xcode dan CocoaPods untuk build iOS (deployment target 15.0)  
- **Firebase**: `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) untuk push notification (kedua berkas tidak di-commit; berkas iOS belum ada di folder ini)  
- Akses ke server Odoo dengan modul `tarombo` terinstal

---

## Konfigurasi Environment

Aplikasi menggunakan file JSON untuk konfigurasi environment melalui `--dart-define-from-file`.  
**File ini tidak di-commit ke Git** (sudah ditambahkan ke `.gitignore`).

Buat file berikut di root proyek:

**`env.dev.json`** — Development
```json
{
  "BASE_URL": "https://your-dev-server.com",
  "DB_NAME": "nama_database",
  "IS_PRODUCTION": "false"
}
```

**`env.prod.json`** — Production
```json
{
  "BASE_URL": "https://your-prod-server.com",
  "DB_NAME": "nama_database",
  "IS_PRODUCTION": "true"
}
```

**`env.web.json`** — Web
```json
{
  "BASE_URL": "https://your-server.com",
  "DB_NAME": "nama_database",
  "IS_PRODUCTION": "false"
}
```

---

## Cara Menjalankan

### Menggunakan skrip PowerShell (Windows)

```powershell
# Development (Android/emulator)
.\run_dev.ps1

# Production
.\run_prod.ps1

# Web browser
.\run_web.ps1
```

### Manual

```bash
# Development
flutter run --dart-define-from-file=env.dev.json

# Production
flutter run --dart-define-from-file=env.prod.json

# Web
flutter run -d chrome --dart-define-from-file=env.web.json
```

---

## Build Release

```bash
# Android APK
flutter build apk --dart-define-from-file=env.prod.json --release

# Android App Bundle (untuk Play Store)
flutter build appbundle --dart-define-from-file=env.prod.json --release

# iOS
flutter build ios --dart-define-from-file=env.prod.json --release
```

---

## Instalasi & Setup Awal

```bash
# Clone repository
git clone https://github.com/rofianto507/TaromboMobile.git
cd TaromboMobile

# Install dependensi
flutter pub get

# Buat file environment (lihat bagian Konfigurasi Environment di atas)

# Jalankan aplikasi
flutter run --dart-define-from-file=env.dev.json
```

---

## Launcher Icon

Ikon launcher di-generate menggunakan `flutter_launcher_icons`.  
Untuk regenerasi setelah mengganti aset:

```bash
dart run flutter_launcher_icons
```

Aset ikon ada di `assets/images/`:
- `logo.png` — ikon utama
- `logo_ios.png` — ikon iOS (tanpa alpha channel)
- `logo_foreground.png` — lapisan foreground adaptive icon Android

---

## Backend (Odoo)

Aplikasi ini memerlukan modul **`tarombo`** yang berjalan di server Odoo 19.  
Repository backend: [rofianto507/tarombo](https://github.com/rofianto507/tarombo)

Endpoint autentikasi (register, login Google, atur/status kata sandi, hapus akun) ada di `tarombo/controllers/mobile_auth.py`; fitur lain memanggil method model Odoo lewat `call_kw`.

> Backend dipakai bersama oleh semua versi aplikasi yang sudah dirilis, sehingga field dan endpoint lama tidak boleh dihapus. Perbarui modul server (`-u tarombo`) sebelum merilis versi aplikasi yang meminta field baru.

---

## Kontribusi

1. Fork repository ini  
2. Buat branch fitur: `git checkout -b fitur/nama-fitur`  
3. Commit perubahan: `git commit -m "feat: deskripsi singkat"`  
4. Push ke branch: `git push origin fitur/nama-fitur`  
5. Buat Pull Request

---

## Lisensi

Proyek ini bersifat privat dan digunakan untuk keperluan internal komunitas marga Silaen.  
© 2025–2026 Sel Studio
