import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/shopping_provider.dart';
import 'repositories/api_shopping_repository.dart';
import 'repositories/mock_shopping_repository.dart';
import 'repositories/shopping_repository.dart';
import 'screens/shopping_list_screen.dart';
import 'utils/constants.dart';

void main() {
  // La bandera kUseMockData (utils/constants.dart) decide qué repositorio
  // se inyecta. El resto de la app no sabe cuál está usando.
  final ShoppingRepository repository = kUseMockData
      ? MockShoppingRepository()
      : ApiShoppingRepository(baseUrl: kApiBaseUrl);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ShoppingProvider(repository)..loadItems(),
      child: const ListaComprasApp(),
    ),
  );
}

class ListaComprasApp extends StatelessWidget {
  const ListaComprasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de compras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.green,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const ShoppingListScreen(),
    );
  }
}
