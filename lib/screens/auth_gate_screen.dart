import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import 'login_screen.dart';
import 'role_selection_screen.dart';
import 'watermark_background.dart';

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

    return WatermarkBackground(
      child: RoleSelectionScreen(
        clientRepo: widget.clientRepo,
        driverRepo: widget.driverRepo,
        orderRepo: widget.orderRepo,
      ),
    );
  }
}