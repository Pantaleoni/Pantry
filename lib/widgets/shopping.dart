import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/pantry.dart';

class ShoppingListTab extends StatelessWidget {
  final ProductStatus status;
  const ShoppingListTab({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final lista = status == ProductStatus.in_lista_settimanale ? provider.listaSettimanale : provider.listaStraordinaria;

    if (lista.isEmpty) return const Center(child: Text("Lista vuota."));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final product = lista[index];
        return CheckboxListTile(
          value: product.isChecked,
          onChanged: (val) => provider.toggleCheck(product),
          title: Text(product.nome, style: TextStyle(decoration: product.isChecked ? TextDecoration.lineThrough : null, color: product.isChecked ? Colors.grey : Colors.black)),
          subtitle: Text("Da comprare: ${product.quantita}"),
        );
      },
    );
  }
}