import 'package:flutter/material.dart';

import '../models/id_helper.dart';
import '../models/payment_method.dart';
import '../models/service_order.dart';
import '../models/service_type.dart';
import '../repositories/client_repository.dart';
import '../repositories/driver_repository.dart';
import '../repositories/service_order_repository.dart';
import '../services/supabase_orders_sync_service.dart';
import '../services/supabase_sync_service.dart';
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
  State<CreateServiceOrderScreen> createState() =>
      _CreateServiceOrderScreenState();
}

class _CreateServiceOrderScreenState extends State<CreateServiceOrderScreen> {
  static const Color brand = Color(0xFF044950);
  static const Color brand2 = Color(0xFF0A6C74);

  final _formKey = GlobalKey<FormState>();

  String? _clientId;
  String? _driverId;

  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();

  ServiceType _serviceType = ServiceType.hauling;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

//cria uma "caixinha de texto controlada"
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _serviceAdressCtrl = TextEditingController();
//cada paragem vai ter sua própria caixa de texto||Essa lista guarda todas elas
  final List<TextEditingController>_stopCtrls = [];

  bool _canSave = false;
  bool _isSaving = false;

//ao digitar a morada, o botão e a validação serão recalculados.
  @override
  void initState() {
    super.initState();
    _syncPriceWithServiceType();
    _priceCtrl.addListener(_recomputeCanSave);
    _notesCtrl.addListener(_recomputeCanSave);
    _serviceAdressCtrl.addListener(_recomputeCanSave);
    _recomputeCanSave();
  }

//cria uma nova paragem
  void _addStop() {
    setState(() {
      _stopCtrls.add(TextEditingController());
    });
  }
//remove uma paragem específica
  void _removeStop(int index){
    setState(() {
      _stopCtrls[index].dispose();
      _stopCtrls.removeAt(index);
    });
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

//Botão só salva a ordem se tiver essas condições
  void _recomputeCanSave() {
    final hasClient = _clientId != null;
    final hasDriver = _driverId != null;
    final hasServiceAddress = _serviceAdressCtrl.text.trim().isNotEmpty;

    final priceOk = _serviceType == ServiceType.miscellaneous
        ? (_priceCtrl.text.trim().isNotEmpty &&
            double.tryParse(_priceCtrl.text.trim()) != null)
        : true;

    final newValue = 
      hasClient && hasDriver && hasServiceAddress && priceOk && !_isSaving;

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

  String? _requiredDropdown<T>(T? v, String label) {
    if (v == null) return '$label é obrigatório';
    return null;
  }

  String? _priceValidator(String? v) {
    final text = v?.trim() ?? '';

    if (_serviceType == ServiceType.miscellaneous) {
      if (text.isEmpty) return 'O preço é obrigatório para Diversos';
      final parsed = double.tryParse(text);
      if (parsed == null) return 'O preço deve ser um número';
      if (parsed <= 0) return 'O preço deve ser maior que 0';
      return null;
    }

    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'O preço deve ser um número';
    if (parsed <= 0) return 'O preço deve ser maior que 0';
    return null;
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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

  Future<void> _goCreateClient() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientFormScreen(clientRepo: widget.clientRepo),
      ),
    );

    if (!mounted) return;

    if (created == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente salvo')),
      );
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Corrija os erros antes de salvar')),
      );
      return;
    }

    final client = widget.clientRepo.getById(_clientId!);
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente selecionado não encontrado')),
      );
      return;
    }

    final scheduledAt = _buildScheduledAt();

    final parsedPrice = _priceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_priceCtrl.text.trim());

    setState(() {
      _isSaving = true;
      _recomputeCanSave();
    });

    try {
      
//transforma os campos das paragens em uma lista de strings real para salvar na ordem.
      final stops = _stopCtrls
      .map((c) => c.text.trim())
      .where((text) => text.isNotEmpty)
      .toList();

      final order = ServiceOrder.create(
        id: newId(),
        clientId: client.id,
        driverId: _driverId!,
        scheduledAt: scheduledAt,
        serviceType: _serviceType,
        paymentMethod: _paymentMethod,
        price: parsedPrice,
        serviceAddress: _serviceAdressCtrl.text.trim(),
        additionalStops: const [],
        phoneSnapshot: client.phone,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      await widget.orderRepo.add(order);

      await SupabaseSyncService(
        clientRepo: widget.clientRepo,
        orderRepo: widget.orderRepo,
      ).trySyncAll();

      await SupabaseOrdersSyncService(orderRepo: widget.orderRepo).trySync();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem salva')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
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

//Libera a memória do controllers
  @override
  void dispose() {
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    _serviceAdressCtrl.dispose();
     
//fecha corretamente todos os controllers das paragens e evita vazamento de memória.
      for (final ctrl in _stopCtrls) {
    ctrl.dispose();
  }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clients = widget.clientRepo.getAll();
    final drivers = widget.driverRepo.getAll();
    const double maxContentWidth = 520;

    if (clients.isEmpty) {
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
                  _header(
                    context,
                    title: 'Criar Ordem',
                    subtitle: 'Você precisa de pelo menos 1 cliente primeiro',
                    trailing: const SizedBox(width: 44, height: 44),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _cardShell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionTitle(
                            icon: Icons.info_outline_rounded,
                            title: 'Antes de começar',
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Você precisa de pelo menos 1 cliente antes de criar uma ordem.',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 14),
                          _toolButton(
                            icon: Icons.person_add_alt_1_rounded,
                            label: 'Criar primeiro cliente',
                            onTap: _goCreateClient,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final misc = _serviceType == ServiceType.miscellaneous;

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
                _header(
                  context,
                  title: 'Criar Ordem',
                  subtitle: 'Escolha cliente, motorista, data e detalhes',
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
//======================== Caixa do cliente =====================
                const SizedBox(height: 16),

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
                            icon: Icons.assignment_rounded,
                            title: 'Detalhes da Ordem',
                          ),
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: _clientId,
                            decoration: _ddDecoration(
                              label: 'Cliente *',
                              icon: Icons.people_alt_rounded,
                            ),
                            items: clients
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            validator: (v) => _requiredDropdown(v, 'Cliente'),
                            onChanged: (v) {
                              setState(() => _clientId = v);
                              _recomputeCanSave();
                            },
                          ),
//======================== Caixa do motorista =====================
                          const SizedBox(height: 12),

                          DropdownButtonFormField<String>(
                            value: _driverId,
                            decoration: _ddDecoration(
                              label: 'Motorista *',
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
                            validator: (v) => _requiredDropdown(v, 'Motorista'),
                            onChanged: (v) {
                              setState(() => _driverId = v);
                              _recomputeCanSave();
                            },
                          ),
//======================== Caixa data hora =====================
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: _pickerTile(
                                  title: 'Data *',
                                  subtitle: _fmtDate(_date),
                                  icon: Icons.calendar_today_rounded,
                                  onTap: _pickDate,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _pickerTile(
                                  title: 'Hora *',
                                  subtitle: _time.format(context),
                                  icon: Icons.schedule_rounded,
                                  onTap: _pickTime,
                                ),
                              ),
                            ],
                          ),
//======================== Caixa do tipo de serviço =====================
                          const SizedBox(height: 12),

                          DropdownButtonFormField<ServiceType>(
                            value: _serviceType,
                            decoration: _ddDecoration(
                              label: 'Tipo de serviço *',
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
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _serviceType = v);
                              _syncPriceWithServiceType();
                            },
                          ),
//======================== Caixa do método de pagamento =====================
                          const SizedBox(height: 12),

                          DropdownButtonFormField<PaymentMethod>(
                            value: _paymentMethod,
                            decoration: _ddDecoration(
                              label: 'Método de pagamento *',
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
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _paymentMethod = v);
                            },
                          ),
//======================== Caixa dos preços =====================
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _fieldDecoration(
                              label: 'Preço (€) ${misc ? "*" : ""}',
                              hint: misc
                                  ? 'Digite um preço personalizado'
                                  : 'Valor padrão aplicado (você pode alterar)',
                              icon: Icons.euro_rounded,
                              helperText: misc
                                  ? 'Obrigatório para Diversos'
                                  : 'Opcional — preenchido automaticamente pelo tipo de serviço',
                            ),
                            validator: _priceValidator,
                            onChanged: (_) => _recomputeCanSave(),
                          ),
//======================== Caixa das paragens =====================
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _serviceAdressCtrl,
                            maxLines: 2,
                            decoration: _fieldDecoration(
                              label:'Morada do serviço *', 
                              hint: 'Onde será feito o serviço', 
                              icon: Icons.location_on_rounded,
                              ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty){
                              return 'A morada do serviço é obrigatória!';
                            }
                            return null;
                          }
                          ),
//======================== Caixa das paragens =====================     
                        const SizedBox(height: 12),

Row(
  children: [
    const Expanded(
      child: Text(
        'Paragens (opcional)',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Color(0xFF111111),
        ),
      ),
    ),
    TextButton.icon(
      onPressed: _addStop,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Adicionar'),
    ),
  ],
),

if (_stopCtrls.isEmpty)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF6F7F8),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: brand.withOpacity(0.12)),
    ),
    child: const Text(
      'Nenhuma paragem adicionada.',
      style: TextStyle(color: Colors.black54),
    ),
  ),

if (_stopCtrls.isNotEmpty)
  Column(
    children: List.generate(_stopCtrls.length, (index) {
      return Padding(
        padding: EdgeInsets.only(bottom: index == _stopCtrls.length - 1 ? 0 : 12),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _stopCtrls[index],
                maxLines: 2,
                decoration: _fieldDecoration(
                  label: 'Paragem ${index + 1}',
                  hint: 'Morada da paragem',
                  icon: Icons.place_rounded,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _removeStop(index),
              icon: const Icon(Icons.delete_outline_rounded),
              color: Colors.red,
            ),
          ],
        ),
      );
    }),
  ),




//======================== Caixa das observações =====================

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            decoration: _fieldDecoration(
                              label: 'Observações (opcional)',
                              hint: 'Informações extras para o motorista…',
                              icon: Icons.notes_rounded,
                            ),
                          ),
                        ],
                      ),

 //===========================ORDEM SALVA texto==============
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _primaryButton(
                        label: _isSaving ? 'Salvando…' : 'Salvar ordem',
                        icon: Icons.check_circle_outline_rounded,
                        enabled: _canSave && !_isSaving,
                        onTap: _save,
                      ),
                      const SizedBox(height: 10),
                      _secondaryButton(
                        label: 'Cancelar',
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
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
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
        Icon(icon, color: _CreateServiceOrderScreenState.brand),
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