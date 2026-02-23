import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ws_app/services/supabase_orders_sync_service.dart';

import '../models/order_status.dart';
import '../models/service_order.dart';
import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import 'edit_service_order_screen.dart';

class ServiceOrderDetailScreen extends StatefulWidget {
  final ServiceOrder order;

  final ServiceOrderRepository orderRepo;
  final ClientRepository clientRepo;
  final DriverRepository driverRepo;

  final bool isAdmin;

  const ServiceOrderDetailScreen({
    super.key,
    required this.order,
    required this.orderRepo,
    required this.clientRepo,
    required this.driverRepo,
    required this.isAdmin,
  });

  @override
  State<ServiceOrderDetailScreen> createState() =>
      _ServiceOrderDetailScreenState();
}

class _ServiceOrderDetailScreenState extends State<ServiceOrderDetailScreen> {
  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

  late ServiceOrder _order;
  final _disposalCtrl = TextEditingController();

  bool _isSavingDisposal = false;
  bool _isCanceling = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _disposalCtrl.text = _order.disposalNote ?? '';
  }

  @override
  void dispose() {
    _disposalCtrl.dispose();
    super.dispose();
  }

  void _reloadFromRepo() {
    final refreshed = widget.orderRepo.getById(_order.id);
    if (refreshed == null) return;
    setState(() {
      _order = refreshed;
      _disposalCtrl.text = _order.disposalNote ?? '';
    });
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveDisposalNote() async {
    if (_isSavingDisposal) return;

    final note = _disposalCtrl.text.trim();

    setState(() => _isSavingDisposal = true);
    try {
      final updated = _order.copyWith(
        disposalNote: note.isEmpty ? null : note,
        updatedAt: DateTime.now(),
      );

      await widget.orderRepo.upsert(updated);
      _reloadFromRepo();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nota de descarte salva')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSavingDisposal = false);
    }
  }

  Future<void> _markDone() async {
    if (_order.status != OrderStatus.scheduled) return;

    await widget.orderRepo.markDone(_order.id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _editOrder() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditServiceOrderScreen(
          order: _order,
          driverRepo: widget.driverRepo,
          orderRepo: widget.orderRepo,
        ),
      ),
    );

    if (!mounted) return;
    if (changed == true) _reloadFromRepo();
  }

  Future<void> _cancelOrder() async {
    if (_isCanceling) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text(
          'This order will be kept in history but removed from the plan.',
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

    setState(() => _isCanceling = true);

    try {
      final updated = _order.copyWith(
        status: OrderStatus.canceled,
        updatedAt: DateTime.now(),
      );

      await widget.orderRepo.update(updated);
      _reloadFromRepo();

      // keep your sync call (but after update so it pushes latest state)
      await SupabaseOrdersSyncService(orderRepo: widget.orderRepo).trySync();

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    } finally {
      if (mounted) setState(() => _isCanceling = false);
    }
  }

  String _fmtShortDateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  Color _statusAccent() {
    if (_order.status == OrderStatus.done) return Colors.green;
    if (_order.status == OrderStatus.canceled) return Colors.red;
    return Colors.white;
  }

  IconData _statusIcon() {
    if (_order.status == OrderStatus.done) return Icons.check_circle_rounded;
    if (_order.status == OrderStatus.canceled) return Icons.cancel_rounded;
    return Icons.schedule_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.clientRepo.getById(_order.clientId);
    final driver = widget.driverRepo.getById(_order.driverId);

    final hh = _order.scheduledAt.hour.toString().padLeft(2, '0');
    final mm = _order.scheduledAt.minute.toString().padLeft(2, '0');

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
                              const Text(
                                'Order detail',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$hh:$mm • ${_order.status.label}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: Icon(_statusIcon(), color: _statusAccent()),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // =========================
                // CLIENT / ORDER SUMMARY
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.badge_rounded,
                          title: 'Summary',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          client?.name ?? 'Client',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(label: 'Driver', value: driver?.name ?? 'Unknown'),
                        _InfoRow(label: 'Service', value: _order.serviceType.label),
                        _InfoRow(label: 'Payment', value: _order.paymentMethod.label),
                        _InfoRow(
                          label: 'Price',
                          value: '€${_order.price.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // ADDRESS
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.location_on_rounded,
                          title: 'Address',
                        ),
                        const SizedBox(height: 10),
                        SelectableText(_order.addressSnapshot),
                        const SizedBox(height: 12),
                        _toolButton(
                          icon: Icons.copy_rounded,
                          label: 'Copy address',
                          onTap: () => _copy(_order.addressSnapshot, 'Address copied'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // PHONE
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.phone_rounded,
                          title: 'Phone',
                        ),
                        const SizedBox(height: 10),
                        SelectableText(_order.phoneSnapshot),
                        const SizedBox(height: 12),
                        _toolButton(
                          icon: Icons.copy_rounded,
                          label: 'Copy phone',
                          onTap: () => _copy(_order.phoneSnapshot, 'Phone copied'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // NOTES
                // =========================
                if ((_order.notes ?? '').trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _cardShell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            icon: Icons.notes_rounded,
                            title: 'Admin notes',
                          ),
                          const SizedBox(height: 10),
                          Text((_order.notes ?? '').trim()),
                        ],
                      ),
                    ),
                  ),

                if ((_order.notes ?? '').trim().isNotEmpty)
                  const SizedBox(height: 14),

                // =========================
                // DISPOSAL NOTE
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.delete_outline_rounded,
                          title: 'Disposal note (driver)',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _disposalCtrl,
                          minLines: 2,
                          maxLines: 5,
                          decoration: _fieldDecoration(
                            label: 'Where was it dumped?',
                            hint: 'Write the location / instructions…',
                            icon: Icons.edit_note_rounded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _toolButton(
                          icon: Icons.save_rounded,
                          label: _isSavingDisposal ? 'Saving…' : 'Save disposal note',
                          onTap: _isSavingDisposal ? () {} : _saveDisposalNote,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // ACTIONS
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      if (_order.status == OrderStatus.scheduled)
                        _primaryButton(
                          label: 'Concluir serviço',
                          icon: Icons.check_circle_outline_rounded,
                          enabled: true,
                          onTap: _markDone,
                        ),
                      if (_order.status == OrderStatus.scheduled)
                        const SizedBox(height: 10),
                      if (widget.isAdmin && _order.status == OrderStatus.scheduled)
                        _toolButton(
                          icon: Icons.cancel_rounded,
                          label: _isCanceling ? 'Canceling…' : 'Cancel order',
                          isDanger: true,
                          onTap: _isCanceling ? () {} : _cancelOrder,
                        ),
                      if (widget.isAdmin && _order.status == OrderStatus.scheduled)
                        const SizedBox(height: 10),
                      if (widget.isAdmin)
                        _secondaryButton(
                          label: 'Edit',
                          icon: Icons.edit_rounded,
                          onTap: _editOrder,
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // =========================
                // META
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _SectionTitle(
                          icon: Icons.info_outline_rounded,
                          title: 'Meta',
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          label: 'Created',
                          value: _fmtShortDateTime(_order.createdAt),
                        ),
                        _InfoRow(
                          label: 'Updated',
                          value: _fmtShortDateTime(_order.updatedAt),
                        ),
                      ],
                    ),
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

  static Widget _primaryButton({
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [brand, brand2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 14,
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  static Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: brand.withOpacity(0.18)),
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
            Icon(icon, color: brand),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111111),
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
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
        Icon(icon, color: _ServiceOrderDetailScreenState.brand),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}