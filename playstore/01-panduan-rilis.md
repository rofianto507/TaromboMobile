# Panduan Rilis Tarombo ke Google Play — Step by Step

Status per 2026-10-04. Centang `[x]` = sudah disiapkan di repo, `[ ]` = tugas Anda.

## Tahap 0 — Akun & prasyarat
- [ ] **Akun Google Play Console** (biaya sekali bayar US$25). Kebijakan privasi Anda menyebut pengembang
      **CV Mitra Hoki Maju Mapan**, jadi daftarkan sebagai akun **Organisasi** (butuh nomor D-U-N-S, verifikasi
      bisa berhari-hari — mulai lebih awal).
- [ ] **Samakan nama pengembang.** Manifest modul Odoo menulis "Cv Sel Studio", kebijakan privasi menulis
      "CV Mitra Hoki Maju Mapan". Nama di Play Console, kebijakan privasi, dan email kontak harus konsisten;
      ketidaksesuaian termasuk penyebab penolakan yang umum.
- [ ] Bila memakai akun **Personal** (bukan organisasi): Google mewajibkan **closed test minimal 12 tester selama
      14 hari berturut-turut** sebelum boleh mengajukan produksi. Akun Organisasi tidak kena syarat ini.
      (Aturan ini sering berubah — cek di Play Console › Dashboard.)
- [x] Application ID `id.selstudio.tarombo_mobile`. **Tidak bisa diubah setelah dipublikasikan.** Ubah sekarang
      bila ingin yang lain (mis. `id.mitrahoki.tarombo`), di `android/app/build.gradle.kts` (`namespace` + `applicationId`)
      dan daftarkan ulang app Android di Firebase untuk mendapat `google-services.json` baru.
- [x] Target SDK 36 (mengikuti Flutter 3.44.4) — memenuhi syarat Play terbaru.

## Tahap 1 — Upload key & signing
Play memakai **Play App Signing**: Anda menandatangani AAB dengan *upload key*, Google yang memegang kunci rilis.

1. Buat keystore (sekali saja). `keytool` ada di JDK Android Studio:
   ```powershell
   & "C:\Program Files\Android\Android Studio2\jbr\bin\keytool.exe" -genkey -v `
     -keystore D:\FLUT\upload-keystore.jks -storetype JKS `
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Simpan `.jks` **di luar repo** + **cadangkan** (password manager / drive terenkripsi) beserta passwordnya.
   Bila hilang, Anda harus meminta reset upload key lewat Google — repot.
2. Buat `android/key.properties` (sudah di-ignore git lewat `android/.gitignore`):
   ```properties
   storePassword=<password keystore>
   keyPassword=<password key>
   keyAlias=upload
   storeFile=D:/FLUT/upload-keystore.jks
   ```
3. [x] `android/app/build.gradle.kts` sudah membaca `key.properties` dan menandatangani build release dengannya
      (R8/shrink aktif, aturan di `proguard-rules.pro`). **Tanpa `key.properties` build release memakai kunci debug —
      jangan upload yang itu.**

## Tahap 2 — Build AAB release
```powershell
cd D:\FLUT\TaromboMobile
flutter clean
flutter pub get
flutter build appbundle --release --dart-define-from-file=env.prod.json
```
Hasil: `build\app\outputs\bundle\release\app-release.aab`.

- **Wajib** pakai `env.prod.json` (BASE_URL produksi). Tanpa itu app menunjuk ke server yang salah.
- Versi di `pubspec.yaml`: `version: 1.0.0+1` → `1.0.0` = nama versi, `+1` = **versionCode**. Setiap upload ke Play
  harus menaikkan angka setelah `+` (`1.0.1+2`, dst.).
- **Uji dulu build release di HP asli** (R8 kadang merusak plugin): `flutter build apk --release --dart-define-from-file=env.prod.json`
  lalu pasang dan coba login, notifikasi, peta, unduh arsip. Belum saya jalankan — itu langkah pertama yang
  harus dibuktikan sebelum upload.

## Tahap 3 — Login Google & Firebase (sering lolos saat debug, gagal di Play)
Saat Play App Signing aktif, APK yang sampai ke pengguna ditandatangani **kunci Google**, bukan upload key Anda,
sehingga sidik jarinya berbeda. Bila tidak didaftarkan, **"Login dengan Google" gagal di versi Play — termasuk
saat reviewer Google mencoba aplikasi Anda.**

1. Play Console › *Setup › App signing* › salin **SHA-1 dan SHA-256** dari "App signing key certificate".
2. Firebase Console › Project settings › app Android › *Add fingerprint* — tambahkan SHA dari **app signing key**
   dan juga dari **upload key** (`keytool -list -v -keystore upload-keystore.jks -alias upload`).
3. Google Cloud Console › Credentials: pastikan OAuth client Android untuk package `id.selstudio.tarombo_mobile`
   memuat SHA-1 yang sama.
4. Unduh ulang `google-services.json` ke `android/app/` (file ini di-ignore git, jangan commit).

## Tahap 4 — Siapkan situs & kebijakan (semuanya di backend Odoo)
| Item | URL | Status |
|---|---|---|
| Kebijakan Privasi | https://tarombo.selstudio.id/kebijakan-privasi | [x] ada. Diperbarui 4 Okt 2026 agar menyebut token notifikasi Firebase. **Perubahan ada di source `tarombo/controllers/public_pages.py` — deploy/restart Odoo produksi agar tampil.** |
| Dukungan | https://tarombo.selstudio.id/dukungan | [x] ada |
| Hapus Akun (web) | https://tarombo.selstudio.id/hapus-akun | [x] ada — wajib untuk kebijakan Data deletion Play |
| Hapus akun di dalam app | Akun › Hapus Akun | [x] ada |

Pastikan ketiga URL bisa dibuka **tanpa login** dari HP, sebelum mengisi formulir Play Console.

## Tahap 5 — Akun uji untuk reviewer (App access)
Aplikasi butuh login, jadi reviewer harus bisa masuk. Di Play Console › *App content › App access* pilih
"All or some functionality is restricted" dan isi:
- Buat satu akun Odoo/login biasa khusus review (mis. `reviewer.tarombo@...`) yang **sudah terhubung ke satu orang
  di pohon** (klaim sudah disetujui) agar semua tab terisi. Jangan pakai data orang sungguhan yang sensitif.
- Cantumkan username, password, dan catatan: *"Login dengan Google tidak diperlukan untuk review; gunakan
  username/password di atas. Izin lokasi opsional."*
- Jangan ubah/hapus akun ini selama masa review.

## Tahap 6 — Grafis (sudah dibuat)
Folder `playstore/graphics/` (dibuat ulang dengan `python scripts/gen_playstore_graphics.py`):
| Aset | Syarat Play | File |
|---|---|---|
| Ikon aplikasi | PNG 512×512, ≤1 MB | `ikon-512.png` ✔ (persegi penuh; Play membulatkan sendiri) |
| Feature graphic | JPG/PNG 1024×500, tanpa alpha | `feature-graphic-1024x500.png` ✔ |
| Screenshot HP | 2–8 gambar, sisi 320–3840 px, rasio maks 2:1 | **Tugas Anda** — lihat di bawah |
| Screenshot tablet 7"/10" | opsional, disarankan | Opsional |

### Screenshot (ambil dari app produksi di HP asli atau emulator)
Rekomendasi 1080×2400 (portrait), PNG, 6–8 gambar urutan berikut. Takarir (untuk disematkan di bingkai bila mau)
ada di `02-listing.md`.
1. Beranda — ringkasan & menu utama
2. Pohon silsilah (tab Tarombo)
3. Partuturan / hubungan kekerabatan
4. Kerabat Terdekat (peta)
5. Arsip keluarga
6. Usulan data
7. Direktori keahlian
8. Layar Akun (menampilkan Kebijakan Privasi & Hapus Akun)

**Aturan agar lolos:**
- **Pakai data demo / nama samaran.** Jangan tampilkan nama, foto, atau lokasi orang sungguhan — itu data pribadi
  pihak ketiga dan bisa memicu penolakan atau keluhan.
- Tanpa bilah status yang memperlihatkan nomor/notifikasi pribadi; baterai/sinyal penuh.
- Tampilkan **UI asli aplikasi**, bukan mockup yang menyesatkan; jangan memakai logo/merek Play, Google, atau
  Android pada gambar.
- Tidak ada teks klaim seperti "#1", "terbaik", harga, atau ajakan unduh pada gambar.
- Pengambilan lewat adb (HP terhubung):
  `adb exec-out screencap -p > s1.png` (adb ada di `%LOCALAPPDATA%\Android\Sdk\platform-tools`).

## Tahap 7 — Isi Play Console
Buat aplikasi: bahasa default **Indonesia (id-ID)**, jenis *App*, *Free*.

**A. Dashboard › "Set up your app"** — kerjakan semua tugas, detail isian ada di `02-listing.md`:
1. App access (Tahap 5)
2. Ads → *Tidak ada iklan*
3. Content rating (kuesioner IARC)
4. Target audience → **18+** (aman; hindari kebijakan Families)
5. Data safety (tabel jawaban di `02-listing.md`)
6. Government apps → Bukan
7. Financial features → Tidak ada
8. Health → Tidak ada
9. News → Bukan
10. Privacy policy URL, Account deletion URL

**B. Main store listing** — teks & grafis dari `02-listing.md`.

**C. Release** — *Testing › Internal testing* dulu (tanpa review lama), unggah AAB, tambahkan email Anda sebagai tester,
pasang lewat link, uji. Lalu lanjut (sesuai jenis akun) ke Closed test → *Production › Create release*.

## Tahap 8 — Pengajuan & setelah itu
- Review pertama biasanya 1–7 hari (bisa lebih untuk akun baru).
- Cek *Policy status* dan email Play Console; bila ditolak, alasan dicantumkan — perbaiki lalu kirim ulang.
- Tiap pembaruan: naikkan `versionCode`, build AAB, upload, catatan rilis.

## Daftar cek cepat sebelum menekan "Send for review"
- [ ] AAB ditandatangani upload key (bukan debug) dan versionCode benar
- [ ] Build release diuji di HP asli: login, Google login (setelah SHA ditambahkan), notifikasi, peta, arsip, hapus akun
- [ ] SHA Play App Signing sudah di Firebase + Google Cloud
- [ ] 3 URL (privasi, dukungan, hapus akun) terbuka tanpa login & versi privasi terbaru sudah dideploy
- [ ] Nama pengembang konsisten di Play Console / kebijakan privasi
- [ ] Akun reviewer berfungsi
- [ ] Screenshot memakai data demo
- [ ] Data safety cocok dengan perilaku app dan kebijakan privasi
