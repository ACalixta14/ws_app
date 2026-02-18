import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'repositories/client_repository.dart';
import 'repositories/driver_repository.dart';
import 'repositories/service_order_repository.dart';
import 'screens/role_selection_screen.dart';

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

    return MaterialApp(
      title: 'Waste Collection MVP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: RoleSelectionScreen(
        clientRepo: clientRepo,
        driverRepo: driverRepo,
        orderRepo: orderRepo,
      ),
    );
  }
}
