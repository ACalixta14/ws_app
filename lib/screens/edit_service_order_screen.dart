import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../models/service_order.dart';
import '../models/service_type.dart';
import '../models/payment_method.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';

class EditServiceOrderScreen extends StatefulWidget {
  final ServiceOrder order;
  final DriverRepository driverRepo;
  final ServiceOrderRepository orderRepo;

  const EditServiceOrderScreen({
    super.key,
    required this.order,
    required this.driverRepo,
    required this.orderRepo,
  });

  @override
  State<EditServiceOrderScreen> createState() => _EditServiceOrderScreenState();
}

class _EditServiceOrderScreenState extends State<EditServiceOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _driverId;
  late DateTime _date;
  late TimeOfDay _time;

  late ServiceType _serviceType;
  late PaymentMethod _paymentMethod;

  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _canSave = true;

  @override
  void initState() {
    super.initState();
    _driverId = widget.order.driverId;
    _date = DateTime(widget.order.scheduledAt.year, widget.order.scheduledAt.month, widget.order.scheduledAt.day);
    _time = TimeOfDay(hour: widget.order.scheduledAt.hour, minute: widget.order.scheduledAt.minute);

    _serviceType = widget.order.serviceType;
    _paymentMethod = widget.order.paymentMethod;

    _priceCtrl.text = widget.order.price.toStringAsFixed(0);
    _notesCtrl.text = widget.order.notes ?? '';

    _priceCtrl.addListener(_recomputeCanSave);
  }

  void _recomputeCanSave() {
    final priceOk = double.tryParse(_priceCtrl.text.trim()) != null;
    final newValue = priceOk;
    if (newValue != _canSave) setState(() => _canSave = newValue);
  }

  DateTime _buildScheduledAt() {
    return DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
  }

  String? _priceValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Price is required';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Price must be a number';
    if (parsed <= 0) return 'Price must be greater than 0';
    return null;
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final updated = widget.order.copyWith(
      driverId: _driverId,
      scheduledAt: _buildScheduledAt(),
      serviceType: _serviceType,
      paymentMethod: _paymentMethod,
      price: double.parse(_priceCtrl.text.trim()),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      updatedAt: DateTime.now(),
      // keep status as-is
    );

    await widget.orderRepo.update(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order updated')),
    );
    Navigator.pop(context, true);
  }

  Future<void> _cancel() async {
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

    final updated = widget.order.copyWith(
      status: OrderStatus.canceled,
      updatedAt: DateTime.now(),
    );

    await widget.orderRepo.update(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order canceled')),
    );
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drivers = widget.driverRepo.getAll();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _driverId,
                decoration: const InputDecoration(labelText: 'Driver *'),
                items: drivers
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                    .toList(),
                onChanged: (v) => setState(() => _driverId = v ?? _driverId),
              ),
              const SizedBox(height: 12),

              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date'),
                subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Time'),
                subtitle: Text(_time.format(context)),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (picked != null) setState(() => _time = picked);
                },
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<ServiceType>(
                value: _serviceType,
                decoration: const InputDecoration(labelText: 'Service type'),
                items: ServiceType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) => setState(() => _serviceType = v ?? _serviceType),
              ),

              const SizedBox(height: 12),

              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment method'),
                items: PaymentMethod.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                    .toList(),
                onChanged: (v) => setState(() => _paymentMethod = v ?? _paymentMethod),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (€) *'),
                validator: _priceValidator,
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes (optional)'),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSave ? _save : null,
                  child: const Text('Save changes'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _cancel,
                  child: const Text('Cancel order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
