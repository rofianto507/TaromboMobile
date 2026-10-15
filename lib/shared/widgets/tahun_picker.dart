import 'package:flutter/material.dart';

/// Dialog pilih TAHUN saja (tanpa bulan dan hari). Mengembalikan tahun
/// terpilih, atau null bila dibatalkan.
Future<int?> showTahunPicker(
  BuildContext context, {
  int? initial,
  int firstYear = 1800,
  String title = 'Pilih Tahun',
}) {
  final sekarang = DateTime.now().year;
  final awal = (initial ?? sekarang - 30).clamp(firstYear, sekarang);
  return showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      contentPadding: const EdgeInsets.only(top: 12),
      content: SizedBox(
        width: 300,
        height: 320,
        child: YearPicker(
          firstDate: DateTime(firstYear),
          lastDate: DateTime(sekarang),
          selectedDate: DateTime(awal),
          currentDate: DateTime(sekarang),
          onChanged: (d) => Navigator.of(ctx).pop(d.year),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Batal'),
        ),
      ],
    ),
  );
}
