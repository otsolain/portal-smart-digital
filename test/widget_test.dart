// Basic Flutter widget test for Sekolah App
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sekolah_app/app.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SekolahApp()),
    );

    // Verify app starts without crashing
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SekolahApp), findsOneWidget);
  });
}
