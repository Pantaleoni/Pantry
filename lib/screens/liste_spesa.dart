import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pantry.dart';
import '../models/product.dart';
import '../widgets/shopping.dart';

class ListeSpesaScreen extends StatelessWidget {
  const ListeSpesaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Liste Spesa'),
          bottom: const TabBar(tabs: [Tab(text: 'Settimanale'), Tab(text: 'Straordinaria')]),
        ),
        body: const TabBarView(
          children: [
            ShoppingListTab(status: ProductStatus.in_lista_settimanale),
            ShoppingListTab(status: ProductStatus.in_lista_straordinaria),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.read<PantryProvider>().moveCheckedToPantry();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Spostati in Dispensa!')));
          },
          icon: const Icon(Icons.move_to_inbox),
          label: const Text("Svuota"),
        ),
      ),
    );
  }
}