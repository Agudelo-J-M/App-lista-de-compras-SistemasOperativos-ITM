import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shopping_item.dart';
import '../providers/shopping_provider.dart';
import '../utils/constants.dart';
import 'item_form_screen.dart';

class ShoppingListScreen extends StatelessWidget {
  const ShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoppingProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lista de compras'),
            Text(
              '${provider.pendingCount} pendientes · '
              '${provider.purchasedCount} comprados'
              '${kUseMockData ? ' · DEMO' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoading ? null : () => _refresh(context),
          ),
        ],
      ),
      body: _buildBody(context, provider),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ShoppingProvider provider) {
    if (provider.isLoading && provider.totalCount == 0) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.loadError != null && provider.totalCount == 0) {
      return _Message(
        icon: Icons.cloud_off,
        // Se muestra la URL para poder diagnosticar en vivo durante la demo.
        text: '${provider.loadError!}\n\n$kApiBaseUrl',
        action: FilledButton.icon(
          onPressed: provider.loadItems,
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      );
    }

    final items = provider.items;
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _Message(
                  icon: Icons.shopping_cart_outlined,
                  text: 'La lista está vacía.\nToca "Agregar" para empezar.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _ItemTile(item: items[i]),
            ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ShoppingItem item;

  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ShoppingProvider>();
    final busy = context.select<ShoppingProvider, bool>((p) => p.isBusy(item.id));
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(item.id),
      direction: busy ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmAndDelete(context, provider),
      child: ListTile(
        enabled: !busy,
        leading: busy
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Checkbox(
                value: item.purchased,
                onChanged: (_) =>
                    _showResult(context, provider.togglePurchased(item)),
              ),
        title: Text(
          item.name,
          style: item.purchased
              ? TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: theme.disabledColor,
                )
              : null,
        ),
        subtitle: Text('${item.quantityLabel} ${item.unit}'.trim()),
        trailing: IconButton(
          tooltip: 'Eliminar',
          icon: const Icon(Icons.delete_outline),
          onPressed: busy ? null : () => _confirmAndDelete(context, provider),
        ),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ItemFormScreen(item: item),
        )),
      ),
    );
  }

  /// Devuelve true solo si se confirmó y se eliminó en el backend,
  /// para que el Dismissible no quite la fila si el borrado falla.
  Future<bool> _confirmAndDelete(
      BuildContext context, ShoppingProvider provider) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "${item.name}" de la lista?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return false;
    final messenger = ScaffoldMessenger.of(context);
    final error = await provider.deleteItem(item);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? '"${item.name}" eliminado.'),
    ));
    // La fila ya desaparece por notifyListeners; devolver false evita que
    // Dismissible intente quitarla una segunda vez.
    return false;
  }

  void _showResult(BuildContext context, Future<String?> action) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await action;
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
    }
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final Widget? action;

  const _Message({required this.icon, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).disabledColor),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

/// Recarga la lista. Si falla y ya hay productos en pantalla, la lista se
/// mantiene y el error se avisa con un SnackBar (si la lista está vacía, el
/// error ya se ve en la pantalla completa).
Future<void> _refresh(BuildContext context) async {
  final provider = context.read<ShoppingProvider>();
  final messenger = ScaffoldMessenger.of(context);
  await provider.loadItems();
  final error = provider.loadError;
  if (error != null && provider.totalCount > 0) {
    messenger.showSnackBar(SnackBar(content: Text(error)));
  }
}

void _openForm(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => const ItemFormScreen(),
  ));
}
