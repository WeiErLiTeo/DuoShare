import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:duoshare/main.dart';
import 'package:duoshare/services/connection_service.dart';
import 'package:duoshare/services/discovery_service.dart';
import 'package:duoshare/services/theme_service.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for unit tests on desktop/CI.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('DuoShare smoke test', (WidgetTester tester) async {
    // Create actual services, but ensure they don't break during tests
    final connectionService = ConnectionService();
    final discoveryService = DiscoveryService();
    discoveryService.setConnectionService(connectionService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: connectionService),
          ChangeNotifierProvider.value(value: discoveryService),
          ChangeNotifierProvider.value(value: ThemeService()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify that DuoShare title is rendered
    expect(find.text('DuoShare'), findsWidgets);

    // Verify some tabs are present
    expect(find.text('设备'), findsWidgets);
    expect(find.text('文件'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
  });
}
