import 'package:flutter_test/flutter_test.dart';

import 'package:lista_compras/models/shopping_item.dart';

void main() {
  test('fromJson lee el formato de la API (DECIMAL como texto)', () {
    final item = ShoppingItem.fromJson({
      'id': 3,
      'nombre': 'Arroz',
      'cantidad': '1.50',
      'unidad': 'kg',
      'estado': 'comprado',
    });
    expect(item.id, 3);
    expect(item.name, 'Arroz');
    expect(item.quantity, 1.5);
    expect(item.unit, 'kg');
    expect(item.purchased, isTrue);
  });

  test('toJson produce el body que espera la API', () {
    const item =
        ShoppingItem(id: 1, name: 'Leche', quantity: 2, unit: 'litros');
    expect(item.toJson(), {
      'nombre': 'Leche',
      'cantidad': 2,
      'unidad': 'litros',
      'estado': 'pendiente',
    });
  });
}
