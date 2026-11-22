import 'package:flutter/foundation.dart';

import '../models/shopping_item.dart';
import '../repositories/shopping_repository.dart';

/// Toda la lógica de negocio de la lista. Las pantallas leen este provider
/// y llaman sus métodos; nunca hablan con el repositorio directamente.
class ShoppingProvider extends ChangeNotifier {
  final ShoppingRepository _repository;

  ShoppingProvider(this._repository);

  List<ShoppingItem> _items = [];
  bool _isLoading = false;
  String? _loadError;

  /// Ids con una operación en curso (para deshabilitar su fila).
  final Set<int> _busyIds = {};

  // --- Lectura ---

  bool get isLoading => _isLoading;

  /// Error de la última carga completa de la lista (pantalla de error).
  String? get loadError => _loadError;

  /// Pendientes primero; dentro de cada grupo, por nombre.
  List<ShoppingItem> get items {
    final sorted = [..._items];
    sorted.sort((a, b) {
      if (a.purchased != b.purchased) return a.purchased ? 1 : -1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return List.unmodifiable(sorted);
  }

  int get totalCount => _items.length;
  int get purchasedCount => _items.where((i) => i.purchased).length;
  int get pendingCount => totalCount - purchasedCount;

  bool isBusy(int? id) => id != null && _busyIds.contains(id);

  // --- Acciones ---
  // Las acciones devuelven null si todo salió bien, o un mensaje de error
  // para que la pantalla lo muestre (ej. en un SnackBar).

  Future<void> loadItems() async {
    _isLoading = true;
    _loadError = null;
    notifyListeners();
    try {
      _items = await _repository.getItems();
    } catch (e) {
      _loadError = _message(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addItem({
    required String name,
    required double quantity,
    required String unit,
  }) async {
    final validation = _validate(name, quantity, unit);
    if (validation != null) return validation;
    try {
      final created = await _repository.createItem(ShoppingItem(
        name: name.trim(),
        quantity: quantity,
        unit: unit.trim(),
      ));
      _items = [..._items, created];
      notifyListeners();
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> editItem(ShoppingItem item) async {
    final validation = _validate(item.name, item.quantity, item.unit);
    if (validation != null) return validation;
    return _runOnItem(item.id, () async {
      final updated = await _repository.updateItem(item.copyWith(
        name: item.name.trim(),
        unit: item.unit.trim(),
      ));
      _replace(updated);
    });
  }

  Future<String?> togglePurchased(ShoppingItem item) {
    return _runOnItem(item.id, () async {
      final updated = await _repository
          .updateItem(item.copyWith(purchased: !item.purchased));
      _replace(updated);
    });
  }

  Future<String?> deleteItem(ShoppingItem item) {
    return _runOnItem(item.id, () async {
      await _repository.deleteItem(item.id!);
      _items = _items.where((i) => i.id != item.id).toList();
    });
  }

  // --- Internos ---

  Future<String?> _runOnItem(int? id, Future<void> Function() action) async {
    if (id == null) return 'El producto no tiene id.';
    if (_busyIds.contains(id)) return null; // ya hay una operación en curso
    _busyIds.add(id);
    notifyListeners();
    try {
      await action();
      return null;
    } catch (e) {
      return _message(e);
    } finally {
      _busyIds.remove(id);
      notifyListeners();
    }
  }

  void _replace(ShoppingItem updated) {
    _items = [
      for (final i in _items) i.id == updated.id ? updated : i,
    ];
  }

  // Límites de las columnas en backend/schema.sql.
  static const maxNameLength = 120; // VARCHAR(120)
  static const maxUnitLength = 30; // VARCHAR(30)
  static const maxQuantity = 99999999.99; // DECIMAL(10,2)

  /// Valida una cantidad contra DECIMAL(10,2). La usa también el formulario.
  static String? validateQuantity(double? quantity) {
    if (quantity == null) return 'Número inválido.';
    if (quantity <= 0) return 'La cantidad debe ser mayor que 0.';
    if (quantity > maxQuantity) return 'La cantidad es demasiado grande.';
    final cents = quantity * 100;
    if ((cents - cents.round()).abs() > 1e-6) return 'Máximo 2 decimales.';
    return null;
  }

  String? _validate(String name, double quantity, String unit) {
    if (name.trim().isEmpty) return 'El nombre es obligatorio.';
    if (name.trim().length > maxNameLength) {
      return 'El nombre es demasiado largo.';
    }
    if (unit.trim().length > maxUnitLength) {
      return 'La unidad es demasiado larga.';
    }
    return validateQuantity(quantity);
  }

  String _message(Object e) =>
      e is RepositoryException ? e.message : 'Error inesperado: $e';
}
