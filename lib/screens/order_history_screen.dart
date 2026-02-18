import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/order_status.dart';
import '../models/service_order.dart';
import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import 'service_order_detail_screen.dart';

class OrdersHistoryScreen extends StatefulWidget {
  final ServiceOrderRepository orderRepo;
  final DriverRepository driverRepo;
  final ClientRepository clientRepo;

  const OrdersHistoryScreen({
    super.key,
    required this.orderRepo,
    required this.driverRepo,
    required this.clientRepo,
  });

  @override
  State<OrdersHistoryScreen> createState() => _OrdersHistoryScreenState();
}

class _OrdersHistoryScreenState extends State<OrdersHistoryScreen> {
  OrderStatus? _statusFilter;
  String? _driverIdFilter;
  int? _periodDays;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // =====================================================
  // ✅ CSV HUMANO (SEU FORMATO)
  // =====================================================
  String buildOrdersCsv({
    required List<ServiceOrder> orders,
    required ClientRepository clientRepo,
    required DriverRepository driverRepo,
  }) {
    final buffer = StringBuffer();

    // Cabeçalho legível
    buffer.writeln('Cliente,Data,Serviço,Motorista,Valor');

    for (final o in orders) {
      final client = clientRepo.getById(o.clientId);
      final driver = driverRepo.getById(o.driverId);

      final clientName = client?.name ?? '';
      final driverName = driver?.name ?? '';

      final date =
          '${o.scheduledAt.day.toString().padLeft(2, '0')}/'
          '${o.scheduledAt.month.toString().padLeft(2, '0')}/'
          '${o.scheduledAt.year} '
          '${o.scheduledAt.hour.toString().padLeft(2, '0')}:'
          '${o.scheduledAt.minute.toString().padLeft(2, '0')}';

      final service = o.serviceType.label;
      final price = o.price.toStringAsFixed(0);

      buffer.writeln(
        '"$clientName","$date","$service","$driverName","$price"',
      );
    }

    return buffer.toString();
  }

  // =====================================================

  bool _matchesPeriod(ServiceOrder o) {
    if (_periodDays == null) return true;
    final now = DateTime.now();
    final from = now.subtract(Duration(days: _periodDays!));
    return o.scheduledAt.isAfter(from);
  }

  bool _matchesStatus(ServiceOrder o) {
    if (_statusFilter == null) return true;
    return o.status == _statusFilter;
  }

  bool _matchesDriver(ServiceOrder o) {
    if (_driverIdFilter == null) return true;
    return o.driverId == _driverIdFilter;
  }

  bool _matchesQuery(ServiceOrder o) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final client = widget.clientRepo.getById(o.clientId);
    final clientName = (client?.name ?? '').toLowerCase();

    return clientName.contains(q) ||
        o.addressSnapshot.toLowerCase().contains(q) ||
        o.phoneSnapshot.toLowerCase().contains(q);
  }

  List<ServiceOrder> _getOrders() {
    final all = widget.orderRepo.getAll();

    final filtered = all.where((o) {
      return _matchesStatus(o) &&
          _matchesDriver(o) &&
          _matchesPeriod(o) &&
          _matchesQuery(o);
    }).toList();

    filtered.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    return filtered;
  }

  // =====================================================
  // ✅ EXPORT CSV (NOVO)
  // =====================================================
  Future<void> _exportCsv() async {
    final orders = _getOrders();

    final csv = buildOrdersCsv(
      orders: orders,
      clientRepo: widget.clientRepo,
      driverRepo: widget.driverRepo,
    );

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Export CSV (Human readable)',
                        style:
                            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text('${orders.length} linhas'),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 260,
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csv,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy CSV'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: csv));
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('CSV copied to clipboard')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =====================================================

  @override
  Widget build(BuildContext context) {
    final orders = _getOrders();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportCsv,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar cliente...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: orders.isEmpty
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (_, i) {
                      final o = orders[i];
                      final client =
                          widget.clientRepo.getById(o.clientId);
                      final driver =
                          widget.driverRepo.getById(o.driverId);

                      return ListTile(
                        title: Text(client?.name ?? 'Client'),
                        subtitle: Text(
                          '${o.status.label} • ${o.serviceType.label} • ${driver?.name ?? ""}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final changed =
                              await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ServiceOrderDetailScreen(
                                order: o,
                                clientRepo: widget.clientRepo,
                                driverRepo: widget.driverRepo,
                                orderRepo: widget.orderRepo,
                                isAdmin: true,
                              ),
                            ),
                          );
                          if (changed == true) setState(() {});
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
