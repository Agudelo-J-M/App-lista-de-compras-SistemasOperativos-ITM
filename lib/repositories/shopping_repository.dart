import '../models/shopping_item.dart';

/// Contrato de acceso a datos. El Provider solo conoce esta interfaz,
/// así que se puede cambiar entre API real y datos de prueba sin tocar la UI.
abstract class ShoppingRepository {
  Future<List<ShoppingItem>> getItems();
  Future<ShoppingItem> getItem(int id);
  Future<ShoppingItem> createItem(ShoppingItem item);
  Future<ShoppingItem> updateItem(ShoppingItem item);
  Future<void> deleteItem(int id);
}

/// Error de acceso a datos con un mensaje apto para mostrar al usuario.
class RepositoryException implements Exception {
  final String message;
  final int? statusCode;

  const RepositoryException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
