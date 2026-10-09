# Flutter + plugin sudah membawa consumer rules sendiri. Tambahkan aturan di sini
# hanya bila build release crash karena R8 (cek `flutter build appbundle` + uji di device).
-dontwarn com.google.android.play.core.**

# Firebase mendaftarkan komponennya lewat reflection (ComponentRegistrar). Tanpa
# aturan ini R8 membuang kelas *KtxRegistrar, dan FCM bisa gagal diam-diam di release.
-keep class com.google.firebase.components.** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
