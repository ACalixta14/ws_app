import 'package:flutter/material.dart';

import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import 'admin_home_screen.dart';
import 'driver_home_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  final ClientRepository clientRepo;
  final DriverRepository driverRepo;
  final ServiceOrderRepository orderRepo;

  const RoleSelectionScreen({
    super.key,
    required this.clientRepo,
    required this.driverRepo,
    required this.orderRepo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Role')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('WS_app', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Admin manages clients and orders.\n'
              'Driver selects their name and sees Today/Tomorrow plan.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                // ✅ replacement so user won’t come back here accidentally
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminHomeScreen(
                      clientRepo: clientRepo,
                      driverRepo: driverRepo,
                      orderRepo: orderRepo,
                    ),
                  ),
                );
              },
              child: const Text('Continue as Admin'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                // ✅ Driver flow: go to driver selection once, then plan
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverHomeScreen(
                      clientRepo: clientRepo,
                      driverRepo: driverRepo,
                      orderRepo: orderRepo,
                    ),
                  ),
                );
              },
              child: const Text('Continue as Driver'),
            ),
          ],
        ),
      ),
    );
  }
}
