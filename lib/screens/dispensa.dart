import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';

class DispensaScreen extends StatelessWidget {
  const DispensaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('La mia Dispensa', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: context.read<PantryProvider>().prodottiInDispensa,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
                child: Text('Dispensa vuota.\nAggiungi qualcosa!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 18)
                )
            );
          }

          // 1. DIVIDIAMO IN CATEGORIE
          final Map<String, List<Product>> groupedItems = {
            'Frigo': [],
            'Freezer': [],
            'Dispensa': [],
            'Altro': [],
          };

          for (var p in items) {
            // Se la categoria non è tra quelle previste, va in "Altro"
            final cat = groupedItems.containsKey(p.categoria) ? p.categoria : 'Altro';
            groupedItems[cat]!.add(p);
          }

          // 2. ORDINE ALFABETICO IN OGNI CATEGORIA
          for (var list in groupedItems.values) {
            list.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
          }

          // 3. COSTRUIAMO LA LISTA GRAFICA
          List<Widget> listWidgets = [];

          for (var entry in groupedItems.entries) {
            if (entry.value.isEmpty) continue; // Salta le categorie vuote

            // Titolo della categoria
            listWidgets.add(
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)
                  ),
                )
            );

            // Prodotti della categoria
            for (var p in entry.value) {
              listWidgets.add(_buildProductCard(context, p));
            }
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 80), // Padding per il FAB
            children: listWidgets,
          );
        },
      ),
    );
  }

  // --- WIDGET DELLA SINGOLA CARTA ---
  Widget _buildProductCard(BuildContext context, Product p) {
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart, // Trascinamento verso sinistra
      background: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 16, left: 16),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.settings, color: Colors.white), // Icona generica visto che ci sono più opzioni
      ),
      confirmDismiss: (direction) async {
        // POP-UP DELLE 4 OPZIONI
        return await showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Gestisci "${p.nome}"'),
              content: const Text('Cosa vuoi fare con questo prodotto?'),
              actionsAlignment: MainAxisAlignment.center,
              actionsOverflowDirection: VerticalDirection.down, // Mette i bottoni in colonna se non ci stanno
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Annulla', style: TextStyle(color: Colors.grey))
                ),
                TextButton(
                    onPressed: () {
                      context.read<PantryProvider>().deleteProduct(p.id);
                      Navigator.of(ctx).pop(true); // true = fai sparire la carta
                    },
                    child: const Text('Elimina definitivamente', style: TextStyle(color: Colors.red))
                ),
                FilledButton.tonal(
                    onPressed: () {
                      context.read<PantryProvider>().updateProductStatus(p.id, ProductStatus.in_lista_settimanale);
                      Navigator.of(ctx).pop(true);
                    },
                    child: const Text('Spesa Settimanale')
                ),
                FilledButton.tonal(
                    onPressed: () {
                      context.read<PantryProvider>().updateProductStatus(p.id, ProductStatus.in_lista_straordinaria);
                      Navigator.of(ctx).pop(true);
                    },
                    child: const Text('Spesa Straordinaria')
                ),
              ],
            )
        );
      },
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Container(
              width: 12,
              decoration: BoxDecoration(color: p.colorCode, borderRadius: BorderRadius.circular(10)),
            ),

            // DOPPIO CLICK PER IL NOME
            title: GestureDetector(
              onDoubleTap: () => _editName(context, p),
              child: Text(p.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),

            // CLICK PER LA DATA
            subtitle: InkWell(
              onTap: () => _editDate(context, p),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  p.dataScadenza != null ? "Scadenza: ${p.dataScadenza!.day}/${p.dataScadenza!.month}/${p.dataScadenza!.year}" : "Nessuna scadenza (Tocca per aggiungere)",
                  style: TextStyle(color: Colors.grey[700], decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted),
                ),
              ),
            ),

            // TASTI QUANTITÀ
            trailing: Container(
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Scompare (lasciando lo spazio intatto) se la quantità è 1
                  p.quantita > 1
                      ? IconButton(
                    icon: const Icon(Icons.remove, color: Colors.redAccent),
                    onPressed: () => context.read<PantryProvider>().updateQuantity(p.id, p.quantita - 1),
                  )
                      : const SizedBox(width: 48), // Stessa larghezza del bottone per mantenere tutto allineato

                  Text('${p.quantita}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () => context.read<PantryProvider>().updateQuantity(p.id, p.quantita + 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- FUNZIONE PER MODIFICARE IL NOME ---
  Future<void> _editName(BuildContext context, Product p) async {
    String newName = p.nome;
    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Modifica nome'),
          content: TextFormField(
            initialValue: p.nome,
            onChanged: (val) => newName = val,
            textCapitalization: TextCapitalization.sentences,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            TextButton(onPressed: () {
              if (newName.trim().isNotEmpty) {
                context.read<PantryProvider>().updateProductName(p.id, newName.trim());
              }
              Navigator.pop(ctx);
            }, child: const Text('Salva')),
          ],
        )
    );
  }

  // --- FUNZIONE PER MODIFICARE LA DATA ---
  Future<void> _editDate(BuildContext context, Product p) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: p.dataScadenza ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'SELEZIONA NUOVA SCADENZA',
    );
    if (picked != null) {
      if (context.mounted) {
        context.read<PantryProvider>().updateProductDate(p.id, picked);
      }
    }
  }
}