import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  static const supportedLocales = [
    Locale('en'),
    Locale('pt'),
  ];

  static AppStrings of(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings)!;
  }

  static const LocalizationsDelegate<AppStrings> delegate = _AppStringsDelegate();

  static const _localized = {
    'en': {
      // ===== RoleSelection =====
      'appTitle': 'WS_app',
      'chooseHow': 'Choose how you want to use the app',
      'howItWorks': 'How it works',
      'howItWorksDesc':
          'Admin manages clients and orders.\nDriver selects their name and sees Today/Tomorrow plan.',
      'continueAdmin': 'Continue as Admin',
      'continueAdminDesc': 'Clients, orders, planning and sync',
      'continueDriver': 'Continue as Driver',
      'continueDriverDesc': 'Select your name and view the plan',

      // ===== DriverHome =====
      'selectDriverTitle': 'Select Driver',
      'selectDriverSubtitle': 'Choose your name to view the plan',
      'chooseYourName': 'Choose your name',
      'noDriversTitle': 'No drivers registered',
      'noDriversDesc': 'Register drivers so they can access the plan',

      // ===== Common =====
      'ok': 'OK',
      'cancel': 'Cancel',
      'clear': 'Clear',

      // ===== AdminHome =====
      'adminTitle': 'Admin',
      'adminSubtitle': 'Clients, orders, planning and sync',

      'clients': 'Clients',
      'manageClients': 'Manage clients',

      'createOrder': 'Create Order',
      'newService': 'New service',

      'plan': 'Plan',
      'todayTomorrow': 'Today / Tomorrow',

      'history': 'History',
      'pastOrders': 'Past orders',

      'syncTools': 'Sync & Tools',
      'exportJson': 'Export JSON',
      'importJson': 'Import JSON',
      'clearTestData': 'Clear test data',

      'exportReady': 'Export ready to share',
      'exportFailed': 'Export failed',
      'importFailed': 'Import failed',

      'importSummary': 'Import summary',
      'clientsImported': 'Clients imported',
      'ordersImported': 'Orders imported',
      'ordersSkippedOlder': 'Orders skipped (older)',

      'clearAllTitle': 'Clear all test data?',
      'clearAllDesc': 'This will delete ALL clients and orders.',
      'allDataCleared': 'All data cleared',
    },

    'pt': {
      // ===== RoleSelection =====
      'appTitle': 'WS_app',
      'chooseHow': 'Escolha como deseja usar o app',
      'howItWorks': 'Como funciona',
      'howItWorksDesc':
          'O admin gerencia clientes e ordens.\nO motorista seleciona o nome e vê o plano de Hoje/Amanhã.',
      'continueAdmin': 'Entrar como Admin',
      'continueAdminDesc': 'Clientes, ordens, planejamento e sync',
      'continueDriver': 'Entrar como Motorista',
      'continueDriverDesc': 'Selecione seu nome e veja o plano',

      // ===== DriverHome =====
      'selectDriverTitle': 'Selecionar Motorista',
      'selectDriverSubtitle': 'Escolha seu nome para ver o plano',
      'chooseYourName': 'Escolha seu nome',
      'noDriversTitle': 'Nenhum motorista cadastrado',
      'noDriversDesc': 'Cadastre motoristas para que possam acessar o plano',

      // ===== Common =====
      'ok': 'OK',
      'cancel': 'Cancelar',
      'clear': 'Limpar',

      // ===== AdminHome =====
      'adminTitle': 'Admin',
      'adminSubtitle': 'Clientes, ordens, planejamento e sync',

      'clients': 'Clientes',
      'manageClients': 'Gerir clientes',

      'createOrder': 'Criar ordem',
      'newService': 'Novo serviço',

      'plan': 'Plano',
      'todayTomorrow': 'Hoje / Amanhã',

      'history': 'Histórico',
      'pastOrders': 'Ordens anteriores',

      'syncTools': 'Sincronização & Ferramentas',
      'exportJson': 'Exportar JSON',
      'importJson': 'Importar JSON',
      'clearTestData': 'Limpar dados de teste',

      'exportReady': 'Export pronto para partilhar',
      'exportFailed': 'Falha ao exportar',
      'importFailed': 'Falha ao importar',

      'importSummary': 'Resumo da importação',
      'clientsImported': 'Clientes importados',
      'ordersImported': 'Ordens importadas',
      'ordersSkippedOlder': 'Ordens ignoradas (mais antigas)',

      'clearAllTitle': 'Limpar todos os dados de teste?',
      'clearAllDesc': 'Isto irá apagar TODOS os clientes e ordens.',
      'allDataCleared': 'Todos os dados foram apagados',
    },
  };

  String _t(String key) =>
      _localized[locale.languageCode]?[key] ?? _localized['en']![key]!;

  // ===== RoleSelection =====
  String get appTitle => _t('appTitle');
  String get chooseHow => _t('chooseHow');
  String get howItWorks => _t('howItWorks');
  String get howItWorksDesc => _t('howItWorksDesc');
  String get continueAdmin => _t('continueAdmin');
  String get continueAdminDesc => _t('continueAdminDesc');
  String get continueDriver => _t('continueDriver');
  String get continueDriverDesc => _t('continueDriverDesc');

  // ===== DriverHome =====
  String get selectDriverTitle => _t('selectDriverTitle');
  String get selectDriverSubtitle => _t('selectDriverSubtitle');
  String get chooseYourName => _t('chooseYourName');
  String get noDriversTitle => _t('noDriversTitle');
  String get noDriversDesc => _t('noDriversDesc');

  // ===== Common =====
  String get ok => _t('ok');
  String get cancel => _t('cancel');
  String get clear => _t('clear');

  // ===== AdminHome =====
  String get adminTitle => _t('adminTitle');
  String get adminSubtitle => _t('adminSubtitle');

  String get clients => _t('clients');
  String get manageClients => _t('manageClients');

  String get createOrder => _t('createOrder');
  String get newService => _t('newService');

  String get plan => _t('plan');
  String get todayTomorrow => _t('todayTomorrow');

  String get history => _t('history');
  String get pastOrders => _t('pastOrders');

  String get syncTools => _t('syncTools');
  String get exportJson => _t('exportJson');
  String get importJson => _t('importJson');
  String get clearTestData => _t('clearTestData');

  String get exportReady => _t('exportReady');
  String get exportFailed => _t('exportFailed');
  String get importFailed => _t('importFailed');

  String get importSummary => _t('importSummary');
  String get clientsImported => _t('clientsImported');
  String get ordersImported => _t('ordersImported');
  String get ordersSkippedOlder => _t('ordersSkippedOlder');

  String get clearAllTitle => _t('clearAllTitle');
  String get clearAllDesc => _t('clearAllDesc');
  String get allDataCleared => _t('allDataCleared');
}

class _AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const _AppStringsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'pt'].contains(locale.languageCode);

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate old) => false;
}