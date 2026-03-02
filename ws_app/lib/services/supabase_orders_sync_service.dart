import 'dart:convert';

import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/service_order.dart';
import '../repositories/service_order_repository.dart';
import 'supabase_order_maps.dart';

class SupabaseOrdersSyncService {
  final ServiceOrderRepository orderRepo;

  SupabaseOrdersSyncService({required this.orderRepo});

  SupabaseClient get _sb => Supabase.instance.client;
  Box get _meta => Hive.box('meta');

  DateTime _getLastSyncAt() {
    final raw = _meta.get('orders_last_sync_at');
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }

  Future<void> _setLastSyncAt(DateTime dt) async {
    await _meta.put('orders_last_sync_at', dt.toUtc().toIso8601String());
  }

  Future<void> trySync() async {
    try {
      await sync();
    } catch (_) {
      // MVP: ignora erro de rede/RLS/keys e mantém offline funcionando.
    }
  }

  Future<void> sync() async {
    final lastSyncAt = _getLastSyncAt();
    final now = DateTime.now().toUtc();

    // 1) PUSH: local -> server (somente alterados depois do lastSyncAt)
    final localChanged = orderRepo
        .getAll()
        .where((o) => o.updatedAt.toUtc().isAfter(lastSyncAt))
        .toList();

    if (localChanged.isNotEmpty) {
      final rows = localChanged.map(SupabaseOrderMaps.orderToRow).toList();

      // Recomendado: usar RPC LWW (upsert com WHERE excluded.updated_at > existing.updated_at)
      // Se você ainda não criou as funções SQL, troque por .from('service_orders').upsert(rows)
      await _sb.rpc('upsert_service_orders_lww', params: {
        'rows': jsonDecode(jsonEncode(rows)), // garante jsonb
      });
    }

    // 2) PULL: server -> local (somente atualizados depois do lastSyncAt)
    final remote = await _sb
        .from('service_orders')
        .select()
        .gt('updated_at', lastSyncAt.toIso8601String())
        .order('updated_at', ascending: true);

    for (final r in remote) {
      final row = (r as Map);
      final mapped = SupabaseOrderMaps.rowToOrderMap(row);
      final incoming = ServiceOrder.fromMap(mapped);

      final existing = orderRepo.getById(incoming.id);
      if (existing == null || incoming.updatedAt.isAfter(existing.updatedAt)) {
        await orderRepo.upsert(incoming);
      }
    }

    await _setLastSyncAt(now);
  }
}