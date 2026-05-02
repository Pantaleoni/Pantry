import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';

class ScannerAndFormModal extends StatefulWidget {
  final ProductStatus targetStatus;

  const ScannerAndFormModal({
    super.key,
    required this.targetStatus,
  });

  @override
  State<ScannerAndFormModal> createState() => _ScannerAndFormModalState();
}

class _ScannerAndFormModalState extends State<ScannerAndFormModal> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  DateTime? _selectedDate;

  // NUOVA VARIABILE: Categoria preimpostata su 'Altro'
  String _selectedCategory = 'Altro';

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
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Controlliamo se dobbiamo mostrare la data (Solo se siamo in Dispensa)
    final bool showDatePickerField = widget.targetStatus == ProductStatus.in_dispensa;

    String titolo = 'Aggiungi Prodotto 🍎';
    if (widget.targetStatus == ProductStatus.in_dispensa) {
      titolo = 'Aggiungi in Dispensa 📦';
    } else if (widget.targetStatus == ProductStatus.in_lista_settimanale) {
      titolo = 'Spesa Settimanale 🛒';
    } else {
      titolo = 'Spesa Straordinaria ⭐';
    }

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
            Text(titolo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // 1. NOME PRODOTTO
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Nome Prodotto',
                prefixIcon: const Icon(Icons.fastfood),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 16),

            // 2. MENU A TENDINA PER CATEGORIA (NUOVO)
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Categoria',
                prefixIcon: const Icon(Icons.category),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              items: const [
                DropdownMenuItem(value: 'Frigo', child: Text('Frigo ❄️')),
                DropdownMenuItem(value: 'Freezer', child: Text('Freezer 🧊')),
                DropdownMenuItem(value: 'Dispensa', child: Text('Dispensa 📦')),
                DropdownMenuItem(value: 'Altro', child: Text('Altro 🏷️')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 3. QUANTITÀ E DATA SCADENZA
            Row(
              children: [
                // Campo Quantità (prende tutto lo spazio se la data non c'è)
                Expanded(
                  flex: 1,
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

                // Mostriamo il bottone della data SOLO se siamo in dispensa
                if (showDatePickerField) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                      ),
                      onPressed: _presentDatePicker,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate == null
                            ? 'Scadenza'
                            : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: const TextStyle(fontSize: 13), // Leggermente rimpicciolito per evitare overflow
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 24),

            // 4. BOTTONE AGGIUNGI
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: () {
                if (_nameController.text.isEmpty) return;

                // Passiamo anche la categoria scelta al Provider
                context.read<PantryProvider>().addProduct(
                  nome: _nameController.text,
                  quantita: int.tryParse(_qtyController.text) ?? 1,
                  scadenza: showDatePickerField ? _selectedDate : null,
                  stato: widget.targetStatus,
                  categoria: _selectedCategory, // <-- Nuovo parametro inviato!
                );
                Navigator.pop(context);
              },
              child: const Text('Aggiungi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}