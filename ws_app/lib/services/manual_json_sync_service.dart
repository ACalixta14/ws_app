import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/client.dart';
import '../models/service_order.dart';
import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';

class JsonSyncImportResult {
  final int clientsImported;
  final int ordersImported;
  final int ordersSkippedOlder;

  const JsonSyncImportResult({
    required this.clientsImported,
    required this.ordersImported,
    required this.ordersSkippedOlder,
  });
}

class ManualJsonSyncService {
  static const int schemaVersion = 1;

  /// Exporta clients + orders em um único arquivo JSON e compartilha via share_plus.
  static Future<File> exportToTempFile({
    required ClientRepository clientRepo,
    required ServiceOrderRepository orderRepo,
  }) async {
    final clients = clientRepo.getAll();
    final orders = orderRepo.getAll();

    final payload = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'clients': clients.map((c) => c.toMap()).toList(),
      'orders': orders.map((o) => o.toMap()).toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);

    final dir = await getTemporaryDirectory();
    final fileName =
        'waste_sync_v${schemaVersion}_${DateTime.now().toIso8601String().replaceAll(':', '-')}.json';
    final file = File('${dir.path}/$fileName');

    await file.writeAsString(jsonStr, flush: true);
    return file;
  }

  static Future<void> shareExportedFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Waste Collection Sync JSON (v$schemaVersion)',
    );
  }

  /// UI helper: exporta e já abre o share sheet.
  static Future<void> exportAndShare({
    required ClientRepository clientRepo,
    required ServiceOrderRepository orderRepo,
  }) async {
    final file = await exportToTempFile(
      clientRepo: clientRepo,
      orderRepo: orderRepo,
    );
    await shareExportedFile(file);
  }

  /// Importa um .json escolhido pelo usuário e faz merge no Hive:
  /// - Clients: upsert por id (usa add como upsert)
  /// - Orders:
  ///    - se não existe -> insert
  ///    - se existe -> mantém o mais novo comparando updatedAt
  static Future<JsonSyncImportResult> importFromPickerAndMerge({
    required ClientRepository clientRepo,
    required ServiceOrderRepository orderRepo,
  }) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) {
      return const JsonSyncImportResult(
        clientsImported: 0,
        ordersImported: 0,
        ordersSkippedOlder: 0,
      );
    }

    final file = picked.files.first;

    String jsonStr;
    if (file.bytes != null) {
      jsonStr = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      jsonStr = await File(file.path!).readAsString();
    } else {
      throw Exception('Unable to read selected file.');
    }

    final decoded = jsonDecode(jsonStr);

    if (decoded is! Map) {
      throw Exception('Invalid JSON: root is not an object.');
    }

    final version = decoded['schemaVersion'];
    if (version != schemaVersion) {
      throw Exception('Unsupported schemaVersion: $version (expected $schemaVersion).');
    }

    final clientsRaw = decoded['clients'];
    final ordersRaw = decoded['orders'];

    if (clientsRaw is! List) throw Exception('Invalid JSON: "clients" is not a list.');
    if (ordersRaw is! List) throw Exception('Invalid JSON: "orders" is not a list.');

    // -------- Clients: upsert por id --------
    int clientsImported = 0;
    for (final item in clientsRaw) {
      if (item is! Map) continue;
      final c = Client.fromMap(item);

      // Usamos add como upsert (padrão do seu app: add() já persiste por id)
      await clientRepo.add(c);
      clientsImported++;
    }

    // -------- Orders: merge por updatedAt --------
    int ordersImported = 0;
    int ordersSkippedOlder = 0;

    for (final item in ordersRaw) {
      if (item is! Map) continue;
      final incoming = ServiceOrder.fromMap(item);

      final existing = orderRepo.getById(incoming.id);

      if (existing == null) {
        await orderRepo.upsert(incoming);
        ordersImported++;
        continue;
      }

      // keep newest by updatedAt
      if (incoming.updatedAt.isAfter(existing.updatedAt)) {
        await orderRepo.upsert(incoming);
        ordersImported++;
      } else {
        ordersSkippedOlder++;
      }
    }

    return JsonSyncImportResult(
      clientsImported: clientsImported,
      ordersImported: ordersImported,
      ordersSkippedOlder: ordersSkippedOlder,
    );
  }
}
