import 'package:flutter/material.dart';

const Map<String, String> jenisArsipLabels = {
  'foto': 'Foto',
  'dokumen': 'Dokumen',
  'audio': 'Audio',
  'video': 'Video',
  'naskah': 'Naskah',
};

String jenisArsipLabel(String? v) => v == null ? '-' : (jenisArsipLabels[v] ?? v);

IconData jenisArsipIcon(String? jenis) {
  switch (jenis) {
    case 'foto':
      return Icons.image_outlined;
    case 'audio':
      return Icons.audiotrack_rounded;
    case 'video':
      return Icons.videocam_outlined;
    case 'naskah':
      return Icons.menu_book_outlined;
    case 'dokumen':
    default:
      return Icons.description_outlined;
  }
}
