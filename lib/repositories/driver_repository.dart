import '../models/driver.dart';

//incluir aqui novos motoristas
class DriverRepository {
  final List<Driver> _drivers = [
    Driver(id: '1', name: 'Matheus', colorTag: 0xFFFFEB3B), // yellow
    Driver(id: '2', name: 'Vitor', colorTag: 0xFF2196F3), // blue
  ];

  List<Driver> getAll() => List.unmodifiable(_drivers);

  Driver? getById(String id) {
    try {
      return _drivers.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }
}
