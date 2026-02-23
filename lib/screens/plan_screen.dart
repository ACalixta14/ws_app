import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../models/service_order.dart';
import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import '../services/data_filters.dart';
import 'driver_home_screen.dart';
import 'service_order_detail_screen.dart';

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
  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

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

    today.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    tomorrow.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
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
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today / Tomorrow',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.isAdmin
                                    ? 'Plan for all drivers'
                                    : 'Your plan for today and tomorrow',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isAdmin)
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
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
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.switch_account_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // SECTIONS
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
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
                      const SizedBox(height: 16),
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
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

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
        content: const Text(
          'The order will be kept in history but removed from the plan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel order'),
          ),
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
  }

  TextDecoration _statusDecoration(ServiceOrder order) {
    if (order.status == OrderStatus.canceled) return TextDecoration.lineThrough;
    return TextDecoration.none;
  }

  IconData? _statusIcon(ServiceOrder order) {
    if (order.status == OrderStatus.done) return Icons.check_circle_rounded;
    if (order.status == OrderStatus.canceled) return Icons.cancel_rounded;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Title bar
    final titleBar = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      child: Row(
        children: [
          Icon(
            title == 'Today' ? Icons.today_rounded : Icons.calendar_month_rounded,
            color: brand,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111111),
            ),
          ),
          const Spacer(),
          Text(
            '${orders.length}',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );

    if (orders.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBar,
          const SizedBox(height: 10),
          _emptyState(),
        ],
      );
    }

    // Group by driver (admin view). If not admin, still works (single driver).
    final grouped = <String, List<ServiceOrder>>{};
    for (final o in orders) {
      grouped.putIfAbsent(o.driverId, () => []).add(o);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        titleBar,
        const SizedBox(height: 12),
        ...grouped.entries.map((entry) {
          final driver = driverRepo.getById(entry.key);
          final driverName = driver?.name ?? 'Unknown';

          final driverOrders = entry.value.toList()
            ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: brand.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: brand.withOpacity(0.14)),
                      ),
                      child: const Icon(
                        Icons.local_shipping_rounded,
                        color: brand,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        driverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Orders list
                ListView.separated(
                  itemCount: driverOrders.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, idx) {
                    final order = driverOrders[idx];
                    final client = clientRepo.getById(order.clientId);
                    final clientName = client?.name ?? 'Client';

                    final hh =
                        order.scheduledAt.hour.toString().padLeft(2, '0');
                    final mm =
                        order.scheduledAt.minute.toString().padLeft(2, '0');

                    final statusColor = _statusColor(order);
                    final statusIcon = _statusIcon(order);

                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
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
                      onLongPress: isAdmin &&
                              order.status == OrderStatus.scheduled
                          ? () => _cancelOrder(context, order)
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7F8),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: brand.withOpacity(0.14),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (statusIcon != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(statusIcon, color: statusColor),
                              )
                            else
                              Container(
                                width: 24,
                                height: 24,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.schedule_rounded,
                                  size: 18,
                                  color: Colors.black.withOpacity(0.35),
                                ),
                              ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$hh:$mm • $clientName',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      decoration: _statusDecoration(order),
                                      color: statusColor ??
                                          const Color(0xFF111111),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${order.serviceType.label} • €${order.price.toStringAsFixed(0)} • ${order.status.label}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.black26,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  static Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: brand.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: brand.withOpacity(0.14)),
            ),
            child: const Icon(Icons.event_available_rounded, color: brand),
          ),
          const SizedBox(height: 10),
          const Text(
            'No orders',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nothing scheduled for this section.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}