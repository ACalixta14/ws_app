import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../models/service_order.dart';
import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';
import '../repositories/driver_repository.dart';
import '../services/data_filters.dart';
import 'service_order_detail_screen.dart';
import 'driver_home_screen.dart';

class PlanScreen extends StatefulWidget {
  final ServiceOrderRepository orderRepo;
  final DriverRepository driverRepo;
  final ClientRepository clientRepo;

  // Se for Driver, passa driverId para filtrar.
  // Se for Admin, pode passar null para ver tudo.
  final String? driverId;
  final bool isAdmin;

  const PlanScreen({
    super.key,
    required this.orderRepo,
    required this.driverRepo,
    required this.clientRepo,
    this.driverId,
    required this.isAdmin,
  });

  @override
  State<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  void _refresh() => setState(() {});

  List<ServiceOrder> _getFilteredOrders() {
    // ✅ Agora o Plan mostra TUDO: scheduled + done + canceled
    final all = widget.orderRepo.getAll();

    final filtered = widget.driverId == null
        ? all
        : all.where((o) => o.driverId == widget.driverId).toList();

    filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _getFilteredOrders();

    final today = filteredOrders.where(isToday).toList();
    final tomorrow = filteredOrders.where(isTomorrow).toList();

    // mantém ordenado por hora
    today.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    tomorrow.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today / Tomorrow'),
        actions: [
          if (!widget.isAdmin)
            IconButton(
              tooltip: 'Change driver',
              icon: const Icon(Icons.switch_account),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverHomeScreen(
                      clientRepo: widget.clientRepo,
                      driverRepo: widget.driverRepo,
                      orderRepo: widget.orderRepo,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(
            title: 'Today',
            orders: today,
            driverRepo: widget.driverRepo,
            clientRepo: widget.clientRepo,
            orderRepo: widget.orderRepo,
            onChanged: _refresh,
            isAdmin: widget.isAdmin,
          ),
          const SizedBox(height: 24),
          _Section(
            title: 'Tomorrow',
            orders: tomorrow,
            driverRepo: widget.driverRepo,
            clientRepo: widget.clientRepo,
            orderRepo: widget.orderRepo,
            onChanged: _refresh,
            isAdmin: widget.isAdmin,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<ServiceOrder> orders;

  final DriverRepository driverRepo;
  final ClientRepository clientRepo;
  final ServiceOrderRepository orderRepo;

  final VoidCallback onChanged;
  final bool isAdmin;

  const _Section({
    required this.title,
    required this.orders,
    required this.driverRepo,
    required this.clientRepo,
    required this.orderRepo,
    required this.onChanged,
    required this.isAdmin,
  });

  Future<void> _cancelOrder(BuildContext context, ServiceOrder order) async {
    if (!isAdmin) return;

    // ✅ Segurança: só cancela se estiver scheduled
    if (order.status != OrderStatus.scheduled) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('The order will be kept in history but removed from the plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel order')),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = order.copyWith(
      status: OrderStatus.canceled,
      updatedAt: DateTime.now(),
    );

    await orderRepo.update(updated);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order canceled')),
    );

    onChanged();
  }

  Color? _statusColor(ServiceOrder order) {
    if (order.status == OrderStatus.done) return Colors.green;
    if (order.status == OrderStatus.canceled) return Colors.red;
    return null;
    // scheduled: padrão
  }

  TextDecoration _statusDecoration(ServiceOrder order) {
    if (order.status == OrderStatus.canceled) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  IconData? _statusIcon(ServiceOrder order) {
    if (order.status == OrderStatus.done) return Icons.check_circle;
    if (order.status == OrderStatus.canceled) return Icons.cancel;
    return null; // scheduled
  }

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('No orders'),
        ],
      );
    }

    final grouped = <String, List<ServiceOrder>>{};
    for (final o in orders) {
      grouped.putIfAbsent(o.driverId, () => []).add(o);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        ...grouped.entries.map((entry) {
          final driver = driverRepo.getById(entry.key);
          final driverName = driver?.name ?? 'Unknown';

          final driverOrders = entry.value.toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(driverName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...driverOrders.map((order) {
                    final client = clientRepo.getById(order.clientId);
                    final clientName = client?.name ?? 'Client';

                    final hh = order.scheduledAt.hour.toString().padLeft(2, '0');
                    final mm = order.scheduledAt.minute.toString().padLeft(2, '0');

                    final statusColor = _statusColor(order);
                    final statusIcon = _statusIcon(order);

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: statusIcon == null
                          ? null
                          : Icon(statusIcon, color: statusColor),
                      title: Text(
                        '$hh:$mm • $clientName',
                        style: TextStyle(
                          decoration: _statusDecoration(order),
                          color: statusColor,
                        ),
                      ),
                      subtitle: Text(
                        '${order.serviceType.label} • €${order.price.toStringAsFixed(0)} • ${order.status.label}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final changed = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceOrderDetailScreen(
                              order: order,
                              clientRepo: clientRepo,
                              driverRepo: driverRepo,
                              orderRepo: orderRepo,
                              isAdmin: isAdmin,
                            ),
                          ),
                        );
                        if (changed == true) onChanged();
                      },
                      // ✅ Cancel só Admin e só scheduled
                      onLongPress: isAdmin && order.status == OrderStatus.scheduled
                          ? () => _cancelOrder(context, order)
                          : null,
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
