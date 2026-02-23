import 'package:flutter/material.dart';

import '../models/order_status.dart';
import '../models/payment_method.dart';
import '../models/service_order.dart';
import '../models/service_type.dart';
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
  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

  final _formKey = GlobalKey<FormState>();

  late String _driverId;
  late DateTime _date;
  late TimeOfDay _time;

  late ServiceType _serviceType;
  late PaymentMethod _paymentMethod;

  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  bool _canSave = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _driverId = widget.order.driverId;
    _date = DateTime(
      widget.order.scheduledAt.year,
      widget.order.scheduledAt.month,
      widget.order.scheduledAt.day,
    );
    _time = TimeOfDay(
      hour: widget.order.scheduledAt.hour,
      minute: widget.order.scheduledAt.minute,
    );

    _serviceType = widget.order.serviceType;
    _paymentMethod = widget.order.paymentMethod;

    _priceCtrl.text = widget.order.price.toStringAsFixed(0);
    _notesCtrl.text = widget.order.notes ?? '';

    _priceCtrl.addListener(_recomputeCanSave);
    _recomputeCanSave();
  }

  void _recomputeCanSave() {
    final priceOk = double.tryParse(_priceCtrl.text.trim()) != null;
    final newValue = priceOk && !_isSaving;
    if (newValue != _canSave) setState(() => _canSave = newValue);
  }

  DateTime _buildScheduledAt() {
    return DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  String? _priceValidator(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return 'Price is required';
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Price must be a number';
    if (parsed <= 0) return 'Price must be greater than 0';
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors before saving')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _recomputeCanSave();
    });

    try {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _recomputeCanSave();
        });
      }
    }
  }

  Future<void> _cancel() async {
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

    setState(() {
      _isSaving = true;
      _recomputeCanSave();
    });

    try {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _recomputeCanSave();
        });
      }
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
                _header(
                  context,
                  title: 'Edit Order',
                  subtitle: 'Update driver, schedule and details',
                  trailing: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _canSave ? _save : null,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_canSave ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.18),
                        ),
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white),
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
                            icon: Icons.edit_rounded,
                            title: 'Order Details',
                          ),
                          const SizedBox(height: 12),

                          // Driver
                          DropdownButtonFormField<String>(
                            value: _driverId,
                            decoration: _ddDecoration(
                              label: 'Driver *',
                              icon: Icons.local_shipping_rounded,
                            ),
                            items: drivers
                                .map(
                                  (d) => DropdownMenuItem(
                                    value: d.id,
                                    child: Text(d.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _driverId = v ?? _driverId),
                          ),
                          const SizedBox(height: 12),

                          // Date/Time
                          Row(
                            children: [
                              Expanded(
                                child: _pickerTile(
                                  title: 'Date',
                                  subtitle: _fmtDate(_date),
                                  icon: Icons.calendar_today_rounded,
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _pickerTile(
                                  title: 'Time',
                                  subtitle: _time.format(context),
                                  icon: Icons.schedule_rounded,
                                  onTap: _pickTime,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Service type
                          DropdownButtonFormField<ServiceType>(
                            value: _serviceType,
                            decoration: _ddDecoration(
                              label: 'Service type',
                              icon: Icons.handyman_rounded,
                            ),
                            items: ServiceType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(t.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _serviceType = v ?? _serviceType,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Payment
                          DropdownButtonFormField<PaymentMethod>(
                            value: _paymentMethod,
                            decoration: _ddDecoration(
                              label: 'Payment method',
                              icon: Icons.payments_rounded,
                            ),
                            items: PaymentMethod.values
                                .map(
                                  (p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(
                              () => _paymentMethod = v ?? _paymentMethod,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Price
                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(
                              label: 'Price (€) *',
                              hint: 'Enter the final price',
                              icon: Icons.euro_rounded,
                            ),
                            validator: _priceValidator,
                          ),

                          const SizedBox(height: 12),

                          // Notes
                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: _fieldDecoration(
                              label: 'Notes (optional)',
                              hint: 'Extra info…',
                              icon: Icons.notes_rounded,
                            ),
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
                        label: _isSaving ? 'Saving…' : 'Save changes',
                        icon: Icons.check_circle_outline_rounded,
                        enabled: _canSave && !_isSaving,
                        onTap: _save,
                      ),
                      const SizedBox(height: 10),
                      _toolButton(
                        icon: Icons.block_rounded,
                        label: 'Cancel order',
                        isDanger: true,
                        onTap: _cancel,
                      ),
                      const SizedBox(height: 10),
                      _secondaryButton(
                        label: 'Back',
                        icon: Icons.arrow_back_rounded,
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
  // HEADER
  // =========================
  static Widget _header(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [brand, brand2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
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
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            trailing,
          ],
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

  static Widget _pickerTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
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
        Icon(icon, color: _EditServiceOrderScreenState.brand),
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