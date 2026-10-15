import 'package:flutter/material.dart';

/// Biru khas lencana terverifikasi (mirip Instagram/Facebook).
const kBiruVerified = Color(0xFF1D9BF0);

/// Lencana centang biru untuk anggota yang akunnya sudah tertaut dan
/// diverifikasi pengurus. Keterangannya "Akun terverifikasi" supaya tidak
/// tertukar dengan status data "Terverifikasi" di tempat lain.
class VerifiedBadge extends StatelessWidget {
  final double size;
  const VerifiedBadge({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Akun terverifikasi',
      child: Icon(Icons.verified_rounded, size: size, color: kBiruVerified),
    );
  }
}

/// Nama orang, dengan lencana terverifikasi tepat setelah nama bila
/// [terverifikasi]. Memakai Text.rich supaya lencana ikut membungkus baris
/// bersama nama yang panjang.
class OrangNama extends StatelessWidget {
  final String nama;
  final bool terverifikasi;
  final TextStyle? style;
  final int? maxLines;
  final TextAlign? textAlign;
  final double badgeSize;

  const OrangNama({
    super.key,
    required this.nama,
    this.terverifikasi = false,
    this.style,
    this.maxLines,
    this.textAlign,
    this.badgeSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!terverifikasi) {
      return Text(
        nama,
        style: style,
        maxLines: maxLines,
        textAlign: textAlign,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
      );
    }
    return Text.rich(
      TextSpan(
        text: nama,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: VerifiedBadge(size: badgeSize),
            ),
          ),
        ],
      ),
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: maxLines == null ? TextOverflow.clip : TextOverflow.ellipsis,
    );
  }
}
