import 'dart:convert';
import 'dart:developer' as developer;

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client.dart';
import '../repositories/client_repository.dart';
import 'supabase_client_maps.dart';

//classe que sincroniza e utiliza o Supabase para passar informações do clients 
class SupabaseClientsSyncService {

//recebe o repositório e guarda em uma variável imutavel (final)
  final ClientRepository clientRepo;

//construtor cria um novo objeto (obriga passar por um repositório)
//===serviço de sync, aqui está o meu repositório local de clientes, use isso para ler e gravar dados=====//
  SupabaseClientsSyncService({required this.clientRepo});


  SupabaseClient get _sb => Supabase.instance.client;
  Box get _meta => Hive.box('meta');

  DateTime _getLastSyncAt() {
    final raw = _meta.get('clients_last_sync_at');
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> _setLastSyncAt(DateTime dt) async {
    await _meta.put('clients_last_sync_at', dt.toUtc().toIso8601String());
  }

  Future<void> trySync() async {
    try {
      await sync();
    } catch (e, s) {
      developer.log(
        'SupabaseClientsSyncService.trySync falhou',
        error: e,
        stackTrace: s,
      );
    }
  }

  Future<void> sync() async {

    print('SYNC CLIENTS SRTART');
    final lastSyncAt = _getLastSyncAt();
    final now = DateTime.now().toUtc();

    final localChanged = clientRepo
        .getAll()
        .where((c) => c.updatedAt.toUtc().isAfter(lastSyncAt))
        .toList();

print('LOCAL CLIENTS CHANGED: ${localChanged.length}');
print('PUSHING CLIENTS TO SUPABASE');
    if (localChanged.isNotEmpty) {
      final rows = localChanged.map(SupabaseClientMaps.clientToRow).toList();

      try {
        await _sb.rpc(
          'upsert_clients_lww',
          params: {'rows': jsonDecode(jsonEncode(rows))},
        );
      } catch (_) {
        await _sb.from('clients').upsert(rows);
      }
    }

print('PUSHING CLIENTS FROM SUPABASE');
    final remote = await _sb
        .from('clients')
        .select()
        .gt('updated_at', lastSyncAt.toIso8601String())
        .order('updated_at', ascending: true);

    for (final r in remote) {
      final row = (r as Map);
      final mapped = SupabaseClientMaps.rowToClientMap(row);
      final incoming = Client.fromMap(mapped);

      final existing = clientRepo.getById(incoming.id);
      if (existing == null || incoming.updatedAt.isAfter(existing.updatedAt)) {
        await clientRepo.add(incoming);
      }
    }

    await _setLastSyncAt(now);
  }
}