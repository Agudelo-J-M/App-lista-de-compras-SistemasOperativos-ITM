import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shopping_item.dart';
import '../providers/shopping_provider.dart';

/// Formulario para crear (item == null) o editar un producto.
class ItemFormScreen extends StatefulWidget {
  final ShoppingItem? item;

  const ItemFormScreen({super.key, this.item});

  bool get isEditing => item != null;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late bool _purchased;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _quantity = TextEditingController(text: item?.quantityLabel ?? '1');
    _unit = TextEditingController(text: item?.unit ?? '');
    _purchased = item?.purchased ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  double? _parseQuantity(String s) =>
      double.tryParse(s.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final provider = context.read<ShoppingProvider>();
    final quantity = _parseQuantity(_quantity.text)!;
    final error = widget.isEditing
        ? await provider.editItem(widget.item!.copyWith(
            name: _name.text,
            quantity: quantity,
            unit: _unit.text,
            purchased: _purchased,
          ))
        : await provider.addItem(
            name: _name.text,
            quantity: quantity,
            unit: _unit.text,
          );

    if (!mounted) return;
    setState(() => _saving = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar producto' : 'Nuevo producto'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              autofocus: !widget.isEditing,
              enabled: !_saving,
              maxLength: ShoppingProvider.maxNameLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                hintText: 'Ej. Leche',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'El nombre es obligatorio'
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    enabled: !_saving,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => ShoppingProvider.validateQuantity(
                        _parseQuantity(v ?? '')),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _unit,
                    enabled: !_saving,
                    maxLength: ShoppingProvider.maxUnitLength,
                    decoration: const InputDecoration(
                      labelText: 'Unidad',
                      hintText: 'Ej. litros, kg, unidades',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.isEditing) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Comprado'),
                value: _purchased,
                onChanged:
                    _saving ? null : (v) => setState(() => _purchased = v),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(widget.isEditing ? 'Guardar cambios' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}
