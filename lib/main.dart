import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'l10n/app_strings.dart';
import 'l10n/locale_controller.dart';
import 'repositories/client_repository.dart';
import 'repositories/driver_repository.dart';
import 'repositories/service_order_repository.dart';
import 'screens/role_selection_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/watermark_background.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await Hive.openBox<Map>('clients');
  await Hive.openBox<Map>('orders');
  await Hive.openBox('meta'); // ✅ idioma aqui

  runApp(const WsApp());
}

class WsApp extends StatefulWidget {
  const WsApp({super.key});

  @override
  State<WsApp> createState() => _WsAppState();
}

class _WsAppState extends State<WsApp> {
  late final LocaleController _localeController;

  @override
  void initState() {
    super.initState();
    _localeController = LocaleController();
  }

  @override
  Widget build(BuildContext context) {
    final clientRepo = ClientRepository();
    final driverRepo = DriverRepository();
    final orderRepo = ServiceOrderRepository();

    final firstScreen = WatermarkBackground(
      child: RoleSelectionScreen(
        clientRepo: clientRepo,
        driverRepo: driverRepo,
        orderRepo: orderRepo,
      ),
    );

    return AnimatedBuilder(
      animation: _localeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Waste Collection MVP',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),

          // ✅ i18n
          locale: _localeController.locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: const [
            AppStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (deviceLocale, supported) {
            if (_localeController.locale != null) return _localeController.locale;
            if (deviceLocale == null) return const Locale('en');
            for (final s in supported) {
              if (s.languageCode == deviceLocale.languageCode) return s;
            }
            return const Locale('en');
          },

          // ✅ injeta controller no app inteiro
          builder: (context, child) => LocaleScope(
            controller: _localeController,
            child: child ?? const SizedBox.shrink(),
          ),

          home: SplashScreen(
            next: firstScreen,
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }
}