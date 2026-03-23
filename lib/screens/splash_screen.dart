import 'package:flutter/material.dart';

import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';
import '../services/supabase_sync_service.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  final Duration duration;
  final ClientRepository clientRepo;
  final ServiceOrderRepository orderRepo;

  const SplashScreen({
    super.key,
    required this.next,
    required this.clientRepo,
    required this.orderRepo,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _bootstrap() async {
    debugPrint('SPLASH BOOTSTRAP START');

    await Future.delayed(widget.duration);

    debugPrint('ANTES DO trySyncAll');

    await SupabaseSyncService(
      clientRepo: widget.clientRepo,
      orderRepo: widget.orderRepo,
    ).trySyncAll();

    debugPrint('DEPOIS DO trySyncAll');

    if (!mounted) return;

    debugPrint('INDO PARA A PRÓXIMA TELA');

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.next),
    );
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.brand,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Image.asset(
            'assets/images/logo.png',
            width: 150,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}