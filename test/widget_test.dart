import 'package:flutter_test/flutter_test.dart';
import 'package:optiruta/main.dart';

void main() {
  testWidgets('Smoke test - Verify Login Admin Screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the title 'Login Super Administrador' is rendered.
    expect(find.text('Login Super Administrador'), findsOneWidget);
  });
}
