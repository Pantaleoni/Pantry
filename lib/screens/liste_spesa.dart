import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';
import '../widgets/scanner.dart'; // <-- Controlla che questo percorso sia giusto!

class ListeSpesaScreen extends StatefulWidget {
  const ListeSpesaScreen({super.key});

  @override
  State<ListeSpesaScreen> createState() => _ListeSpesaScreenState();
}

class _ListeSpesaScreenState extends State<ListeSpesaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Liste della Spesa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month), text: 'Settimanale'),
            Tab(icon: Icon(Icons.star), text: 'Straordinaria'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ShoppingListTab(status: ProductStatus.in_lista_settimanale),
          ShoppingListTab(status: ProductStatus.in_lista_straordinaria),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton(
              heroTag: 'svuota_spesa',
              onPressed: () {
                context.read<PantryProvider>().moveCheckedToPantry();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Prodotti spuntati spostati in Dispensa! 📦'),
                      backgroundColor: Colors.green
                  ),
                );
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              tooltip: 'Svuota in Dispensa',
              child: const Icon(Icons.move_to_inbox),
            ),
            FloatingActionButton(
              heroTag: 'add_spesa',
              onPressed: () {
                final activeStatus = _tabController.index == 0
                    ? ProductStatus.in_lista_settimanale
                    : ProductStatus.in_lista_straordinaria;

                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => ScannerAndFormModal(
                    targetStatus: activeStatus,
                  ),
                );
              },
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              tooltip: 'Aggiungi Prodotto',
              child: const Icon(Icons.add),
            ),
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

        final int totali = items.length;
        final int presi = items.where((p) => p.isChecked).length;
        final int daPrendere = totali - presi;

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

        for (var list in groupedItems.values) {
          list.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        }

        List<Widget> listWidgets = [];

        listWidgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              color: Colors.white,
              elevation: 4,
              shadowColor: Colors.green.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatColumn('Totali', '$totali', Colors.blueGrey),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatColumn('Da prendere', '$daPrendere', Colors.orange),
                    Container(width: 1, height: 40, color: Colors.grey[300]),
                    _buildStatColumn('Presi', '$presi', Colors.green),
                  ],
                ),
              ),
            ),
          ),
        );

        for (var entry in groupedItems.entries) {
          if (entry.value.isEmpty) continue;

          listWidgets.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)
                ),
              )
          );

          for (var p in entry.value) {
            listWidgets.add(_buildShoppingCard(context, p, provider));
          }
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 80, top: 8),
          children: listWidgets,
        );
      },
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildShoppingCard(BuildContext context, Product p, PantryProvider provider) {
    final String targetLabel = status == ProductStatus.in_lista_settimanale ? "Straordinaria" : "Settimanale";
    final ProductStatus targetStatus = status == ProductStatus.in_lista_settimanale
        ? ProductStatus.in_lista_straordinaria
        : ProductStatus.in_lista_settimanale;

    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 16, left: 16),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Gestisci "${p.nome}"'),
              actionsOverflowDirection: VerticalDirection.down,
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla', style: TextStyle(color: Colors.grey))),
                TextButton(
                    onPressed: () {
                      provider.deleteProduct(p.id);
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('Elimina', style: TextStyle(color: Colors.red))
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.only(left: 8.0, right: 0.0),

            leading: Checkbox(
              activeColor: Colors.green,
              value: p.isChecked,
              onChanged: (val) {
                if (val != null) provider.toggleCheck(p.id, p.isChecked);
              },
            ),

            title: GestureDetector(
              onDoubleTap: () => _editName(context, p, provider),
              child: Text(
                  p.nome,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: p.isChecked ? TextDecoration.lineThrough : null,
                      color: p.isChecked ? Colors.grey : Colors.black
                  )
              ),
            ),

            trailing: Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  p.quantita > 1
                      ? IconButton(
                    icon: const Icon(Icons.remove, color: Colors.redAccent),
                    onPressed: () => provider.updateQuantity(p.id, p.quantita - 1),
                  )
                      : const SizedBox(width: 40),

                  Text('${p.quantita}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => provider.updateQuantity(p.id, p.quantita + 1),
                  ),
                ],
              ),
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