import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:lista_compras/main.dart';
import 'package:lista_compras/providers/shopping_provider.dart';
import 'package:lista_compras/repositories/mock_shopping_repository.dart';

void main() {
  testWidgets('Muestra los items de prueba', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) =>
            ShoppingProvider(MockShoppingRepository(latency: Duration.zero))
              ..loadItems(),
        child: const ListaComprasApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lista de compras'), findsOneWidget);
    expect(find.text('Leche'), findsOneWidget);
  });

  test('Agregar valida nombre vacío', () async {
    final provider =
        ShoppingProvider(MockShoppingRepository(latency: Duration.zero));
    await provider.loadItems();
    final before = provider.totalCount;

    expect(await provider.addItem(name: '  ', quantity: 1, unit: ''),
        isNotNull);
    expect(await provider.addItem(name: 'Queso', quantity: 1, unit: 'kg'),
        isNull);
    expect(provider.totalCount, before + 1);
  });

  test('Cantidad respeta DECIMAL(10,2)', () {
    expect(ShoppingProvider.validateQuantity(1.15), isNull);
    expect(ShoppingProvider.validateQuantity(0.01), isNull);
    expect(ShoppingProvider.validateQuantity(1.555), isNotNull);
    expect(ShoppingProvider.validateQuantity(0), isNotNull);
    expect(ShoppingProvider.validateQuantity(100000000), isNotNull);
    expect(ShoppingProvider.validateQuantity(null), isNotNull);
  });
}
