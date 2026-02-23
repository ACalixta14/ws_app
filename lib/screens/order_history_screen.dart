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
  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

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

      buffer.writeln('"$clientName","$date","$service","$driverName","$price"');
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
  // ✅ EXPORT CSV (BOTTOM SHEET)
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text('${orders.length} linhas'),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 260,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7F8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: brand.withOpacity(0.18)),
                  ),
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
                        const SnackBar(content: Text('CSV copied to clipboard')),
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
  // UI: filters (opcional)
  // =====================================================
  void _clearFilters() {
    setState(() {
      _statusFilter = null;
      _driverIdFilter = null;
      _periodDays = null;
      _query = '';
      _searchCtrl.text = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final orders = _getOrders();
    final drivers = widget.driverRepo.getAll();
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Orders History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Search, filter and export to CSV',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _exportCsv,
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
                              Icons.download_rounded,
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
                // SEARCH + FILTERS CARD
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.filter_alt_rounded,
                          title: 'Filters',
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _query = v),
                          decoration: _fieldDecoration(
                            label: 'Buscar cliente...',
                            hint: 'Nome, endereço ou telefone',
                            icon: Icons.search_rounded,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<OrderStatus?>(
                                value: _statusFilter,
                                decoration: _ddDecoration(
                                  label: 'Status',
                                  icon: Icons.flag_rounded,
                                ),
                                items: [
                                  const DropdownMenuItem<OrderStatus?>(
                                    value: null,
                                    child: Text('All'),
                                  ),
                                  ...OrderStatus.values.map(
                                    (s) => DropdownMenuItem<OrderStatus?>(
                                      value: s,
                                      child: Text(s.label),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _statusFilter = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String?>(
                                value: _driverIdFilter,
                                decoration: _ddDecoration(
                                  label: 'Driver',
                                  icon: Icons.local_shipping_rounded,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('All'),
                                  ),
                                  ...drivers.map(
                                    (d) => DropdownMenuItem<String?>(
                                      value: d.id,
                                      child: Text(d.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) =>
                                    setState(() => _driverIdFilter = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField<int?>(
                          value: _periodDays,
                          decoration: _ddDecoration(
                            label: 'Period',
                            icon: Icons.date_range_rounded,
                          ),
                          items: const [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text('All time'),
                            ),
                            DropdownMenuItem<int?>(
                              value: 7,
                              child: Text('Last 7 days'),
                            ),
                            DropdownMenuItem<int?>(
                              value: 30,
                              child: Text('Last 30 days'),
                            ),
                            DropdownMenuItem<int?>(
                              value: 90,
                              child: Text('Last 90 days'),
                            ),
                          ],
                          onChanged: (v) => setState(() => _periodDays = v),
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: _toolButton(
                                icon: Icons.download_rounded,
                                label: 'Export CSV',
                                onTap: _exportCsv,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _toolButton(
                                icon: Icons.clear_all_rounded,
                                label: 'Clear filters',
                                onTap: _clearFilters,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // LIST / EMPTY
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: orders.isEmpty
                      ? _emptyState()
                      : Column(
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
                                border: Border.all(
                                  color: brand.withOpacity(0.18),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.history_rounded, color: brand),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Results',
                                    style: TextStyle(
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
                            ),
                            const SizedBox(height: 12),
                            ListView.separated(
                              itemCount: orders.length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 10),
                              itemBuilder: (_, i) {
                                final o = orders[i];
                                final client = widget.clientRepo.getById(o.clientId);
                                final driver = widget.driverRepo.getById(o.driverId);

                                return _orderCard(
                                  title: client?.name ?? 'Client',
                                  subtitle:
                                      '${o.status.label} • ${o.serviceType.label} • ${driver?.name ?? ""}',
                                  onTap: () async {
                                    final changed = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ServiceOrderDetailScreen(
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

  // =========================
  // UI HELPERS
  // =========================
  static Widget _cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  static InputDecoration _ddDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: brand, width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  static InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF6F7F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: brand, width: 1.3),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  static Widget _toolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final border =
        isDanger ? Colors.red.withOpacity(0.35) : brand.withOpacity(0.18);
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

  static Widget _orderCard({
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
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: brand.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: brand.withOpacity(0.14)),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: brand, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
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
            child: const Icon(Icons.search_off_rounded, color: brand),
          ),
          const SizedBox(height: 10),
          const Text(
            'No orders found',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try adjusting filters or search terms.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;

  const _SectionTitle({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _OrdersHistoryScreenState.brand),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111111),
          ),
        ),
      ],
    );
  }
}