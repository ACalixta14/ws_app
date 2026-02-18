import 'package:flutter/material.dart';

import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import '../services/manual_json_sync_service.dart';
import 'client_list_screen.dart';
import 'create_service_order_screen.dart';
import 'order_history_screen.dart';
import 'plan_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  final ClientRepository clientRepo;
  final DriverRepository driverRepo;
  final ServiceOrderRepository orderRepo;

  const AdminHomeScreen({
    super.key,
    required this.clientRepo,
    required this.driverRepo,
    required this.orderRepo,
  });

  Future<void> _exportSyncJson(BuildContext context) async {
    try {
      await ManualJsonSyncService.exportAndShare(
        clientRepo: clientRepo,
        orderRepo: orderRepo,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export ready to share')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  Future<void> _importSyncJson(BuildContext context) async {
    try {
      final result = await ManualJsonSyncService.importFromPickerAndMerge(
        clientRepo: clientRepo,
        orderRepo: orderRepo,
      );

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Import summary'),
          content: Text(
            'Clients imported: ${result.clientsImported}\n'
            'Orders imported: ${result.ordersImported}\n'
            'Orders skipped (older): ${result.ordersSkippedOlder}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientsListScreen(clientRepo: clientRepo),
                  ),
                );
              },
              child: const Text('Clients'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateServiceOrderScreen(
                      clientRepo: clientRepo,
                      driverRepo: driverRepo,
                      orderRepo: orderRepo,
                    ),
                  ),
                );
              },
              child: const Text('Create Service Order'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlanScreen(
                      orderRepo: orderRepo,
                      driverRepo: driverRepo,
                      clientRepo: clientRepo,
                      driverId: null,
                      isAdmin: true,
                    ),
                  ),
                );
              },
              child: const Text('Today / Tomorrow Plan'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrdersHistoryScreen(
                      orderRepo: orderRepo,
                      driverRepo: driverRepo,
                      clientRepo: clientRepo,
                    ),
                  ),
                );
              },
              child: const Text('Orders History'),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ✅ NEW: Export/Import JSON Sync
            ElevatedButton.icon(
              onPressed: () => _exportSyncJson(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Export Sync JSON (share)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _importSyncJson(context),
              icon: const Icon(Icons.download),
              label: const Text('Import Sync JSON'),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Clear all test data?'),
                    content: const Text('This will delete ALL clients and orders.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirmed != true) return;

                await orderRepo.clear();
                await clientRepo.clear();

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              },
              child: const Text('Clear test data'),
            ),
          ],
        ),
      ),
    );
  }
}
