import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class LocaleController extends ChangeNotifier {
  Locale? _locale;
  Locale? get locale => _locale;

  LocaleController() {
    final meta = Hive.box('meta');
    final code = meta.get('locale') as String?;
    if (code == 'pt' || code == 'en') _locale = Locale(code!);
  }

  Future<void> setLocale(Locale locale) async {
    final code = locale.languageCode;
    if (code != 'pt' && code != 'en') return;
    _locale = Locale(code);
    await Hive.box('meta').put('locale', code);
    notifyListeners();
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found in widget tree');
    return scope!.notifier!;
  }
}