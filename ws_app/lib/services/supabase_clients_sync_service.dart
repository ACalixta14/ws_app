import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/client.dart';
import '../repositories/client_repository.dart';
import 'supabase_client_maps.dart';

class SupabaseClientsSyncService {
  final ClientRepository clientRepo;

  SupabaseClientsSyncService({required this.clientRepo});

  SupabaseClient get _sb => Supabase.instance.client;
  Box get _meta => Hive.box('meta');

  DateTime _getLastSyncAt() {
    final raw = _meta.get('clients_last_sync_at');
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> _setLastSyncAt(DateTime dt) async {
    await _meta.put('clients_last_sync_at', dt.toUtc().toIso8601String());
  }

  Future<void> trySync() async {
    try {
      await sync();
    } catch (_) {
      // MVP: se estiver sem net / erro, não trava o app
    }
  }

  Future<void> sync() async {
    final lastSyncAt = _getLastSyncAt();
    final now = DateTime.now().toUtc();

    // 1) PUSH local -> server (clientes alterados após lastSyncAt)
    final localChanged = clientRepo
        .getAll()
        .where((c) => c.updatedAt.toUtc().isAfter(lastSyncAt))
        .toList();

    if (localChanged.isNotEmpty) {
      final rows = localChanged.map(SupabaseClientMaps.clientToRow).toList();

      // Recomendado: RPC LWW no Supabase (upsert_clients_lww)
      await _sb.rpc('upsert_clients_lww', params: {
        'rows': jsonDecode(jsonEncode(rows)),
      });
    }

    // 2) PULL server -> local (clientes atualizados após lastSyncAt)
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
        // ClientRepository.add já funciona como UPSERT (Hive put)
        await clientRepo.add(incoming);
      }
    }

    await _setLastSyncAt(now);
  }
}