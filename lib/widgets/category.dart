import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/pantry.dart';

class CategoryList extends StatelessWidget {
  final String title;
  final List<Product> products;

  const CategoryList({super.key, required this.title, required this.products});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      initiallyExpanded: true,
      children: products.map((product) => Dismissible(
        key: Key(product.id),
        direction: DismissDirection.endToStart,
        background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
        onDismissed: (_) => _askToList(context, product),
        child: ListTile(
          leading: Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: product.colorCode)),
          title: Text(product.nome),
          subtitle: Text("Q.tà: ${product.quantita} | ${product.dataScadenza != null ? 'Scade: ${product.dataScadenza!.day}/${product.dataScadenza!.month}' : 'No Scadenza'}"),
        ),
      )).toList(),
    );
  }

  void _askToList(BuildContext context, Product product) {
    showDialog(
      context: context, barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Prodotto Finito'), content: Text('Vuoi aggiungere "${product.nome}" alla lista?'),
        actions: [
          TextButton(onPressed: () { context.read<PantryProvider>().deleteProduct(product.id); Navigator.pop(ctx); }, child: const Text('No, elimina', style: TextStyle(color: Colors.grey))),
          TextButton(
              onPressed: () {
                context.read<PantryProvider>().updateProductStatus(product.id, ProductStatus.in_lista_straordinaria);
                Navigator.pop(ctx);
              },
              child: const Text('Straordinaria')
          ),
          FilledButton(
              onPressed: () {
                context.read<PantryProvider>().updateProductStatus(product.id, ProductStatus.in_lista_settimanale);
                Navigator.pop(ctx);
              },
              child: const Text('Settimanale')
          ),
        ],
      ),
    );
  }
}