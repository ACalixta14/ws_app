import 'package:hive_ce_flutter/hive_flutter.dart';

import '../models/client.dart';

class ClientRepository {
  Box<Map> get _box => Hive.box<Map>('clients');

  List<Client> getAll() {
    return _box.values.map((m) => Client.fromMap(m)).toList();
  }

  Future<void> add(Client client) async {
    await _box.put(client.id, client.toMap());
  }

  Client? getById(String id) {
    final data = _box.get(id);
    if (data == null) return null;
    return Client.fromMap(data);
  }

Future<void> delete (String id) async{
  await _box.delete(id);
}
Future<void> clear() async {
  await _box.clear();
}
}