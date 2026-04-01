import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'services/supabase_config.dart';
import 'repositories/client_repository.dart';
import 'repositories/driver_repository.dart';
import 'repositories/service_order_repository.dart';
import 'screens/role_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/watermark_background.dart';
import 'theme/app_theme.dart';
import 'screens/auth_gate_screen.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox<Map>('clients');
  await Hive.openBox<Map>('orders');
  await Hive.openBox('meta');

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const WsApp());
}

class WsApp extends StatelessWidget {
  const WsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final clientRepo = ClientRepository();
    final driverRepo = DriverRepository();
    final orderRepo = ServiceOrderRepository();

    final firstScreen = AuthGateScreen(
        clientRepo: clientRepo,
        driverRepo: driverRepo,
        orderRepo: orderRepo,
      );

    return MaterialApp(
      title: 'Weslly Entulhos e Remodelações',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
   home: SplashScreen(
  next: firstScreen,
  clientRepo: clientRepo,
  orderRepo: orderRepo,
  duration: const Duration(seconds: 2),
),
    );
  }
}