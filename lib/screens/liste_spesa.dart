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
        appBar: AppBar(
          title: const Text('Liste della Spesa', style: TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            indicatorColor: Colors.green,
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            tabs: [Tab(icon: Icon(Icons.calendar_month), text: 'Settimanale'), Tab(icon: Icon(Icons.star), text: 'Straordinaria')],
          ),
        ),
        body: const TabBarView(
          children: [
            ShoppingListTab(status: ProductStatus.in_lista_settimanale),
            ShoppingListTab(status: ProductStatus.in_lista_straordinaria),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.read<PantryProvider>().moveCheckedToPantry();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Prodotti spuntati spostati in Dispensa! 📦'), backgroundColor: Colors.green),
            );
          },
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.move_to_inbox),
          label: const Text("Svuota nel Frigo"),
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
    final stream = status == ProductStatus.in_lista_settimanale ? provider.listaSettimanale : provider.listaStraordinaria;

    return StreamBuilder<List<Product>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Lista vuota. 🎉", style: TextStyle(color: Colors.grey, fontSize: 18)));

        final lista = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80, top: 10),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final product = lista[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              elevation: product.isChecked ? 0 : 2,
              color: product.isChecked ? Colors.grey[200] : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: CheckboxListTile(
                activeColor: Colors.green,
                value: product.isChecked,
                onChanged: (val) {
                  if (val != null) provider.toggleCheck(product.id, product.isChecked);
                },
                title: Text(
                    product.nome,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: product.isChecked ? TextDecoration.lineThrough : null,
                        color: product.isChecked ? Colors.grey : Colors.black
                    )
                ),
                subtitle: Text("Da comprare: ${product.quantita}"),
                secondary: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => provider.deleteProduct(product.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}