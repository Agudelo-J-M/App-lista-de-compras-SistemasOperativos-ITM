/// Un producto de la lista de compras. Refleja una fila de la tabla
/// `productos` y el JSON de la API (ver HANDOFF_BACKEND.md).
class ShoppingItem {
  /// Valores de la columna `estado`.
  static const estadoPendiente = 'pendiente';
  static const estadoComprado = 'comprado';

  final int? id; // null mientras no se ha guardado en el backend
  final String name;
  final double quantity;
  final String unit;
  final bool purchased;

  const ShoppingItem({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.purchased = false,
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: _toInt(json['id']),
      name: (json['nombre'] ?? '').toString(),
      quantity: _toDouble(json['cantidad']),
      unit: (json['unidad'] ?? '').toString(),
      purchased:
          json['estado']?.toString().toLowerCase().trim() == estadoComprado,
    );
  }

  /// Body para POST / PUT: solo los campos que acepta la API (sin `id`).
  Map<String, dynamic> toJson() => {
        'nombre': name,
        // Se envía entero cuando no tiene decimales (ej. 2 en vez de 2.0).
        'cantidad': quantity == quantity.roundToDouble()
            ? quantity.toInt()
            : quantity,
        'unidad': unit,
        'estado': purchased ? estadoComprado : estadoPendiente,
      };

  ShoppingItem copyWith({
    int? id,
    String? name,
    double? quantity,
    String? unit,
    bool? purchased,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchased: purchased ?? this.purchased,
    );
  }

  /// Cantidad legible: "2" en vez de "2.0", "1.5" se queda igual.
  String get quantityLabel => quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();

  // --- Conversiones tolerantes (MySQL devuelve DECIMAL como texto, ej. "2.00") ---

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
