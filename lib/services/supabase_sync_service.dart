import '../repositories/client_repository.dart';
import '../repositories/service_order_repository.dart';
import 'supabase_clients_sync_service.dart';
import 'supabase_orders_sync_service.dart';

class SupabaseSyncService {
  final ClientRepository clientRepo;
  final ServiceOrderRepository orderRepo;

  SupabaseSyncService({
    required this.clientRepo,
    required this.orderRepo,
  });

  Future<void> trySyncAll() async {
    try {
      await SupabaseClientsSyncService(clientRepo: clientRepo).sync();
      await SupabaseOrdersSyncService(orderRepo: orderRepo).sync();
    } catch (_) {
      // MVP: não trava
    }
  }
}