// Pruebas del cliente HTTP real (ApiShoppingRepository) SIN necesitar la VM.
//
// `MockClient` simula el servidor: cada endpoint devuelve un JSON fijo.
// Compañero de integración: reemplace los JSON de abajo por las respuestas
// REALES que el compañero de BD/API copió en backend/FICHA_API.md. Si estas
// pruebas pasan con las respuestas reales, la app va a entender la API.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:lista_compras/models/shopping_item.dart';
import 'package:lista_compras/repositories/api_shopping_repository.dart';
import 'package:lista_compras/repositories/shopping_repository.dart';

// ---- Respuestas de la API (pegar aquí las reales de FICHA_API.md) ----

const respuestaListar = '''
[
  {"id": 1, "nombre": "Leche", "cantidad": "2.00", "unidad": "litros", "estado": "pendiente"},
  {"id": 3, "nombre": "Huevos", "cantidad": "12.00", "unidad": "unidades", "estado": "comprado"}
]
''';

const respuestaCrear = '''
{"id": 6, "nombre": "Queso", "cantidad": "1.00", "unidad": "kg", "estado": "pendiente"}
''';

const respuestaActualizar = '''
{"id": 6, "nombre": "Queso", "cantidad": "1.00", "unidad": "kg", "estado": "comprado"}
''';

const respuestaError400 = '''
{"error": "El nombre es obligatorio."}
''';

// ----------------------------------------------------------------------

const baseUrl = 'http://servidor-de-prueba/api';
const jsonUtf8 = {'content-type': 'application/json; charset=utf-8'};

/// Servidor simulado que responde según el contrato de HANDOFF_BACKEND.md.
/// Guarda la última petición para poder revisar qué envió la app.
class ServidorFalso {
  http.Request? ultimaPeticion;

  late final client = MockClient((req) async {
    ultimaPeticion = req;
    final ruta = req.url.path;
    switch ((req.method, ruta)) {
      case ('GET', '/api/productos'):
        return http.Response(respuestaListar, 200, headers: jsonUtf8);
      case ('POST', '/api/productos'):
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        if ((body['nombre'] ?? '').toString().trim().isEmpty) {
          return http.Response(respuestaError400, 400, headers: jsonUtf8);
        }
        return http.Response(respuestaCrear, 201, headers: jsonUtf8);
      case ('PUT', '/api/productos/6'):
        return http.Response(respuestaActualizar, 200, headers: jsonUtf8);
      case ('DELETE', '/api/productos/6'):
        return http.Response('', 204);
      default:
        return http.Response('{"error": "Producto no encontrado."}', 404,
            headers: jsonUtf8);
    }
  });

  ApiShoppingRepository get repo =>
      ApiShoppingRepository(baseUrl: baseUrl, client: client);
}

void main() {
  late ServidorFalso servidor;

  setUp(() => servidor = ServidorFalso());

  test('GET /productos: lee la lista', () async {
    final items = await servidor.repo.getItems();
    expect(items, hasLength(2));
    expect(items.first.name, 'Leche');
    expect(items.first.quantity, 2);
    expect(items[1].purchased, isTrue);
  });

  test('POST /productos: envía el body correcto y lee el creado', () async {
    final creado = await servidor.repo.createItem(
        const ShoppingItem(name: 'Queso', quantity: 1, unit: 'kg'));

    final enviado = jsonDecode(servidor.ultimaPeticion!.body);
    expect(enviado, {
      'nombre': 'Queso',
      'cantidad': 1,
      'unidad': 'kg',
      'estado': 'pendiente',
    });
    expect(creado.id, 6);
  });

  test('PUT /productos/{id}: marca comprado', () async {
    final actualizado = await servidor.repo.updateItem(const ShoppingItem(
        id: 6, name: 'Queso', quantity: 1, unit: 'kg', purchased: true));

    expect(servidor.ultimaPeticion!.method, 'PUT');
    expect(jsonDecode(servidor.ultimaPeticion!.body)['estado'], 'comprado');
    expect(actualizado.purchased, isTrue);
  });

  test('DELETE /productos/{id}: acepta 204', () async {
    await servidor.repo.deleteItem(6);
    expect(servidor.ultimaPeticion!.method, 'DELETE');
  });

  test('Error 400: muestra el mensaje del servidor', () async {
    await expectLater(
      servidor.repo
          .createItem(const ShoppingItem(name: '', quantity: 1, unit: '')),
      throwsA(isA<RepositoryException>()
          .having((e) => e.message, 'message', 'El nombre es obligatorio.')),
    );
  });

  test('Error 404: id inexistente', () async {
    await expectLater(
      servidor.repo.getItem(999),
      throwsA(isA<RepositoryException>()
          .having((e) => e.statusCode, 'statusCode', 404)),
    );
  });
}
