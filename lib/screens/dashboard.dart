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

          // Calcolo delle date
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          // 1. IN SCADENZA A BREVE (Tra 0 e 3 giorni, cioè arancione e rosso non scaduti)
          final inScadenza = allProducts.where((p) {
            if (p.dataScadenza == null) return false;
            final expiry = DateTime(p.dataScadenza!.year, p.dataScadenza!.month, p.dataScadenza!.day);
            final diff = expiry.difference(today).inDays;
            return diff >= 0 && diff <= 3;
          }).toList();

          // Ordina per scadenza più vicina
          inScadenza.sort((a, b) => a.dataScadenza!.compareTo(b.dataScadenza!));

          // 2. SCADUTI (Meno di 0 giorni)
          final scaduti = allProducts.where((p) {
            if (p.dataScadenza == null) return false;
            final expiry = DateTime(p.dataScadenza!.year, p.dataScadenza!.month, p.dataScadenza!.day);
            final diff = expiry.difference(today).inDays;
            return diff < 0;
          }).toList();

          // Ordina dai più vecchi ai più recenti
          scaduti.sort((a, b) => a.dataScadenza!.compareTo(b.dataScadenza!));

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // --- WIDGET RIEPILOGO A 3 COLONNE ---
              Card(
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.green.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatColumn('In Dispensa', '${allProducts.length}', Colors.green),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStatColumn('In Scadenza', '${inScadenza.length}', Colors.orange),
                      Container(width: 1, height: 40, color: Colors.grey[300]),
                      _buildStatColumn('Scaduti', '${scaduti.length}', Colors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // --- SEZIONE IN SCADENZA A BREVE ---
              Text('In scadenza a breve ⚠️', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (inScadenza.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('Nessun prodotto in scadenza a breve! 🎉', style: TextStyle(color: Colors.grey, fontSize: 16))),
                )
              else
                ...inScadenza.map((prodotto) {
                  final diff = prodotto.dataScadenza!.difference(today).inDays;
                  return Card(
                    color: Colors.white,
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

              const SizedBox(height: 20),

              // --- SEZIONE PRODOTTI SCADUTI ---
              Text('Prodotti scaduti ❌', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              if (scaduti.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('Nessun prodotto scaduto! Ottimo lavoro! 👏', style: TextStyle(color: Colors.grey, fontSize: 16))),
                )
              else
                ...scaduti.map((prodotto) {
                  // Usiamo .abs() per trasformare un numero negativo (-2) in positivo (2)
                  final diff = prodotto.dataScadenza!.difference(today).inDays.abs();
                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.2),
                        child: const Icon(Icons.error_outline, color: Colors.red),
                      ),
                      title: Text(prodotto.nome, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                      subtitle: Text(diff == 1 ? 'Scaduto IERI!' : 'Scaduto da $diff giorni', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                      trailing: Text('${prodotto.quantita} pz', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
                    ),
                  );
                }),

              const SizedBox(height: 80), // Margine a fondo pagina
            ],
          );
        },
      ),
    );
  }

  // Widget estratto e aggiornato con 'Expanded' per gestire meglio gli spazi
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
}