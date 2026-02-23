import 'package:flutter/material.dart';

import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import 'plan_screen.dart';
import 'role_selection_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  final ClientRepository clientRepo;
  final DriverRepository driverRepo;
  final ServiceOrderRepository orderRepo;

  const DriverHomeScreen({
    super.key,
    required this.clientRepo,
    required this.driverRepo,
    required this.orderRepo,
  });

  @override
  Widget build(BuildContext context) {
    final drivers = driverRepo.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Motorista'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Volta para RoleSelection (Admin/Driver)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => RoleSelectionScreen(
                  clientRepo: clientRepo,
                  driverRepo: driverRepo,
                  orderRepo: orderRepo,
                ),
              ),
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Escolha seu nome:'),
          const SizedBox(height: 12),
          ...drivers.map(
            (d) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: () {
                  // ✅ replacement: não volta pra tela de seleção quando apertar back
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlanScreen(
                        orderRepo: orderRepo,
                        driverRepo: driverRepo,
                        clientRepo: clientRepo,
                        driverId: d.id,
                        isAdmin: false,
                      ),
                    ),
                  );
                },
                child: Text(d.name),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
