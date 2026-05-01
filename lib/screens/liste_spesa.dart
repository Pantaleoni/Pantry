import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';

class ListeSpesaScreen extends StatelessWidget {
  const ListeSpesaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Liste della Spesa', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(icon: Icon(Icons.calendar_month), text: 'Settimanale'),
              Tab(icon: Icon(Icons.star), text: 'Straordinaria'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ShoppingListTab(status: ProductStatus.in_lista_settimanale),
            ShoppingListTab(status: ProductStatus.in_lista_straordinaria),
          ],
        ),
      ),
    );
  }
}

class ShoppingListTab extends StatelessWidget {
  final ProductStatus status;
  const ShoppingListTab({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PantryProvider>();
    final stream = status == ProductStatus.in_lista_settimanale
        ? provider.listaSettimanale
        : provider.listaStraordinaria;

    return StreamBuilder<List<Product>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
              child: Text("Lista vuota. 🎉", style: TextStyle(color: Colors.grey, fontSize: 18))
          );
        }

        // 1. RAGGRUPPAMENTO PER CATEGORIE (Come in dispensa)
        final Map<String, List<Product>> groupedItems = {
          'Frigo': [],
          'Freezer': [],
          'Dispensa': [],
          'Altro': [],
        };

        for (var p in items) {
          final cat = groupedItems.containsKey(p.categoria) ? p.categoria : 'Altro';
          groupedItems[cat]!.add(p);
        }

        // 2. ORDINE ALFABETICO
        for (var list in groupedItems.values) {
          list.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        }

        List<Widget> listWidgets = [];
        for (var entry in groupedItems.entries) {
          if (entry.value.isEmpty) continue;

          listWidgets.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)
                ),
              )
          );

          for (var p in entry.value) {
            listWidgets.add(_buildShoppingCard(context, p, provider));
          }
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 100, top: 8),
          children: listWidgets,
        );
      },
    );
  }

  Widget _buildShoppingCard(BuildContext context, Product p, PantryProvider provider) {
    // Determiniamo la lista "opposta" per il tasto sposta
    final String targetLabel = status == ProductStatus.in_lista_settimanale ? "Straordinaria" : "Settimanale";
    final ProductStatus targetStatus = status == ProductStatus.in_lista_settimanale
        ? ProductStatus.in_lista_straordinaria
        : ProductStatus.in_lista_settimanale;

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.settings, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Gestisci "${p.nome}"'),
              actionsOverflowDirection: VerticalDirection.down,
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                TextButton(
                    onPressed: () {
                      provider.deleteProduct(p.id);
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Elimina', style: TextStyle(color: Colors.red))
                ),
                FilledButton.tonal(
                    onPressed: () {
                      provider.updateProductStatus(p.id, ProductStatus.in_dispensa);
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Sposta in Dispensa')
                ),
                FilledButton.tonal(
                    onPressed: () {
                      provider.updateProductStatus(p.id, targetStatus);
                      Navigator.pop(ctx, true);
                    },
                    child: Text('Sposta in $targetLabel')
                ),
              ],
            )
        );
      },
      child: Card(
        elevation: p.isChecked ? 0 : 2,
        color: p.isChecked ? Colors.grey[200] : Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

          // SPUNTA A SINISTRA
          leading: Checkbox(
            activeColor: Colors.green,
            value: p.isChecked,
            onChanged: (val) {
              if (val != null) provider.toggleCheck(p.id, p.isChecked);
            },
          ),

          // NOME CON DOPPIO CLICK (con sbarratura se selezionato)
          title: GestureDetector(
            onDoubleTap: () => _editName(context, p, provider),
            child: Text(
                p.nome,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: p.isChecked ? TextDecoration.lineThrough : null,
                    color: p.isChecked ? Colors.grey : Colors.black87
                )
            ),
          ),

          // CONTROLLI QUANTITÀ (Uguali alla dispensa)
          trailing: Container(
            decoration: BoxDecoration(color: p.isChecked ? Colors.grey[300] : Colors.grey[100], borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.quantita > 1)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove, color: Colors.redAccent, size: 20),
                    onPressed: () => provider.updateQuantity(p.id, p.quantita - 1),
                  )
                else
                  const SizedBox(width: 40),

                Text('${p.quantita}', style: const TextStyle(fontWeight: FontWeight.bold)),

                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.add, color: Colors.green, size: 20),
                  onPressed: () => provider.updateQuantity(p.id, p.quantita + 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, Product p, PantryProvider provider) async {
    String newName = p.nome;
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rinomina prodotto'),
          content: TextFormField(
            initialValue: p.nome,
            onChanged: (val) => newName = val,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            TextButton(onPressed: () {
              if (newName.trim().isNotEmpty) {
                provider.updateProductName(p.id, newName.trim());
              }
              Navigator.pop(ctx);
            }, child: const Text('Salva')),
          ],
        )
    );
  }
}