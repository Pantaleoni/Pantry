import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<List<Product>>(
        stream: context.read<PantryProvider>().prodottiInDispensa,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allProducts = snapshot.data ?? [];

          // Calcolo scadenze
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final inScadenza = allProducts.where((p) {
            if (p.dataScadenza == null) return false;
            final expiry = DateTime(p.dataScadenza!.year, p.dataScadenza!.month, p.dataScadenza!.day);
            final diff = expiry.difference(today).inDays;
            return diff >= 0 && diff <= 5; // Avvisa 5 giorni prima
          }).toList();

          // Ordina per scadenza più vicina
          inScadenza.sort((a, b) => a.dataScadenza!.compareTo(b.dataScadenza!));

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- WIDGET RIEPILOGO ---
              Card(
                elevation: 4,
                shadowColor: Colors.green.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('In Dispensa', '${allProducts.length}', Colors.green),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStatColumn('In Scadenza', '${inScadenza.length}', Colors.orange),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- SEZIONE SCADENZE ---
              Text('In scadenza a breve ⚠️', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (inScadenza.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('Nessun prodotto in scadenza! 🎉', style: TextStyle(color: Colors.grey, fontSize: 16))),
                )
              else
                ...inScadenza.map((prodotto) {
                  final diff = prodotto.dataScadenza!.difference(today).inDays;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: prodotto.colorCode.withOpacity(0.2),
                        child: Icon(Icons.warning_amber_rounded, color: prodotto.colorCode),
                      ),
                      title: Text(prodotto.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(diff == 0 ? 'Scade OGGI!' : 'Scade tra $diff giorni'),
                      trailing: Text('${prodotto.quantita} pz', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }
}