import 'package:flutter/material.dart';
import '../utils/orang_format.dart';
import 'orang_avatar.dart';

/// Baris orang yang seragam untuk semua hasil pencarian:
/// foto, nama lengkap, lalu "Sundut N - Nama Ayah".
class OrangListTile extends StatelessWidget {
  /// Satu baris hasil search_read yang memuat [kOrangSearchFields].
  final Map<String, dynamic> orang;
  final VoidCallback? onTap;
  final Widget? trailing;

  /// Baris tambahan di bawah subtitel (mis. pekerjaan di direktori).
  final String? keterangan;

  const OrangListTile({
    super.key,
    required this.orang,
    this.onTap,
    this.trailing,
    this.keterangan,
  });

  @override
  Widget build(BuildContext context) {
    final sub = subtitleOrang(orang);
    return ListTile(
      leading: OrangAvatar(
        orangId: orang['id'] as int,
        jenisKelamin: (orang['jenis_kelamin'] as String?) ?? 'L',
        radius: 20,
      ),
      title: Text(
        orang['name'] as String,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: (sub.isEmpty && keterangan == null)
          ? null
          : Text(
              [if (sub.isNotEmpty) sub, ?keterangan].join('\n'),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
      isThreeLine: keterangan != null && sub.isNotEmpty,
      trailing: trailing,
      onTap: onTap,
    );
  }
}
