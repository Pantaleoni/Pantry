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
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Dispensa vuota.\nAggiungi qualcosa!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 18)));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Padding sotto per il FAB
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Container(
                      width: 12,
                      decoration: BoxDecoration(color: p.colorCode, borderRadius: BorderRadius.circular(10)),
                    ),
                    title: Text(p.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(p.dataScadenza != null ? "Scadenza: ${p.dataScadenza!.day}/${p.dataScadenza!.month}/${p.dataScadenza!.year}" : "Senza scadenza"),
                    trailing: Container(
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.redAccent),
                            onPressed: () => context.read<PantryProvider>().updateQuantity(p.id, p.quantita - 1),
                          ),
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
              );
            },
          );
        },
      ),
    );
  }
}