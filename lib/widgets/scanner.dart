import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';

class ScannerAndFormModal extends StatefulWidget {
  const ScannerAndFormModal({super.key});
  @override
  State<ScannerAndFormModal> createState() => _ScannerAndFormModalState();
}

class _ScannerAndFormModalState extends State<ScannerAndFormModal> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  DateTime? _selectedDate;
  ProductStatus _selectedStatus = ProductStatus.in_dispensa;

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Gestisce la tastiera che copre lo schermo
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPadding + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Aggiungi Prodotto 🍎', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Nome Prodotto',
                prefixIcon: const Icon(Icons.fastfood),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Quantità',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                    ),
                    onPressed: _presentDatePicker,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_selectedDate == null ? 'Scadenza' : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Scelta della destinazione
            SegmentedButton<ProductStatus>(
              segments: const [
                ButtonSegment(value: ProductStatus.in_dispensa, label: Text('Dispensa'), icon: Icon(Icons.kitchen)),
                ButtonSegment(value: ProductStatus.in_lista_settimanale, label: Text('Spesa'), icon: Icon(Icons.shopping_cart)),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (Set<ProductStatus> newSelection) {
                setState(() => _selectedStatus = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                if (_nameController.text.isEmpty) return;

                context.read<PantryProvider>().addProduct(
                  nome: _nameController.text,
                  quantita: int.tryParse(_qtyController.text) ?? 1,
                  scadenza: _selectedDate,
                  stato: _selectedStatus,
                );
                Navigator.pop(context);
              },
              child: const Text('Salva', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}