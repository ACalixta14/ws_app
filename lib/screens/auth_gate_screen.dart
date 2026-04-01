import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ws_app/screens/admin_home_screen.dart';
import 'package:ws_app/screens/driver_home_screen.dart';

import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import 'login_screen.dart';
import '../screens/admin_home_screen.dart';
import '../screens/driver_home_screen.dart';

class AuthGateScreen extends StatefulWidget {
  final ClientRepository clientRepo;
  final DriverRepository driverRepo;
  final ServiceOrderRepository orderRepo;

  const AuthGateScreen({
    super.key,
    required this.clientRepo,
    required this.driverRepo,
    required this.orderRepo,
  });

  @override
  State<AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<AuthGateScreen> {
  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    }

    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';

    final isAdmin = email == 'weslly.pinturas@gmail.com';

//tela de admin
    if (isAdmin){
      return AdminHomeScreen(
        clientRepo: widget.clientRepo, 
        driverRepo: widget.driverRepo, 
        orderRepo: widget.orderRepo,
        );
    }
//tela driver (padrão)
final drivers = widget.driverRepo.getAll();

final driver = drivers.firstWhere(
  (d) => d.name.toLowerCase() == email.toLowerCase(),
  orElse: () => drivers.first,
);

return DriverHomeScreen(
  driverId: driver.id,
  clientRepo: widget.clientRepo,
  driverRepo: widget.driverRepo,
  orderRepo: widget.orderRepo,
);


  }
}