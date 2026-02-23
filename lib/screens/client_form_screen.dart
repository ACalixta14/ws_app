import 'package:flutter/material.dart';
import 'package:ws_app/services/supabase_clients_sync_service.dart';

import '../models/client.dart';
import '../models/id_helper.dart';
import '../repositories/client_repository.dart';
import '../services/supabase_sync_service.dart';

class ClientFormScreen extends StatefulWidget {
  final ClientRepository clientRepo;

  const ClientFormScreen({
    super.key,
    required this.clientRepo,
  });

  @override
  State<ClientFormScreen> createState() => _ClientFormScreenState();
}

class _ClientFormScreenState extends State<ClientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();

  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _addressCtrl, _phoneCtrl, _invoiceCtrl]) {
      c.addListener(_recomputeValidity);
    }
  }

  void _recomputeValidity() {
    final valid = _nameCtrl.text.trim().isNotEmpty &&
        _addressCtrl.text.trim().isNotEmpty &&
        _phoneCtrl.text.trim().isNotEmpty;

    if (valid != _isValid) setState(() => _isValid = valid);
  }

  String? _required(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _phoneValidator(String? v) {
    final value = v?.trim() ?? '';
    if (value.isEmpty) return 'Phone is required';
    if (value.length < 6) return 'Phone seems too short';
    return null;
  }

  Future<void> _save() async {
final now = DateTime.now();
await SupabaseClientsSyncService(clientRepo: widget.clientRepo).trySync();

final client = Client(
  id: newId(),
  name: _nameCtrl.text.trim(),
  address: _addressCtrl.text.trim(),
  phone: _phoneCtrl.text.trim(),
  invoiceDetails: _invoiceCtrl.text.trim().isEmpty ? null : _invoiceCtrl.text.trim(),
  locationLink: null,
  createdAt: now,
  updatedAt: now,
);
    await widget.clientRepo.add(client);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _invoiceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Client')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => _required(v, 'Name'),
                textInputAction: TextInputAction.next,
              ),
              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(labelText: 'Address *'),
                validator: (v) => _required(v, 'Address'),
                textInputAction: TextInputAction.next,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone *'),
                keyboardType: TextInputType.phone,
                validator: _phoneValidator,
                textInputAction: TextInputAction.next,
              ),
              TextFormField(
                controller: _invoiceCtrl,
                decoration: const InputDecoration(labelText: 'Invoice details (optional)'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isValid ? _save : null,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
