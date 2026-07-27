import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/test.dart';
import 'package:optiruta/main.dart';
import 'package:optiruta/providers/pedido_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Smoke test - Verify Welcome Screen loads and displays profiles', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => PedidoProvider()),
        ],
        child: const MyApp(),
      ),
    );

    // Esperar a que se rendericen los elementos
    await tester.pumpAndSettle();

    // Verificar que el título principal de bienvenida esté presente
    expect(find.text('¡Bienvenido a OPTIRUTA!'), findsOneWidget);

    // Verificar que las opciones de perfiles se muestren en las tarjetas
    expect(find.text('SUPER ADMINISTRADOR'), findsOneWidget);
    expect(find.text('BODEGUERO'), findsOneWidget);
    expect(find.text('CONDUCTOR'), findsOneWidget);

    // Verificar que el botón Siguiente esté presente
    expect(find.text('Siguiente'), findsOneWidget);
  });
}
