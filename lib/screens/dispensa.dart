import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';

class DispensaScreen extends StatelessWidget {
  const DispensaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('La mia Dispensa')),
      body: StreamBuilder<List<PantryItem>>(
        stream: context.read<PantryProvider>().pantryItems,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(items[i].name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.remove), onPressed: () => context.read<PantryProvider>().updateQuantity(items[i].id, items[i].quantity - 1)),
                  Text('${items[i].quantity}'),
                  IconButton(icon: const Icon(Icons.add), onPressed: () => context.read<PantryProvider>().updateQuantity(items[i].id, items[i].quantity + 1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}