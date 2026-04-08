import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import '../screens/admin_home_screen.dart';
import '../screens/driver_home_screen.dart';
import 'login_screen.dart';

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
  late final Stream<AuthState> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final row = await Supabase.instance.client
        .from('user_profiles')
        .select('role, driver_id, is_active')
        .eq('id', user.id)
        .maybeSingle();

    return row;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStream,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (session == null) {
          return const LoginScreen();
        }

        return FutureBuilder<Map<String, dynamic>?>(
          future: _loadProfile(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Erro ao carregar perfil: ${profileSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final profile = profileSnapshot.data;
            if (profile == null) {
              return const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Perfil de acesso não encontrado para este usuário.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final isActive = profile['is_active'] == true;
            if (!isActive) {
              return const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Este acesso está inativo.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            final role = (profile['role'] ?? '').toString();

            if (role == 'admin') {
              return AdminHomeScreen(
                clientRepo: widget.clientRepo,
                driverRepo: widget.driverRepo,
                orderRepo: widget.orderRepo,
              );
            }

            if (role == 'driver') {
              final driverId = (profile['driver_id'] ?? '').toString();

              if (driverId.isEmpty) {
                return const Scaffold(
                  body: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Motorista sem driver_id configurado.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              return DriverHomeScreen(
                driverId: driverId,
                clientRepo: widget.clientRepo,
                driverRepo: widget.driverRepo,
                orderRepo: widget.orderRepo,
              );
            }

            return const Scaffold(
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Role inválida para este usuário.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}