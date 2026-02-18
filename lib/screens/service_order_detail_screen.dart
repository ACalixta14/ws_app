import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  State<ServiceOrderDetailScreen> createState() => _ServiceOrderDetailScreenState();
}

class _ServiceOrderDetailScreenState extends State<ServiceOrderDetailScreen> {
  late ServiceOrder _order;
  final _disposalCtrl = TextEditingController();

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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDisposalNote() async {
    final note = _disposalCtrl.text.trim();

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
  }

  Future<void> _markDone() async {
    if (_order.status != OrderStatus.scheduled) return;

    await widget.orderRepo.markDone(_order.id);

    if (!mounted) return;
    Navigator.pop(context, true); // avisa a tela anterior para refresh
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

    if (changed == true) {
      _reloadFromRepo();
    }
  }

  Future<void> _cancelOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel order?'),
        content: const Text('This order will be kept in history but removed from the plan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Cancel order')),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = _order.copyWith(
      status: OrderStatus.canceled,
      updatedAt: DateTime.now(),
    );

    await widget.orderRepo.update(updated);
    _reloadFromRepo();

    if (!mounted) return;
    Navigator.pop(context, true); // volta e força refresh no plan/history
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.clientRepo.getById(_order.clientId);
    final driver = widget.driverRepo.getById(_order.driverId);

    final hh = _order.scheduledAt.hour.toString().padLeft(2, '0');
    final mm = _order.scheduledAt.minute.toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order detail'),
        actions: [
          if (widget.isAdmin)
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit),
              onPressed: _editOrder,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            client?.name ?? 'Client',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text('$hh:$mm • ${_order.status.label}'),
          const SizedBox(height: 12),

          _InfoRow(label: 'Driver', value: driver?.name ?? 'Unknown'),
          _InfoRow(label: 'Service', value: _order.serviceType.label),
          _InfoRow(label: 'Payment', value: _order.paymentMethod.label),
          _InfoRow(label: 'Price', value: '€${_order.price.toStringAsFixed(0)}'),

          const SizedBox(height: 16),

          const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SelectableText(_order.addressSnapshot),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy address'),
              onPressed: () => _copy(_order.addressSnapshot, 'Address copied'),
            ),
          ),

          const SizedBox(height: 16),

          const Text('Phone', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          SelectableText(_order.phoneSnapshot),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copy phone'),
              onPressed: () => _copy(_order.phoneSnapshot, 'Phone copied'),
            ),
          ),

          const SizedBox(height: 16),

          if ((_order.notes ?? '').trim().isNotEmpty) ...[
            const Text('Admin notes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text((_order.notes ?? '').trim()),
            const SizedBox(height: 16),
          ],

          const Text('Disposal note (driver)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextField(
            controller: _disposalCtrl,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Where was it dumped?',
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save disposal note'),
              onPressed: _saveDisposalNote,
            ),
          ),

          const SizedBox(height: 16),

          if (_order.status == OrderStatus.scheduled) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('Concluir serviço'),
                onPressed: _markDone,
              ),
            ),
            const SizedBox(height: 10),
          ],

          if (widget.isAdmin && _order.status == OrderStatus.scheduled) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel order'),
                onPressed: _cancelOrder,
              ),
            ),
          ],

          const SizedBox(height: 18),
          _InfoRow(label: 'Created', value: _order.createdAt.toString()),
          _InfoRow(label: 'Updated', value: _order.updatedAt.toString()),
        ],
      ),
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
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
