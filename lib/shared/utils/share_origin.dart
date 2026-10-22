import 'package:flutter/widgets.dart';

/// Titik asal lembar bagikan. iPad dan Mac ("Designed for iPad") wajib punya
/// `sharePositionOrigin` yang valid; tanpa itu share_plus melempar galat dan
/// lembar bagikan tidak muncul. Dipakai juga di iPhone (diabaikan di sana).
/// Posisinya pojok kanan atas layar, tempat tombol bagikan berada.
Rect asalBagikan(BuildContext context) {
  final ukuran = MediaQuery.sizeOf(context);
  final atas = MediaQuery.paddingOf(context).top;
  return Rect.fromLTWH(ukuran.width - 56, atas, 48, 56);
}
