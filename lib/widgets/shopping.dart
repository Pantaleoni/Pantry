import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/pantry.dart';

class ShoppingListTab extends StatelessWidget {
  final ProductStatus status;
  const ShoppingListTab({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // 1. Scegliamo lo Stream corretto in base allo stato
    final provider = context.read<PantryProvider>();
    final stream = status == ProductStatus.in_lista_settimanale
        ? provider.listaSettimanale
        : provider.listaStraordinaria;

    // 2. Avvolgiamo tutto nello StreamBuilder per il tempo reale
    return StreamBuilder<List<Product>>(
      stream: stream,
      builder: (context, snapshot) {

        // 3. Mostriamo la rotellina mentre Firebase carica i dati
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 4. Il controllo sicuro di Null Safety!
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Lista vuota."));
        }

        // Ora possiamo estrarre la lista in totale sicurezza
        final lista = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final product = lista[index];

            return CheckboxListTile(
              value: product.isChecked,
              // 5. Corretta la chiamata passando l'ID e lo stato attuale
              onChanged: (val) {
                if (val != null) {
                  provider.toggleCheck(product.id, product.isChecked);
                }
              },
              title: Text(
                  product.nome,
                  style: TextStyle(
                      decoration: product.isChecked ? TextDecoration.lineThrough : null,
                      color: product.isChecked ? Colors.grey : Colors.black
                  )
              ),
              subtitle: Text("Da comprare: ${product.quantita}"),
            );
          },
        );
      },
    );
  }
}