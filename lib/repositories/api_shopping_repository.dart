import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/shopping_item.dart';
import '../utils/constants.dart';
import 'shopping_repository.dart';

/// Implementación real: habla con la API REST de la VM.
class ApiShoppingRepository implements ShoppingRepository {
  final String baseUrl;
  final http.Client _client;

  ApiShoppingRepository({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<List<ShoppingItem>> getItems() async {
    final res = await _send(() => _client.get(_uri('/productos')));
    _expect(res, const [200]);
    final data = _decode(res);
    if (data is! List) {
      throw const RepositoryException('Respuesta inesperada del servidor.');
    }
    return data
        .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ShoppingItem> getItem(int id) async {
    final res = await _send(() => _client.get(_uri('/productos/$id')));
    _expect(res, const [200]);
    return ShoppingItem.fromJson(_decode(res) as Map<String, dynamic>);
  }

  @override
  Future<ShoppingItem> createItem(ShoppingItem item) async {
    final res = await _send(() => _client.post(
          _uri('/productos'),
          headers: _jsonHeaders,
          body: jsonEncode(item.toJson()),
        ));
    _expect(res, const [200, 201]);
    return ShoppingItem.fromJson(_decode(res) as Map<String, dynamic>);
  }

  @override
  Future<ShoppingItem> updateItem(ShoppingItem item) async {
    if (item.id == null) {
      throw const RepositoryException('No se puede actualizar un producto sin id.');
    }
    final res = await _send(() => _client.put(
          _uri('/productos/${item.id}'),
          headers: _jsonHeaders,
          body: jsonEncode(item.toJson()),
        ));
    _expect(res, const [200]);
    return ShoppingItem.fromJson(_decode(res) as Map<String, dynamic>);
  }

  @override
  Future<void> deleteItem(int id) async {
    final res = await _send(() => _client.delete(_uri('/productos/$id')));
    _expect(res, const [200, 204]);
  }

  // --- Helpers ---

  /// Ejecuta la petición traduciendo fallos de red a mensajes claros.
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(kRequestTimeout);
    } on TimeoutException {
      throw const RepositoryException(
          'El servidor no respondió a tiempo. ¿Está encendida la VM?');
    } on SocketException {
      throw const RepositoryException(
          'No se pudo conectar con el servidor. Revisa la IP y el puerto en constants.dart.');
    } on http.ClientException catch (e) {
      throw RepositoryException('Error de conexión: ${e.message}');
    }
  }

  void _expect(http.Response res, List<int> okCodes) {
    if (okCodes.contains(res.statusCode)) return;
    String message = 'Error del servidor (${res.statusCode}).';
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map && body['error'] != null) {
        message = body['error'].toString();
      }
    } catch (_) {
      // Cuerpo vacío o no-JSON: se usa el mensaje genérico.
    }
    throw RepositoryException(message, statusCode: res.statusCode);
  }

  dynamic _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw const RepositoryException('El servidor devolvió un JSON inválido.');
    }
  }
}
