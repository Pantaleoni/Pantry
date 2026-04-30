import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';

class ScannerAndFormModal extends StatefulWidget {
  const ScannerAndFormModal({super.key});
  @override
  State<ScannerAndFormModal> createState() => _ScannerAndFormModalState();
}

class _ScannerAndFormModalState extends State<ScannerAndFormModal> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Aggiungi Prodotto', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nome Prodotto')),
          TextField(controller: _qtyController, decoration: const InputDecoration(labelText: 'Quantità'), keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              context.read<PantryProvider>().addItem(_nameController.text, int.parse(_qtyController.text));
              Navigator.pop(context);
            },
            child: const Text('Salva in Dispensa'),
          )
        ],
      ),
    );
  }
}