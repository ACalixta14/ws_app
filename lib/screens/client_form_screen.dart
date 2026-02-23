import 'package:flutter/material.dart';
import 'package:ws_app/services/supabase_clients_sync_service.dart';

import '../models/client.dart';
import '../models/id_helper.dart';
import '../repositories/client_repository.dart';

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
  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _invoiceCtrl = TextEditingController();

  bool _isValid = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _addressCtrl, _phoneCtrl, _invoiceCtrl]) {
      c.addListener(_recomputeValidity);
    }
    _recomputeValidity();
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
    if (_isSaving) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();

      // Sync before creating (same behavior you already had).
      await SupabaseClientsSyncService(clientRepo: widget.clientRepo).trySync();

      final client = Client(
        id: newId(),
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        invoiceDetails:
            _invoiceCtrl.text.trim().isEmpty ? null : _invoiceCtrl.text.trim(),
        locationLink: null,
        createdAt: now,
        updatedAt: now,
      );

      await widget.clientRepo.add(client);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                                'New Client',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Fill the details to create a client',
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
                // FORM CARD
                // =========================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _cardShell(
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            icon: Icons.badge_rounded,
                            title: 'Client Details',
                          ),
                          const SizedBox(height: 12),

                          _field(
                            label: 'Name *',
                            hint: 'Client name',
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            validator: (v) => _required(v, 'Name'),
                            keyboardType: TextInputType.name,
                            icon: Icons.person_rounded,
                          ),
                          const SizedBox(height: 12),

                          _field(
                            label: 'Address *',
                            hint: 'Street, city…',
                            controller: _addressCtrl,
                            textInputAction: TextInputAction.next,
                            validator: (v) => _required(v, 'Address'),
                            keyboardType: TextInputType.streetAddress,
                            icon: Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 12),

                          _field(
                            label: 'Phone *',
                            hint: 'Contact phone',
                            controller: _phoneCtrl,
                            textInputAction: TextInputAction.next,
                            validator: _phoneValidator,
                            keyboardType: TextInputType.phone,
                            icon: Icons.phone_rounded,
                          ),
                          const SizedBox(height: 12),

                          _field(
                            label: 'Invoice details (optional)',
                            hint: 'NIF, billing name, notes…',
                            controller: _invoiceCtrl,
                            textInputAction: TextInputAction.done,
                            validator: (v) => null,
                            keyboardType: TextInputType.text,
                            icon: Icons.receipt_long_rounded,
                            maxLines: 2,
                          ),
                        ],
                      ),
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
                      _primaryButton(
                        label: _isSaving ? 'Saving…' : 'Save',
                        icon: Icons.check_circle_outline_rounded,
                        enabled: _isValid && !_isSaving,
                        onTap: _save,
                      ),
                      const SizedBox(height: 10),
                      _secondaryButton(
                        label: 'Cancel',
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
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
  // UI HELPERS (same "feel" as AdminHomeScreen)
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

  static Widget _field({
    required String label,
    required String hint,
    required TextEditingController controller,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    required TextInputType keyboardType,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
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
      ),
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
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: enabled ? 1 : 0.55,
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
        Icon(icon, color: _ClientFormScreenState.brand),
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