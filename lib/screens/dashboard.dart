import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PantryProvider>();
    final inScadenza = provider.inScadenzaOggi;
    final spesaSettimanale = provider.listaSettimanale;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        children: [
          _buildSectionHeader('In Scadenza a Breve', Icons.warning_rounded, Colors.redAccent),
          if (inScadenza.isEmpty) _buildEmptyState('Nessun prodotto in scadenza!', Icons.check_circle_outline, Colors.green)
          else ...inScadenza.map((p) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: p.colorCode.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.timer, color: p.colorCode)),
              title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text("Quantità residua: ${p.quantita}"),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            ),
          )),
          const SizedBox(height: 24),
          _buildSectionHeader('Cosa manca (Spesa Rapida)', Icons.shopping_basket_rounded, Colors.blueAccent),
          if (spesaSettimanale.isEmpty) _buildEmptyState('Lista spesa vuota.', Icons.shopping_cart_outlined, Colors.grey)
          else ...spesaSettimanale.take(3).map((p) => Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const Icon(Icons.radio_button_unchecked, color: Colors.grey),
              title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(children: [Icon(icon, color: color, size: 28), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5))]),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Column(children: [Icon(icon, size: 48, color: color.withOpacity(0.5)), const SizedBox(height: 12), Text(message, style: TextStyle(color: Colors.grey.shade600, fontSize: 16))]),
      ),
    );
  }
}