/// Odoo JSON-RPC mengembalikan `false` (bukan `null` atau string kosong)
/// untuk field Char/Text/Selection/Many2one/Date/Datetime yang belum diisi.
/// Cast langsung `json['x'] as String?` akan MELEMPAR error saat runtime-nya
/// `false` (bool), karena bool bukan subtype dari String? — bukan cuma
/// mengembalikan null seperti yang sering diasumsikan. Pakai helper ini di
/// SETIAP field nullable dari respons call_kw, bukan cast langsung.
String? asOdooString(dynamic v) => v is String ? v : null;

/// Field Datetime Odoo dikirim sebagai string UTC naif ("2026-10-01 09:19:00",
/// tanpa 'Z'/offset) — tambahkan 'Z' secara eksplisit sebelum parse supaya
/// Dart tidak keliru menganggapnya waktu lokal device.
DateTime? asOdooDateTime(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.parse('${v.replaceFirst(' ', 'T')}Z').toLocal();
}

/// Field Date Odoo (tanpa jam, mis. "1923-01-01") — TIDAK boleh lewat
/// asOdooDateTime: tidak ada komponen jam untuk diubah ke UTC, dan menambah
/// 'Z' langsung ke string tanggal polos bisa gagal di-parse.
DateTime? asOdooDate(dynamic v) {
  if (v is! String || v.isEmpty) return null;
  return DateTime.tryParse(v);
}
