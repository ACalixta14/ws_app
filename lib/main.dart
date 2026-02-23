import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'repositories/client_repository.dart';
import 'repositories/driver_repository.dart';
import 'repositories/service_order_repository.dart';
import 'screens/role_selection_screen.dart';

import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'screens/watermark_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox<Map>('clients');
  await Hive.openBox<Map>('orders');

  runApp(const WsApp());
}

class WsApp extends StatelessWidget {
  const WsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final clientRepo = ClientRepository();
    final driverRepo = DriverRepository();
    final orderRepo = ServiceOrderRepository();

    final firstScreen = WatermarkBackground(
      child: RoleSelectionScreen(
        clientRepo: clientRepo,
        driverRepo: driverRepo,
        orderRepo: orderRepo,
      ),
    );

    return MaterialApp(
      title: 'Waste Collection MVP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: SplashScreen(
        next: firstScreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}