import 'package:flutter/material.dart';

class WatermarkBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double logoWidth;

  const WatermarkBackground({
    super.key,
    required this.child,
    this.opacity = 0.07,
    this.logoWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1) Conteúdo normal (telas)
        Positioned.fill(child: child),

        // 2) Marca d'água por CIMA do conteúdo (garante aparecer)
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity: opacity,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: logoWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}