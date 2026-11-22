import '../models/shopping_item.dart';
import 'shopping_repository.dart';

/// Implementación en memoria con datos de prueba. Permite desarrollar y
/// demostrar la app sin backend. Los datos se pierden al cerrar la app.
class MockShoppingRepository implements ShoppingRepository {
  /// Latencia simulada para que se vean los estados de carga.
  final Duration latency;

  MockShoppingRepository({this.latency = const Duration(milliseconds: 400)}) {
    for (final seed in [
      ('Leche', 2.0, 'litros', false),
      ('Pan', 1.0, 'unidad', false),
      ('Huevos', 12.0, 'unidades', true),
      ('Arroz', 1.5, 'kg', false),
      ('Café', 500.0, 'g', true),
    ]) {
      final id = _nextId++;
      _items[id] = ShoppingItem(
        id: id,
        name: seed.$1,
        quantity: seed.$2,
        unit: seed.$3,
        purchased: seed.$4,
      );
    }
  }

  final Map<int, ShoppingItem> _items = {};
  int _nextId = 1;

  Future<void> _delay() => Future.delayed(latency);

  ShoppingItem _find(int id) {
    final item = _items[id];
    if (item == null) {
      throw const RepositoryException('Producto no encontrado.',
          statusCode: 404);
    }
    return item;
  }

  @override
  Future<List<ShoppingItem>> getItems() async {
    await _delay();
    return _items.values.toList();
  }

  @override
  Future<ShoppingItem> getItem(int id) async {
    await _delay();
    return _find(id);
  }

  @override
  Future<ShoppingItem> createItem(ShoppingItem item) async {
    await _delay();
    final id = _nextId++;
    final created = item.copyWith(id: id);
    _items[id] = created;
    return created;
  }

  @override
  Future<ShoppingItem> updateItem(ShoppingItem item) async {
    await _delay();
    _find(item.id ?? -1);
    _items[item.id!] = item;
    return item;
  }

  @override
  Future<void> deleteItem(int id) async {
    await _delay();
    _find(id);
    _items.remove(id);
  }
}
