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

  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

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

  Future<void> _clearAllData(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) {
    const double maxContentWidth = 520;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F8),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 22),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxContentWidth),
            child: Column(
              children: [
                // =========================
                // HEADER
                // =========================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [brand, brand2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logo.png',
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 18),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Clients, orders, planning and sync',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // GRID CARDS
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.55,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _card(
                        icon: Icons.people_alt_rounded,
                        title: 'Clients',
                        subtitle: 'Manage clients',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ClientsListScreen(
                                clientRepo: clientRepo,
                              ),
                            ),
                          );
                        },
                      ),
                      _card(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Create Order',
                        subtitle: 'New service',
                        onTap: () {
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
                      ),
                      _card(
                        icon: Icons.calendar_month_rounded,
                        title: 'Plan',
                        subtitle: 'Today / Tomorrow',
                        onTap: () {
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
                      ),
                      _card(
                        icon: Icons.history_rounded,
                        title: 'History',
                        subtitle: 'Past orders',
                        onTap: () {
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // =========================
                // SYNC & TOOLS
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              brand.withOpacity(0.12),
                              brand2.withOpacity(0.10),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: brand.withOpacity(0.18)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.sync_rounded, color: brand),
                            SizedBox(width: 10),
                            Text(
                              'Sync & Tools',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _toolButton(
                              icon: Icons.upload_file_rounded,
                              label: 'Export JSON',
                              onTap: () => _exportSyncJson(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _toolButton(
                              icon: Icons.download_rounded,
                              label: 'Import JSON',
                              onTap: () => _importSyncJson(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _toolButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Clear test data',
                        isDanger: true,
                        onTap: () => _clearAllData(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 22, color: brand),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _toolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final border = isDanger ? Colors.red.withOpacity(0.35) : brand.withOpacity(0.18);
    final bg = isDanger ? Colors.red.withOpacity(0.06) : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.04),
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isDanger ? Colors.red : brand),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isDanger ? Colors.red : const Color(0xFF111111),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}