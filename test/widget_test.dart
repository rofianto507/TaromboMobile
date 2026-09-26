import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tarombo_mobile/main.dart';

void main() {
  testWidgets('App boots and shows splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TaromboApp()));
    await tester.pump();
    expect(find.text('TAROMBO'), findsOneWidget);
    // Selesaikan _splashTimerProvider (delay 1200ms) sebelum test berakhir,
    // supaya tidak ada Timer yang masih pending saat widget tree dibuang.
    await tester.pump(const Duration(milliseconds: 1300));
  });
}
