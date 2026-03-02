import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final Widget next;
  final Duration duration;

  const SplashScreen({
    super.key,
    required this.next,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(widget.duration, () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => widget.next),
      );
    });
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