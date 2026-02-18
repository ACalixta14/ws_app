import 'package:flutter/material.dart';

import '../models/id_helper.dart';
import '../models/service_order.dart';
import '../models/service_type.dart';
import '../models/payment_method.dart';
import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import 'client_form_screen.dart';

class CreateServiceOrderScreen extends StatefulWidget {
  final ClientRepository clientRepo;
  final DriverRepository driverRepo;
  final ServiceOrderRepository orderRepo;

  const CreateServiceOrderScreen({
    super.key,
    required this.clientRepo,
    required this.driverRepo,
    required this.orderRepo,
  });

  @override
  State<CreateServiceOrderScreen> createState() => _CreateServiceOrderScreenState();
}

class _CreateServiceOrderScreenState extends State<CreateServiceOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _clientId;
  String? _driverId;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  ServiceType _serviceType = ServiceType.hauling;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _syncPriceWithServiceType();
    _priceCtrl.addListener(_recomputeCanSave);
    _notesCtrl.addListener(_recomputeCanSave);
  }

  void _syncPriceWithServiceType() {
    final p = _serviceType.defaultPrice;
    if (_serviceType == ServiceType.miscellaneous) {
      _priceCtrl.text = '';
    } else {
      _priceCtrl.text = (p ?? 0).toStringAsFixed(0);
    }
    _recomputeCanSave();
  }

  void _recomputeCanSave() {
    final hasClient = _clientId != null;
    final hasDriver = _driverId != null;

    final priceOk = _serviceType == ServiceType.miscellaneous
        ? (_priceCtrl.text.trim().isNotEmpty && double.tryParse(_priceCtrl.text.trim()) != null)
        : true;

    final newValue = hasClient && hasDriver && priceOk;
    if (newValue != _canSave) setState(() => _canSave = newValue);
  }

  DateTime _buildScheduledAt() {
    return DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
  }

  String? _requiredDropdown<T>(T? v, String label) {
    if (v == null) return '$label is required';
    return null;
  }

  String? _priceValidator(String? v) {
    final text = v?.trim() ?? '';
    if (_serviceType == ServiceType.miscellaneous) {
      if (text.isEmpty) return 'Price is required for Miscellaneous';
      final parsed = double.tryParse(text);
      if (parsed == null) return 'Price must be a number';
      if (parsed <= 0) return 'Price must be greater than 0';
      return null;
    }

    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Price must be a number';
    if (parsed <= 0) return 'Price must be greater than 0';
    return null;
  }

  Future<void> _goCreateClient() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(clientRepo: widget.clientRepo),
      ),
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client saved')),
      );
      setState(() {});
    }
  }

  Future<void> _save() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before saving')),
      );
      return;
    }

    final client = widget.clientRepo.getById(_clientId!);
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected client not found')),
      );
      return;
    }

    final scheduledAt = _buildScheduledAt();

    final parsedPrice = _priceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_priceCtrl.text.trim());

    try {
      final order = ServiceOrder.create(
        id: newId(),
        clientId: client.id,
        driverId: _driverId!,
        scheduledAt: scheduledAt,
        serviceType: _serviceType,
        paymentMethod: _paymentMethod,
        price: parsedPrice,
        addressSnapshot: client.address,
        phoneSnapshot: client.phone,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await widget.orderRepo.add(order);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order saved')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = widget.clientRepo.getAll();
    final drivers = widget.driverRepo.getAll();

    if (clients.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Service Order')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('You need at least 1 client before creating an order.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _goCreateClient,
                icon: const Icon(Icons.person_add),
                label: const Text('Create first client'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Service Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _clientId,
                decoration: const InputDecoration(labelText: 'Client *'),
                items: clients
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                validator: (v) => _requiredDropdown(v, 'Client'),
                onChanged: (v) {
                  setState(() => _clientId = v);
                  _recomputeCanSave();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _driverId,
                decoration: const InputDecoration(labelText: 'Driver *'),
                items: drivers
                    .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                    .toList(),
                validator: (v) => _requiredDropdown(v, 'Driver'),
                onChanged: (v) {
                  setState(() => _driverId = v);
                  _recomputeCanSave();
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date *'),
                subtitle: Text(
                  '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                ),
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
                title: const Text('Time *'),
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
                decoration: const InputDecoration(labelText: 'Service type *'),
                items: ServiceType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _serviceType = v);
                  _syncPriceWithServiceType();
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment method *'),
                items: PaymentMethod.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _paymentMethod = v);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price (€) ${_serviceType == ServiceType.miscellaneous ? "*" : ""}',
                  helperText: _serviceType == ServiceType.miscellaneous
                      ? 'Required for Miscellaneous'
                      : 'Default applied automatically (you can override)',
                ),
                validator: _priceValidator,
                onChanged: (_) => _recomputeCanSave(),
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
                  child: const Text('Save order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
