import 'dart:convert';

import '../../../../shared/utils/odoo_json.dart';

class NotifikasiItem {
  final int id;
  final String judul;
  final String? isi;
  final String? tipe;
  final Map<String, dynamic> data;
  final bool dibaca;
  final DateTime? tanggal;

  const NotifikasiItem({
    required this.id,
    required this.judul,
    this.isi,
    this.tipe,
    this.data = const {},
    this.dibaca = false,
    this.tanggal,
  });

  factory NotifikasiItem.fromJson(Map<String, dynamic> j) {
    final rawData = asOdooString(j['data']);
    Map<String, dynamic> data = const {};
    if (rawData != null) {
      try {
        data = jsonDecode(rawData) as Map<String, dynamic>;
      } catch (_) {
        data = const {};
      }
    }
    return NotifikasiItem(
      id: j['id'] as int,
      judul: asOdooString(j['judul']) ?? '',
      isi: asOdooString(j['isi']),
      tipe: asOdooString(j['tipe']),
      data: data,
      dibaca: j['dibaca'] == true,
      tanggal: asOdooDateTime(j['create_date']),
    );
  }
}
