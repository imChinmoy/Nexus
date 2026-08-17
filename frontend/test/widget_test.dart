import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brl_nexus/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BRL Nexus app smoke test', (WidgetTester tester) async {
    await dotenv.load(fileName: '.env');

    await tester.pumpWidget(
      const ProviderScope(
        child: BrlNexusApp(),
      ),
    );
  });
}
